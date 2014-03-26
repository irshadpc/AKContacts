//
//  AKAddressBook+Loader.m
//  AKContacts
//
//  Created by Adam Kornafeld on 1/28/14.
//  Copyright (c) 2014 Adam Kornafeld. All rights reserved.
//

#import "AKAddressBook+Loader.h"
#import "AKAddressBook.h"
#import "AKSource.h"
#import "AKGroup.h"
#import "AKContact.h"

@implementation AKAddressBook (Loader)

- (void)loadAddressBookWithCompletionHandler: (void (^)(BOOL))completionHandler
{
    /*
     * Loading the addressbook runs in the background and uses a local ABAddressBookRef
     */
    dispatch_block_t block = ^{
        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
        CFErrorRef error = NULL;
        ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, &error);
        if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }
#else
        ABAddressBookRef addressBook = ABAddressBookCreate();
#endif
        
        // Do not change order of loading
        [self loadSourcesWithABAddressBookRef: addressBookRef];
        
        [self loadGroupsWithABAddressBookRef: addressBookRef];
        
        [self loadContactsWithABAddressBookRef: addressBookRef];
        
        CFRelease(addressBookRef);
        
        if (completionHandler) {
            completionHandler(YES);
        }
    };
    
    dispatch_async(self.ab_queue, block);
}

- (void)loadSourcesWithABAddressBookRef: (ABAddressBookRef)addressBookRef
{
    NSAssert(!dispatch_get_specific(IsOnMainQueueKey), @"Must not be dispatched on main queue");
    
    if (!self.sources) {
        self.sources = [[NSMutableArray alloc] init];
    }
    
    NSArray *sources = (NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllSources(addressBookRef));
    
    if ([sources count] > 1)
    {
        AKSource *aggregatorSource = [self sourceForSourceId: kSourceAggregate];
        if (!aggregatorSource) {
            aggregatorSource = [[AKSource alloc] initWithABRecordID: kSourceAggregate andAddressBookRef: self.addressBookRef];
            aggregatorSource.canCreateRecord = YES;
            [self.sources addObject: aggregatorSource];
        }
    }
    
    ABRecordRef source = ABAddressBookCopyDefaultSource(addressBookRef);
    ABRecordID defaultSourceID = ABRecordGetRecordID(source);
    CFRelease(source);
    
    for (id obj in sources)
    {
        ABRecordRef recordRef = (__bridge ABRecordRef)obj;
        ABRecordID recordID = ABRecordGetRecordID(recordRef);
        
        ABSourceType type =  [(NSNumber *)CFBridgingRelease(ABRecordCopyValue(recordRef, kABSourceTypeProperty)) intValue];
        if (type == kABSourceTypeExchangeGAL) continue; // No support for Exchange Global Address List, yet
        
        AKSource *source = [self sourceForSourceId: recordID];
        if (!source) {
            source = [[AKSource alloc] initWithABRecordID: recordID andAddressBookRef: self.addressBookRef];
            source.isDefault = (defaultSourceID == recordID) ? YES : NO;
            
            ABRecordRef tryRecordRef = ABPersonCreateInSource(recordRef);
            if (tryRecordRef != nil)
            { // Check if source supports create records
                source.canCreateRecord = YES;
                CFRelease(tryRecordRef);
            }
            [self.sources addObject: source];
        }
    }
    self.sourceID = (sources.count > 1) ? kSourceAggregate : defaultSourceID;
}

- (void)loadGroupsWithABAddressBookRef: (ABAddressBookRef)addressBookRef
{
    NSAssert(!dispatch_get_specific(IsOnMainQueueKey), @"Must not be dispatched on main queue");
    
    if (ShowGroups == NO) return;
    
    [self setGroupID: kGroupAggregate];
    
    AKGroup *mainAggregateGroup = nil;
    
    for (AKSource *source in self.sources)
    {
        AKGroup *aggregateGroup = [source groupForGroupId: kGroupAggregate];
        if (!aggregateGroup) {
            aggregateGroup = [[AKGroup alloc] initWithABRecordID: kGroupAggregate andAddressBookRef: self.addressBookRef];
            [source.groups addObject: aggregateGroup];
        }   // Group members are recompiled on all reload
        [aggregateGroup.memberIDs removeAllObjects];

        if (source.recordID < 0)
        {
            if (source.recordID == kSourceAggregate)
            {
                mainAggregateGroup = aggregateGroup;
                [mainAggregateGroup setIsMainAggregate: YES];
            }
            continue; // Skip custom sources
        }
        
        NSArray *groups = (NSArray *) CFBridgingRelease(ABAddressBookCopyArrayOfAllGroupsInSource(addressBookRef, source.recordRef));
        
        for (id obj in groups)
        {
            ABRecordRef recordRef = (__bridge ABRecordRef)obj;
            ABRecordID recordID = ABRecordGetRecordID(recordRef);

            AKGroup *group = [source groupForGroupId: recordID];
            if (!group) {
                group = [[AKGroup alloc] initWithABRecordID: recordID andAddressBookRef: self.addressBookRef];
                [source.groups addObject: group];
            }
            
            NSArray *members = (NSArray *)CFBridgingRelease(ABGroupCopyArrayOfAllMembers(recordRef));
            [group.memberIDs removeAllObjects];
            for (id member in members)
            {
                ABRecordRef record = (__bridge ABRecordRef)member;
                // From ABGRoup Reference: Groups may not contain other groups
                if (ABRecordGetRecordType(record) == kABPersonType)
                {
                    [group.memberIDs addObject: @(ABRecordGetRecordID(record))];
                }
            }
            NSString *name = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef, kABGroupNameProperty));
            NSLog(@"% 3d : %@ member count: %lu", recordID, name, (unsigned long)group.memberIDs.count);
        }
        [source revertGroupsOrder];
    }
}

- (void)loadContactsWithABAddressBookRef: (ABAddressBookRef)addressBookRef
{
    NSAssert(!dispatch_get_specific(IsOnMainQueueKey), @"Must not be dispatched on main queue");

    if (!self.contactIDsSortedByFirst || !self.contactIDsSortedByLast || !self.contactIDsSortedByPhone)
    {
        self.contactIDsSortedByFirst = [[NSMutableDictionary alloc] init];
        self.contactIDsSortedByLast = [[NSMutableDictionary alloc] init];
        self.contactIDsSortedByPhone = [[NSMutableDictionary alloc] init];

        for (NSString *sectionKey in [AKAddressBook sectionKeys])
        {
            [self.contactIDsSortedByFirst setObject: [[NSMutableArray alloc] init] forKey: sectionKey];
            [self.contactIDsSortedByLast setObject: [[NSMutableArray alloc] init] forKey: sectionKey];
        }
        NSArray *sectionKeys = @[@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9"];
        for (NSString *sectionKey in sectionKeys)
        {
            [self.contactIDsSortedByFirst setObject: [[NSMutableArray alloc] init] forKey: sectionKey];
            [self.contactIDsSortedByLast setObject: [[NSMutableArray alloc] init] forKey: sectionKey];
            [self.contactIDsSortedByPhone setObject: [[NSMutableArray alloc] init] forKey: sectionKey];
        }
    }

    NSMutableSet *appContactIdentifiers = [[NSMutableSet alloc] init];
    if (self.status == kAddressBookLoading)
    {
        for (NSString *key in self.contactIDsSortedByFirst) {
            NSArray *section = [self.contactIDsSortedByFirst objectForKey: key];
            [appContactIdentifiers addObjectsFromArray: section];
        }
    }

    AKSource *aggregateSource = [self sourceForSourceId: kSourceAggregate];
    AKGroup *mainAggregateGroup = [aggregateSource groupForGroupId: kGroupAggregate];

    NSMutableSet *nativeContactIDs = [[NSMutableSet alloc] init];
    NSMutableSet *allLinkedRecordIDs = [[NSMutableSet alloc] init];
    NSMutableSet *createdRecordIDs = [[NSMutableSet alloc] init];
    NSMutableSet *changedRecordIDs = [[NSMutableSet alloc] init];

    NSDate *start = [NSDate date];

    NSLog(@"Number of contacts: %ld", (long)self.contactsCount);
    self.loadProgress.totalUnitCount = self.contactsCount;
    self.loadProgress.completedUnitCount = 0;
    // Get array of records in Address Book
    for (AKSource *source in self.sources)
    {
        if (source.recordID < 0) {
            continue; // Skip custom sources
        }

        AKGroup *aggregateGroup = [source groupForGroupId: kGroupAggregate];

        // ABAddressBookCopyArrayOfAllPeopleInSource calls ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering
        // Perfomance is not affected by which of the two is called
        NSArray *people = (NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBookRef, source.recordRef, self.sortOrdering));
        for (id obj in people)
        {
            self.loadProgress.completedUnitCount += 1;

            ABRecordRef recordRef = (__bridge ABRecordRef)obj;

            ABRecordID recordID = ABRecordGetRecordID(recordRef);
            NSNumber *contactID = [NSNumber numberWithInt: recordID];
          
//            NSLog(@"%d intHash: %d RecordHash: %d", recordID, [contactID hash], [(__bridge id)recordRef hash]);
            
            [nativeContactIDs addObject: contactID];

            NSDate *created = (NSDate *)CFBridgingRelease(ABRecordCopyValue(recordRef, kABPersonCreationDateProperty));
            NSDate *modified = (NSDate *)CFBridgingRelease(ABRecordCopyValue(recordRef, kABPersonModificationDateProperty));

            NSArray *linked = CFBridgingRelease(ABPersonCopyArrayOfAllLinkedPeople(recordRef));
            NSMutableSet *linkedRecordIDs = [[NSMutableSet alloc] init];
            for (id obj in linked)
            {
                ABRecordID linkedID = ABRecordGetRecordID((__bridge ABRecordRef)obj);
                [linkedRecordIDs addObject: @(linkedID)];
            }
            if (linkedRecordIDs.count > 1 && ![allLinkedRecordIDs intersectsSet: linkedRecordIDs])
            {
                [allLinkedRecordIDs addObject: linkedRecordIDs.anyObject];
            }

            if (!self.dateAddressBookLoaded || [self.dateAddressBookLoaded compare: created] != NSOrderedDescending)
            { // Created should be compared first
                [createdRecordIDs addObject: contactID];
                self.loadProgress.totalUnitCount += 1;
            }
            else if ([self.dateAddressBookLoaded compare: modified] != NSOrderedDescending)
            { // Contact changed
                [changedRecordIDs addObject: contactID];
                self.loadProgress.totalUnitCount += 1;
            }

            // Aggregate groups are repopulated on each load
            // so there's no need to remove members from them
            if (![allLinkedRecordIDs member: contactID])
            {
                [mainAggregateGroup.memberIDs addObject: contactID];
            }
            [aggregateGroup.memberIDs addObject: contactID];
        }
    }

    NSLog(@"Address book sweep %.2f", fabs([[NSDate date] timeIntervalSinceDate: start]));
    start = [NSDate date];
    
    if (self.status == kAddressBookLoading)
    {
      if ([self.presentationDelegate respondsToSelector: @selector(addressBookWillBeginUpdates:)])
      {
        [self.presentationDelegate addressBookWillBeginUpdates: self];
      }
    }

    if (self.status == kAddressBookLoading)
    {
        [appContactIdentifiers minusSet: nativeContactIDs];
        NSLog(@"Deleted contactIDs: %@", appContactIdentifiers);
        for (NSNumber *contactID in appContactIdentifiers)
        {
          [self contactIdentifiersDeleteRecordID: contactID.intValue withAddressBookRef: addressBookRef];
        }
    }

    for (NSNumber *recordID in createdRecordIDs)
    {
        self.loadProgress.completedUnitCount += 1;
        if (self.status == kAddressBookLoading)
        {
            NSLog(@"% 3d : %@ is new", recordID.intValue, CFBridgingRelease(ABRecordCopyCompositeName(ABAddressBookGetPersonWithRecordID(addressBookRef, recordID.intValue))));
        }
        if (![allLinkedRecordIDs member: recordID])
        {
            [self contactIdentifiersInsertRecordID: recordID.intValue withAddressBookRef: addressBookRef];
        }
        [self processPhoneNumbersOfRecordID: recordID.intValue andABAddressBookRef: addressBookRef];
    }
    for (NSNumber *recordID in changedRecordIDs)
    {
        self.loadProgress.completedUnitCount += 1;
        if (self.status == kAddressBookLoading)
        {
            NSLog(@"% 3d : %@ did change", recordID.intValue, CFBridgingRelease(ABRecordCopyCompositeName(ABAddressBookGetPersonWithRecordID(addressBookRef, recordID.intValue))));
        }
        [self contactIdentifiersDeleteRecordID: recordID.intValue withAddressBookRef: addressBookRef];
        [self contactIdentifiersInsertRecordID: recordID.intValue withAddressBookRef: addressBookRef];
    }
    NSLog(@"Lookup table contstructed %.2f", fabs([[NSDate date] timeIntervalSinceDate: start]));
    
    if (self.status == kAddressBookLoading)
    {
      if ([self.presentationDelegate respondsToSelector:@selector(addressBookDidEndUpdates:)])
      {
        [self.presentationDelegate addressBookDidEndUpdates: self];
      }
    }
}

- (void)processPhoneNumbersOfRecordID: (ABRecordID)recordID andABAddressBookRef: (ABAddressBookRef)addressBookRef
{
    ABRecordRef recordRef = ABAddressBookGetPersonWithRecordID(addressBookRef, recordID);
    ABMultiValueRef multiValueRecord =(ABMultiValueRef)ABRecordCopyValue(recordRef, kABPersonPhoneProperty);
    if (multiValueRecord)
    {
        NSInteger count = ABMultiValueGetCount(multiValueRecord);
        for (NSInteger i = 0; i < count; ++i) {
            NSString *value = (NSString *)CFBridgingRelease(ABMultiValueCopyValueAtIndex(multiValueRecord, i));
            NSString *digits = value.stringWithNonDigitsRemoved;
            if (digits.length > 0)
            {
                NSString *key = [digits substringToIndex: 1];
                NSMutableArray *sectionArray = [self.contactIDsSortedByPhone objectForKey: key];

                NSUInteger index = [AKAddressBook indexOfRecordID: recordID inArray: sectionArray withSortOrdering: self.sortOrdering andAddressBookRef: addressBookRef];
                [sectionArray insertObject: @(recordID) atIndex: index];
            }
            for (NSString *prefix in [AKAddressBook prefixesToDiscardOnSearch])
            {
                if ([digits hasPrefix: prefix])
                {
                    digits = [digits substringFromIndex: prefix.length];
                    if (digits.length > 0)
                    {
                        NSString *key = [digits substringToIndex: prefix.length];
                        NSMutableArray *sectionArray = [self.contactIDsSortedByPhone objectForKey: key];
                        NSUInteger index = [AKAddressBook indexOfRecordID: recordID inArray: sectionArray withSortOrdering: self.sortOrdering andAddressBookRef: addressBookRef];
                        [sectionArray insertObject: @(recordID) atIndex: index];
                    }
                }
            }
        }
        CFRelease(multiValueRecord);
    }
}

#pragma mark - Insert / Remove methods

- (void)contactIdentifiersInsertRecordID: (ABRecordID)recordID withAddressBookRef: (ABAddressBookRef)addressBookRef
{
  ABRecordRef recordRef = ABAddressBookGetPersonWithRecordID(addressBookRef, recordID);
  // First name
  NSString *firstName = [AKContact nameToDetermineSectionForRecordRef: recordRef withSortOrdering: kABPersonSortByFirstName];
  NSString *sectionKey = [AKContact sectionKeyForName: firstName];
  NSMutableArray *sectionArray = (NSMutableArray *)[self.contactIDsSortedByFirst objectForKey: sectionKey];
  NSUInteger index = [AKAddressBook indexOfRecordID: recordID inArray: sectionArray withSortOrdering: kABPersonSortByFirstName andAddressBookRef: addressBookRef];
  [sectionArray insertObject: @(recordID) atIndex: index];

  if ([sectionKey isEqualToString: @"#"] && [firstName isMemberOfCharacterSet: [NSCharacterSet decimalDigitCharacterSet]])
  {
      sectionKey = [firstName substringToIndex: 1];
      sectionArray = (NSMutableArray *)[self.contactIDsSortedByFirst objectForKey: sectionKey];
      index = [AKAddressBook indexOfRecordID: recordID inArray: sectionArray withSortOrdering: kABPersonSortByFirstName andAddressBookRef: addressBookRef];
      [sectionArray insertObject: @(recordID) atIndex: index];
  }

  // Last name
  NSString *lastName = [AKContact nameToDetermineSectionForRecordRef: recordRef withSortOrdering: kABPersonSortByLastName];
  sectionKey = [AKContact sectionKeyForName: lastName];
  sectionArray = (NSMutableArray *)[self.contactIDsSortedByLast objectForKey: sectionKey];
  index = [AKAddressBook indexOfRecordID: recordID inArray: sectionArray withSortOrdering: kABPersonSortByLastName andAddressBookRef: addressBookRef];
  [sectionArray insertObject: @(recordID) atIndex: index];

  if ([sectionKey isEqualToString: @"#"] && [lastName isMemberOfCharacterSet: [NSCharacterSet decimalDigitCharacterSet]])
  {
    sectionKey = [lastName substringToIndex: 1];
    sectionArray = (NSMutableArray *)[self.contactIDsSortedByLast objectForKey: sectionKey];
    index = [AKAddressBook indexOfRecordID: recordID inArray: sectionArray withSortOrdering: kABPersonSortByLastName andAddressBookRef: addressBookRef];
    [sectionArray insertObject: @(recordID) atIndex: index];
  }

  if (self.status == kAddressBookLoading)
  {
    if ([self.presentationDelegate respondsToSelector:@selector(addressBook:didInsertRecordID:)])
    {
      [self.presentationDelegate addressBook: self didInsertRecordID: recordID];
    }
  }
}

- (void)contactIdentifiersDeleteRecordID: (ABRecordID)recordID withAddressBookRef: (ABAddressBookRef)addressBookRef
{
  NSString *sectionKeyByFirst, *sectionKeyByLast;

  ABRecordRef recordRef = ABAddressBookGetPersonWithRecordID(addressBookRef, recordID);
  if (recordRef)
  { // Can still exist when it is removed and added due to a name change
    NSString *nameByFirst = [AKContact nameToDetermineSectionForRecordRef: recordRef withSortOrdering: kABPersonSortByFirstName];
    NSString *nameByLast = [AKContact nameToDetermineSectionForRecordRef: recordRef withSortOrdering: kABPersonSortByLastName];
    sectionKeyByFirst = [AKContact sectionKeyForName: nameByFirst];
    sectionKeyByLast = [AKContact sectionKeyForName: nameByLast];
  }

  NSUInteger indexByFirst = [AKAddressBook removeRecordID: recordID withSectionKey: sectionKeyByFirst fromContactIdentifierDictionary: self.contactIDsSortedByFirst];
  NSUInteger indexByLast = [AKAddressBook removeRecordID: recordID withSectionKey: sectionKeyByLast fromContactIdentifierDictionary: self.contactIDsSortedByLast];

  if ((indexByFirst != NSNotFound || indexByLast != NSNotFound) && self.status == kAddressBookLoading)
  {
    if ([self.presentationDelegate respondsToSelector:@selector(addressBook:didRemoveRecordID:)])
    {
      [self.presentationDelegate addressBook: self didRemoveRecordID: recordID];
    }
  }
}

# pragma mark - Class methods

+ (NSUInteger)indexOfRecordID: (ABRecordID) recordID inArray: (NSArray *)array withSortOrdering: (ABPersonSortOrdering)sortOrdering andAddressBookRef: (ABAddressBookRef)addressBookRef
{
    return [array indexOfObject: @(recordID)
                  inSortedRange: (NSRange){0, array.count}
                        options: NSBinarySearchingInsertionIndex
                usingComparator: [AKAddressBook recordIDBasedComparatorWithSortOrdering: sortOrdering andAddressBookRef: addressBookRef]];
}

+ (NSUInteger)removeRecordID: (ABRecordID)recordID withSectionKey: (NSString *)sectionKey fromContactIdentifierDictionary: (NSMutableDictionary *)contactIDs
{
    NSMutableArray *sectionArray;
    NSUInteger index = NSNotFound;
    if (sectionKey)
    {
        sectionArray = [contactIDs objectForKey: sectionKey];
        index = [sectionArray indexOfObject: @(recordID)];
    }
    
    if (index == NSNotFound)
    { // Moved to another section
        for (NSString *key in contactIDs)
        { // This is slow but should run seldom
            sectionArray = [contactIDs objectForKey: key];
            index = [sectionArray indexOfObject: @(recordID)];
            if (index != NSNotFound)
            {
                NSLog(@"Moved from section: %@", key);
                break;
            }
        }
    }
    if (index != NSNotFound)
    {
        [sectionArray removeObjectAtIndex: index];
    }
    return index;
}

#pragma mark - Comparators

+ (NSComparator)recordIDBasedComparatorWithSortOrdering: (ABPersonSortOrdering)sortOrdering andAddressBookRef: (ABAddressBookRef)addressBookRef
{
    NSInteger organization = [(NSNumber *)kABPersonKindOrganization integerValue];
    NSInteger person = [(NSNumber *)kABPersonKindPerson integerValue];
    
    NSComparator comparator = ^NSComparisonResult(id obj1, id obj2) {
        ABRecordRef recordRef2 = ABAddressBookGetPersonWithRecordID(addressBookRef, [(NSNumber *)obj2 intValue]);
        ABRecordRef recordRef1 = ABAddressBookGetPersonWithRecordID(addressBookRef, [(NSNumber *)obj1 intValue]);
        
        NSInteger kind1 = [(NSNumber *)CFBridgingRelease(ABRecordCopyValue(recordRef1, kABPersonKindProperty)) integerValue];
        NSInteger kind2 = [(NSNumber *)CFBridgingRelease(ABRecordCopyValue(recordRef2, kABPersonKindProperty)) integerValue];
        
        ABPropertyID prop1 = (sortOrdering == kABPersonSortByFirstName) ? kABPersonFirstNameProperty : kABPersonLastNameProperty;
        ABPropertyID prop2 = (sortOrdering == kABPersonSortByFirstName) ? kABPersonFirstNameProperty : kABPersonLastNameProperty;
        
        NSString *elem1, *elem2;
        NSComparisonResult result = NSOrderedSame;
        
        if (kind1 == person && kind2 == person)
        {
            elem1 = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef1, prop1));
            elem2 = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef2, prop2));
            
            result = [elem1 localizedCaseInsensitiveCompare: elem2];
            if (result == NSOrderedSame)
            {
                prop1 = prop2 = (sortOrdering == kABPersonSortByFirstName) ? kABPersonLastNameProperty : kABPersonFirstNameProperty;
                
                elem1 = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef1, prop1));
                elem2 = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef2, prop2));
                
                result = [elem1 localizedCaseInsensitiveCompare: elem2];
            }
        }
        else if (kind1 == person && kind2 == organization)
        {
            prop2 = kABPersonOrganizationProperty;
            
            elem1 = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef1, prop1));
            elem2 = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef2, prop2));
            
            result = [elem1 localizedCaseInsensitiveCompare: elem2];
            if (result == NSOrderedSame)
            {
                prop1 = (sortOrdering == kABPersonSortByFirstName) ? kABPersonLastNameProperty : kABPersonFirstNameProperty;
                
                elem1 = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef1, prop1));
                result = [elem1 localizedCaseInsensitiveCompare: elem2];
            }
        }
        else if (kind1 == organization && kind2 == person)
        {
            prop1 = kABPersonOrganizationProperty;
            
            elem1 = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef1, prop1));
            elem2 = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef2, prop2));
            
            result = [elem1 localizedCaseInsensitiveCompare: elem2];
            if (result == NSOrderedSame)
            {
                prop2 = (sortOrdering == kABPersonSortByFirstName) ? kABPersonLastNameProperty : kABPersonFirstNameProperty;
                
                elem2 = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef2, prop2));
                result = [elem1 localizedCaseInsensitiveCompare: elem2];
            }
        }
        else if (kind1 == organization && kind2 == organization)
        {
            prop1 = prop2 = kABPersonOrganizationProperty;
            
            elem1 = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef1, prop1));
            elem2 = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef2, prop2));
            
            result = [elem1 localizedCaseInsensitiveCompare: elem2];
        }
        return result;
    };
    return comparator;
}

@end
