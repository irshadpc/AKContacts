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
        if (error) NSLog(@"%ld", CFErrorGetCode(error));
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

- (void)loadSourcesWithABAddressBookRef: (ABAddressBookRef)addressBook
{
    NSAssert(!dispatch_get_specific(IsOnMainQueueKey), @"Must not be dispatched on main queue");
    
    if (!self.sources) {
        self.sources = [[NSMutableArray alloc] init];
    }
    
    NSArray *sources = (NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllSources(addressBook));
    
    if ([sources count] > 1)
    {
        AKSource *aggregatorSource = [self sourceForSourceId: kSourceAggregate];
        if (!aggregatorSource) {
            aggregatorSource = [[AKSource alloc] initWithABRecordID: kSourceAggregate];
            aggregatorSource.canCreateRecord = YES;
            [self.sources addObject: aggregatorSource];
        }
    }
    
    ABRecordRef source = ABAddressBookCopyDefaultSource(addressBook);
    ABRecordID defaultSourceID = ABRecordGetRecordID(source);
    CFRelease(source);
    
    for (id obj in sources)
    {
        ABRecordRef recordRef = (__bridge ABRecordRef)obj;
        ABRecordID recordID = ABRecordGetRecordID(recordRef);
        
        ABSourceType type =  [(NSNumber *)CFBridgingRelease(ABRecordCopyValue(recordRef, kABSourceTypeProperty)) integerValue];
        if (type == kABSourceTypeExchangeGAL) continue; // No support for Exchange Global Address List, yet
        
        AKSource *source = [self sourceForSourceId: recordID];
        if (!source) {
            source = [[AKSource alloc] initWithABRecordID: recordID];
            source.isDefault = (defaultSourceID == recordID) ? YES : NO;
            
            ABRecordRef tryRecordRef = ABPersonCreateInSource(source.recordRef);
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

- (void)loadGroupsWithABAddressBookRef: (ABAddressBookRef)addressBook
{
    NSAssert(!dispatch_get_specific(IsOnMainQueueKey), @"Must not be dispatched on main queue");
    
    if (ShowGroups == NO) return;
    
    [self setGroupID: kGroupAggregate];
    
    AKGroup *mainAggregateGroup = nil;
    
    for (AKSource *source in self.sources)
    {
        AKGroup *aggregateGroup = [source groupForGroupId: kGroupAggregate];
        if (!aggregateGroup) {
            aggregateGroup = [[AKGroup alloc] initWithABRecordID: kGroupAggregate];
            [source.groups addObject: aggregateGroup];
        }
        
        if (source.recordID < 0)
        {
            if (source.recordID == kSourceAggregate)
            {
                mainAggregateGroup = aggregateGroup;
                [mainAggregateGroup setIsMainAggregate: YES];
            }
            continue; // Skip custom sources
        }
        
        NSArray *groups = (NSArray *) CFBridgingRelease(ABAddressBookCopyArrayOfAllGroupsInSource(addressBook, source.recordRef));
        
        for (id obj in groups)
        {
            ABRecordRef recordRef = (__bridge ABRecordRef)obj;
            ABRecordID recordID = ABRecordGetRecordID(recordRef);
            
            NSString *name = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef, kABGroupNameProperty));
            NSLog(@"% 3d : %@", recordID, name);
            
            AKGroup *group = [source groupForGroupId: recordID];
            if (!group) {
                group = [[AKGroup alloc] initWithABRecordID: recordID];
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
        }
        [source revertGroupsOrder];
    }
}

- (void)loadContactsWithABAddressBookRef: (ABAddressBookRef)addressBook
{
    NSAssert(!dispatch_get_specific(IsOnMainQueueKey), @"Must not be dispatched on main queue");

    if (!self.allContactIdentifiers)
    {
        self.allContactIdentifiers = [[NSMutableDictionary alloc] init];
        NSString *sectionKeys = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ#";
        for (int i = 0; i < [sectionKeys length]; i++)
        {
            NSString *sectionKey = [NSString stringWithFormat: @"%c", [sectionKeys characterAtIndex: i]];
            NSMutableArray *sectionArray = [[NSMutableArray alloc] init];
            [self.allContactIdentifiers setObject: sectionArray forKey: sectionKey];
        }
    }

    NSMutableSet *appContactIdentifiers = [[NSMutableSet alloc] init];
    if (self.status == kAddressBookLoading)
    {
        for (NSString *key in self.allContactIdentifiers) {
            NSArray *section = [self.allContactIdentifiers objectForKey: key];
            [appContactIdentifiers addObjectsFromArray: section];
        }
    }

    AKSource *aggregateSource = [self sourceForSourceId: kSourceAggregate];
    AKGroup *mainAggregateGroup = [aggregateSource groupForGroupId: kGroupAggregate];

    NSMutableSet *nativeContactIdentifiers = [[NSMutableSet alloc] init];
    NSMutableSet *linkedRecords = [[NSMutableSet alloc] init];
    NSMutableSet *createdRecords = [[NSMutableSet alloc] init];
    NSMutableSet *changedRecords = [[NSMutableSet alloc] init];

    NSLog(@"Number of contacts: %d", self.contactsCount);
    [self.delegate setProgressTotal: self.contactsCount];
    NSInteger i = 0, total = self.contactsCount;
    // Get array of records in Address Book
    for (AKSource *source in self.sources)
    {
        if (source.recordID < 0) {
            continue; // Skip custom sources
        }

        AKGroup *aggregateGroup = [source groupForGroupId: kGroupAggregate];

        // ABAddressBookCopyArrayOfAllPeopleInSource calls ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering
        // Perfomance is not affected by which of the two is called
        NSArray *people = (NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook, source.recordRef, self.sortOrdering));
        for (id obj in people)
        {
            [self.delegate setProgressCurrent: ++i];

            ABRecordRef recordRef = (__bridge ABRecordRef)obj;

            ABRecordID recordID = ABRecordGetRecordID(recordRef);
            NSNumber *contactID = [NSNumber numberWithInteger: recordID];

            [nativeContactIdentifiers addObject: contactID];

            NSDate *created = (NSDate *)CFBridgingRelease(ABRecordCopyValue(recordRef, kABPersonCreationDateProperty));
            NSDate *modified = (NSDate *)CFBridgingRelease(ABRecordCopyValue(recordRef, kABPersonModificationDateProperty));

            NSArray *linked = CFBridgingRelease(ABPersonCopyArrayOfAllLinkedPeople(recordRef));
            for (id obj in linked)
            {
                ABRecordID linkedID = ABRecordGetRecordID((__bridge ABRecordRef)obj);
                if (linkedID != recordID)
                {
                    [linkedRecords addObject: [NSNumber numberWithInteger: linkedID]];
                }
            }

            if (!self.dateAddressBookLoaded || [self.dateAddressBookLoaded compare: created] != NSOrderedDescending)
            { // Created should be compared first
                [createdRecords addObject: contactID];
                [self.delegate setProgressTotal: ++total];
            }
            else if ([self.dateAddressBookLoaded compare: modified] != NSOrderedDescending)
            { // Contact changed
                [changedRecords addObject: contactID];
                [self.delegate setProgressTotal: ++total];
            }

            // Aggregate groups are repopulated on each load
            // so there's no need to remove members from them
            if (![linkedRecords member: contactID])
            {
                [mainAggregateGroup.memberIDs addObject: contactID];
            }
            [aggregateGroup.memberIDs addObject: contactID];
        }
    }
    
    if (self.status == kAddressBookLoading)
    {
        [appContactIdentifiers minusSet: nativeContactIdentifiers];
        NSLog(@"Deleted contactIDs: %@", appContactIdentifiers);
        for (NSNumber *contactID in appContactIdentifiers)
        {
          [self contactIdentifiersDeleteRecordID: contactID.integerValue withAddressBookRef: addressBook];
        }
    }
    
    for (NSNumber *recordID in createdRecords)
    {
        [self.delegate setProgressCurrent: ++i];
        NSLog(@"% 3d : %@ is new", recordID.integerValue, CFBridgingRelease(ABRecordCopyCompositeName(ABAddressBookGetPersonWithRecordID(addressBook, recordID.integerValue))));
        [self contactIdentifiersInsertRecordID: recordID.integerValue withAddressBookRef: addressBook];
    }
    for (NSNumber *recordID in changedRecords)
    {
        [self.delegate setProgressCurrent: ++i];
        NSLog(@"% 3d : %@ did change", recordID.integerValue, CFBridgingRelease(ABRecordCopyCompositeName(ABAddressBookGetPersonWithRecordID(addressBook, recordID.integerValue))));
        [self contactIdentifiersDeleteRecordID: recordID.integerValue withAddressBookRef: addressBook];
        [self contactIdentifiersInsertRecordID: recordID.integerValue withAddressBookRef: addressBook];
    }
}

- (NSString *)sortNameForRecordID: (ABRecordID)recordID inAddressBook: (ABAddressBookRef)addressBook
{
    ABRecordRef recordRef = ABAddressBookGetPersonWithRecordID(addressBook, recordID);
    
    NSNumber *kind = (NSNumber *)CFBridgingRelease(ABRecordCopyValue(recordRef, kABPersonKindProperty));
    
    NSString *ret;
    if ([kind isEqualToNumber: (NSNumber *)kABPersonKindPerson])
    {
        NSString *first = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef, kABPersonFirstNameProperty));
        NSString *last = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef, kABPersonLastNameProperty));
        
        if (kABPersonSortByFirstName == [AKAddressBook sharedInstance].sortOrdering)
        {
            ret = [NSString stringWithFormat: @"%@ %@", first, last];
        }
        else
        {
            ret = [NSString stringWithFormat: @"%@ %@", last, first];
        }
    }
    else if ([kind isEqualToNumber: (NSNumber *)kABPersonKindOrganization])
    {
        ret = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef, kABPersonOrganizationProperty));
    }
    return ret;
}

#pragma mark - Insert / Remove methods

- (void)contactIdentifiersInsertRecordID: (ABRecordID)recordID withAddressBookRef: (ABAddressBookRef)addressBook
{
    ABRecordRef recordRef = ABAddressBookGetPersonWithRecordID(addressBook, recordID);
    NSString *name = [AKAddressBook nameToDetermineSectionForRecordRef: recordRef withSortOrdering: self.sortOrdering];
    NSString *sectionKey = [AKContact sectionKeyForName: name];
    
    NSMutableArray *sectionArray = (NSMutableArray *)[self.allContactIdentifiers objectForKey: sectionKey];
    
    NSUInteger index = [AKAddressBook indexOfRecordID: recordID inArray: sectionArray withSortOrdering: self.sortOrdering andAddressBookRef: addressBook];
    
    [sectionArray insertObject: [NSNumber numberWithInteger: recordID] atIndex: index];
}

- (void)contactIdentifiersDeleteRecordID: (ABRecordID)recordID withAddressBookRef: (ABAddressBookRef)addressBook
{
    NSString *sectionKey;
    NSUInteger index = NSNotFound;
    NSMutableArray *sectionArray = nil;
    
    ABRecordRef recordRef = ABAddressBookGetPersonWithRecordID(addressBook, recordID);
    if (recordRef)
    {
        NSString *name = [AKAddressBook nameToDetermineSectionForRecordRef: recordRef withSortOrdering: self.sortOrdering];
        sectionKey = [AKContact sectionKeyForName: name];
    }
    
    if (sectionKey)
    {
        sectionArray = [self.allContactIdentifiers objectForKey: sectionKey];
        index = [sectionArray indexOfObject: @(recordID)];
    }
    
    if (index == NSNotFound)
    { // Moved to another section
        for (NSString *key in self.allContactIdentifiers)
        { // This is slow but should run seldom
            if ([sectionKey isEqualToString: key])
            {  // Cannot be here
                continue;
            }
            sectionArray = [self.allContactIdentifiers objectForKey: key];
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
}

# pragma mark - Class methods

+ (NSUInteger)indexOfRecordID: (ABRecordID) recordID inArray: (NSArray *)array withSortOrdering: (ABPersonSortOrdering)sortOrdering andAddressBookRef: (ABAddressBookRef)addressBook
{
    return [array indexOfObject: @(recordID)
                  inSortedRange: (NSRange){0, array.count}
                        options: NSBinarySearchingInsertionIndex
                usingComparator: [AKAddressBook recordIDBasedComparatorWithSortOrdering: sortOrdering andAddressBook: addressBook]];
}

+ (NSString *)nameToDetermineSectionForRecordRef: (ABRecordRef)recordRef withSortOrdering: (ABPersonSortOrdering)sortOrdering
{
    NSString *ret;
    NSNumber *kind = (NSNumber *)CFBridgingRelease(ABRecordCopyValue(recordRef, kABPersonKindProperty));
    if ([kind isEqualToNumber: (NSNumber *)kABPersonKindPerson])
    {
        ABPropertyID property = (sortOrdering == kABPersonSortByFirstName) ? kABPersonFirstNameProperty : kABPersonLastNameProperty;
        ret = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef, property));
        if (!ret.length)
        {
            property = (property == kABPersonFirstNameProperty) ? kABPersonLastNameProperty : kABPersonFirstNameProperty;
            ret = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef, property));
        }
    }
    else if ([kind isEqualToNumber: (NSNumber *)kABPersonKindOrganization])
    {
        ret = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef, kABPersonOrganizationProperty));
    }
    return ret;
}

#pragma mark - Comparators

+ (NSComparator)recordIDBasedComparatorWithSortOrdering: (ABPersonSortOrdering)sortOrdering andAddressBook: (ABAddressBookRef)addressBook
{
    NSInteger organization = [(NSNumber *)kABPersonKindOrganization integerValue];
    NSInteger person = [(NSNumber *)kABPersonKindPerson integerValue];
    
    NSComparator comparator = ^NSComparisonResult(id obj1, id obj2) {
        ABRecordRef recordRef2 = ABAddressBookGetPersonWithRecordID(addressBook, [(NSNumber *)obj2 integerValue]);
        ABRecordRef recordRef1 = ABAddressBookGetPersonWithRecordID(addressBook, [(NSNumber *)obj1 integerValue]);
        
        NSInteger kind1 = [(NSNumber *)CFBridgingRelease(ABRecordCopyValue(recordRef1, kABPersonKindProperty)) integerValue];
        NSInteger kind2 = [(NSNumber *)CFBridgingRelease(ABRecordCopyValue(recordRef2, kABPersonKindProperty)) integerValue];
        
        ABPropertyID prop1 = (sortOrdering == kABPersonSortByFirstName) ? kABPersonFirstNameProperty : kABPersonLastNameProperty;
        ABPropertyID prop2 = (sortOrdering == kABPersonSortByFirstName) ? kABPersonFirstNameProperty : kABPersonLastNameProperty;
        
        NSString *elem1, *elem2;
        NSComparisonResult ret = NSOrderedSame;
        
        if (kind1 == person && kind2 == person)
        {
            elem1 = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef1, prop1));
            elem2 = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef2, prop2));
            
            ret = [elem1 localizedCaseInsensitiveCompare: elem2];
            if (ret == NSOrderedSame)
            {
                prop1 = prop2 = (sortOrdering == kABPersonSortByFirstName) ? kABPersonLastNameProperty : kABPersonFirstNameProperty;
                
                elem1 = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef1, prop1));
                elem2 = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef2, prop2));
                
                ret = [elem1 localizedCaseInsensitiveCompare: elem2];
            }
        }
        else if (kind1 == person && kind2 == organization)
        {
            prop2 = kABPersonOrganizationProperty;
            
            elem1 = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef1, prop1));
            elem2 = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef2, prop2));
            
            ret = [elem1 localizedCaseInsensitiveCompare: elem2];
            if (ret == NSOrderedSame)
            {
                prop1 = (sortOrdering == kABPersonSortByFirstName) ? kABPersonLastNameProperty : kABPersonFirstNameProperty;
                
                elem1 = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef1, prop1));
                ret = [elem1 localizedCaseInsensitiveCompare: elem2];
            }
        }
        else if (kind1 == organization && kind2 == person)
        {
            prop1 = kABPersonOrganizationProperty;
            
            elem1 = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef1, prop1));
            elem2 = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef2, prop2));
            
            ret = [elem1 localizedCaseInsensitiveCompare: elem2];
            if (ret == NSOrderedSame)
            {
                prop2 = (sortOrdering == kABPersonSortByFirstName) ? kABPersonLastNameProperty : kABPersonFirstNameProperty;
                
                elem2 = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef2, prop2));
                ret = [elem1 localizedCaseInsensitiveCompare: elem2];
            }
        }
        else if (kind1 == organization && kind2 == organization)
        {
            prop1 = prop2 = kABPersonOrganizationProperty;
            
            elem1 = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef1, prop1));
            elem2 = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef2, prop2));
            
            ret = [elem1 localizedCaseInsensitiveCompare: elem2];
        }
        return ret;
    };
    return comparator;
}

@end
