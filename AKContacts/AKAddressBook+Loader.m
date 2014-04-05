//
//  AKAddressBook.h
//
//  Copyright (c) 2013 Adam Kornafeld All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions
//  are met:
//  1. Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright
//  notice, this list of conditions and the following disclaimer in the
//  documentation and/or other materials provided with the distribution.
//  3. The name of the author may not be used to endorse or promote products
//  derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
//  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
//  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
        
        if ([self unarchiveCache]) {
            self.status = kAddressBookOnline;
            self.status = kAddressBookLoading;
        }
        else if (!self.hashTableSortedByFirst || !self.hashTableSortedByLast || !self.hashTableSortedByPhone) {
            self.hashTableSortedByFirst = [[NSMutableDictionary alloc] init];
            self.hashTableSortedByLast = [[NSMutableDictionary alloc] init];
            self.hashTableSortedByPhone = [[NSMutableDictionary alloc] init];
            
            for (NSString *sectionKey in [AKAddressBook sectionKeys])
            {
                [self.hashTableSortedByFirst setObject: [[NSMutableArray alloc] init] forKey: sectionKey];
                [self.hashTableSortedByLast setObject: [[NSMutableArray alloc] init] forKey: sectionKey];
            }
            NSArray *sectionKeys = @[@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9"];
            for (NSString *sectionKey in sectionKeys)
            {
                [self.hashTableSortedByFirst setObject: [[NSMutableArray alloc] init] forKey: sectionKey];
                [self.hashTableSortedByLast setObject: [[NSMutableArray alloc] init] forKey: sectionKey];
                [self.hashTableSortedByPhone setObject: [[NSMutableArray alloc] init] forKey: sectionKey];
            }
        }
        
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
        
        if (self.status == kAddressBookLoading)
        {
            if ([self.presentationDelegate respondsToSelector:@selector(addressBookDidEndUpdates:)])
            {
                [self.presentationDelegate addressBookDidEndUpdates: self];
            }
        }
        
        [self archiveCache];
        
        if (completionHandler) {
            completionHandler(YES);
        }
    };
    
    dispatch_async(self.serial_queue, block);
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
    
    NSMutableSet *allContactIdentifiers = [[NSMutableSet alloc] init];
    if (self.status == kAddressBookLoading)
    {
        [allContactIdentifiers addObjectsFromArray: self.allContactIDs];
    }
    
    AKSource *aggregateSource = [self sourceForSourceId: kSourceAggregate];
    AKGroup *mainAggregateGroup = [aggregateSource groupForGroupId: kGroupAggregate];
    
    NSMutableSet *nativeContactIDs = [[NSMutableSet alloc] init];
    NSMutableSet *appContactIDs = [[NSMutableSet alloc] init];
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
            
            AKContact *contact = [self contactForContactId: recordID withAddressBookRef: addressBookRef];
            
            NSLog(@"%d intHash: %lu RecordHash: %lu", recordID, (unsigned long)[contactID hash], (unsigned long)[(__bridge id)recordRef hash]);
            
            [nativeContactIDs addObject: contactID];
            
            NSDate *created = [contact valueForProperty: kABPersonCreationDateProperty];
            NSDate *modified = [contact valueForProperty: kABPersonModificationDateProperty];
            
            NSArray *linkedContactIDs = [contact linkedContactIDs];
            NSMutableSet *linkedRecordIDs = [[NSMutableSet alloc] init];
            for (NSNumber *contactID in linkedContactIDs)
            {
                [linkedRecordIDs addObject: contactID];
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
    
    NSLog(@"Native Address book sweep %.2f", fabs([[NSDate date] timeIntervalSinceDate: start]));
    start = [NSDate date];
    
    if (self.status == kAddressBookLoading)
    {
        if ([self.presentationDelegate respondsToSelector: @selector(addressBookWillBeginUpdates:)])
        {
            [self.presentationDelegate addressBookWillBeginUpdates: self];
        }
        
        [allContactIdentifiers minusSet: nativeContactIDs];
        [allContactIdentifiers minusSet: appContactIDs];
        if (allContactIdentifiers.count > 0)
        {
            NSLog(@"Deleted contactIDs: %@", allContactIdentifiers);
        }
        for (NSNumber *recordID in allContactIdentifiers)
        {
            AKContact *contact = [self contactForContactId: recordID.intValue withAddressBookRef: addressBookRef];
            [self deleteRecordIDfromContactIdentifiersForContact: contact];
        }
    }
    
    for (NSNumber *recordID in createdRecordIDs)
    {
        self.loadProgress.completedUnitCount += 1;
        AKContact *contact =  [self contactForContactId: recordID.intValue withAddressBookRef: addressBookRef];
        if (self.status == kAddressBookLoading)
        {
            NSLog(@"% 3d : %@ is new", recordID.intValue, contact.compositeName);
        }
        if (![allLinkedRecordIDs member: recordID])
        {
            [self insertRecordIDinContactIdentifiersForContact: contact withAddressBookRef: addressBookRef];
        }
        [self processPhoneNumbersOfContact: contact withABAddressBookRef: addressBookRef];
    }
    for (NSNumber *recordID in changedRecordIDs)
    {
        self.loadProgress.completedUnitCount += 1;
        AKContact *contact = [self contactForContactId: recordID.intValue withAddressBookRef: addressBookRef];
        if (self.status == kAddressBookLoading)
        {
            NSLog(@"% 3d : %@ did change", recordID.intValue, contact.compositeName);
        }
        [self deleteRecordIDfromContactIdentifiersForContact: contact];
        [self insertRecordIDinContactIdentifiersForContact: contact withAddressBookRef: addressBookRef];
    }
    
    NSLog(@"Lookup table contstructed %.2f", fabs([[NSDate date] timeIntervalSinceDate: start]));
}

- (void)processPhoneNumbersOfContact: (AKContact *)contact withABAddressBookRef: (ABAddressBookRef)addressBookRef
{
    NSArray *phoneIdentifiers = [contact identifiersForMultiValueProperty: kABPersonPhoneProperty];
    if (phoneIdentifiers.count > 0)
    {
        for (NSNumber *identifier in phoneIdentifiers) {
            NSString *value = [contact valueForMultiValueProperty: kABPersonPhoneProperty andIdentifier: identifier.intValue];
            NSString *digits = value.stringWithNonDigitsRemoved;
            if (digits.length > 0)
            {
                NSString *key = [digits substringToIndex: 1];
                NSMutableArray *sectionArray = [self.hashTableSortedByPhone objectForKey: key];
                
                NSUInteger index = [AKAddressBook indexOfRecordID: contact.recordID inArray: sectionArray withSortOrdering: self.sortOrdering andAddressBookRef: addressBookRef];
                [sectionArray insertObject: @(contact.recordID) atIndex: index];
            }
            for (NSString *prefix in [AKAddressBook prefixesToDiscardOnSearch])
            {
                if ([digits hasPrefix: prefix])
                {
                    digits = [digits substringFromIndex: prefix.length];
                    if (digits.length > 0)
                    {
                        NSString *key = [digits substringToIndex: prefix.length];
                        NSMutableArray *sectionArray = [self.hashTableSortedByPhone objectForKey: key];
                        NSUInteger index = [AKAddressBook indexOfRecordID: contact.recordID inArray: sectionArray withSortOrdering: self.sortOrdering andAddressBookRef: addressBookRef];
                        [sectionArray insertObject: @(contact.recordID) atIndex: index];
                    }
                }
            }
        }
    }
}

#pragma mark - Insert / Remove methods

- (void)insertRecordIDinContactIdentifiersForContact: (AKContact *)contact withAddressBookRef: (ABAddressBookRef)addressBookRef
{
    // First name
    NSString *firstName = [contact nameToDetermineSectionForSortOrdering: kABPersonSortByFirstName];
    NSString *sectionKey = [AKContact sectionKeyForName: firstName];
    NSMutableArray *sectionArray = (NSMutableArray *)[self.hashTableSortedByFirst objectForKey: sectionKey];
    
    NSUInteger index = [AKAddressBook indexOfRecordID: contact.recordID inArray: sectionArray withSortOrdering: kABPersonSortByFirstName andAddressBookRef: addressBookRef];
    [sectionArray insertObject: @(contact.recordID) atIndex: index];
    
    if ([sectionKey isEqualToString: @"#"] && [firstName isMemberOfCharacterSet: [NSCharacterSet decimalDigitCharacterSet]])
    {
        sectionKey = [firstName substringToIndex: 1];
        sectionArray = (NSMutableArray *)[self.hashTableSortedByFirst objectForKey: sectionKey];
        index = [AKAddressBook indexOfRecordID: contact.recordID inArray: sectionArray withSortOrdering: kABPersonSortByFirstName andAddressBookRef: addressBookRef];
        [sectionArray insertObject: @(contact.recordID) atIndex: index];
    }
    
    // Last name
    NSString *lastName = [contact nameToDetermineSectionForSortOrdering: kABPersonSortByLastName];
    sectionKey = [AKContact sectionKeyForName: lastName];
    sectionArray = (NSMutableArray *)[self.hashTableSortedByLast objectForKey: sectionKey];
    index = [AKAddressBook indexOfRecordID: contact.recordID inArray: sectionArray withSortOrdering: kABPersonSortByLastName andAddressBookRef: addressBookRef];
    [sectionArray insertObject: @(contact.recordID) atIndex: index];
    
    if ([sectionKey isEqualToString: @"#"] && [lastName isMemberOfCharacterSet: [NSCharacterSet decimalDigitCharacterSet]])
    {
        sectionKey = [lastName substringToIndex: 1];
        sectionArray = (NSMutableArray *)[self.hashTableSortedByLast objectForKey: sectionKey];
        index = [AKAddressBook indexOfRecordID: contact.recordID inArray: sectionArray withSortOrdering: kABPersonSortByLastName andAddressBookRef: addressBookRef];
        [sectionArray insertObject: @(contact.recordID) atIndex: index];
    }
    
    if (self.status == kAddressBookLoading)
    {
        if ([self.presentationDelegate respondsToSelector:@selector(addressBook:didInsertRecordID:)])
        {
            [self.presentationDelegate addressBook: self didInsertRecordID: contact.recordID];
        }
    }
}

- (void)deleteRecordIDfromContactIdentifiersForContact: (AKContact *)contact
{
    NSString *sectionKeyByFirst, *sectionKeyByLast;
    
    if (contact)
    { // Can still exist when it is removed and added due to a name change
        NSString *nameByFirst = [contact nameToDetermineSectionForSortOrdering: kABPersonSortByFirstName];
        NSString *nameByLast = [contact nameToDetermineSectionForSortOrdering: kABPersonSortByLastName];
        sectionKeyByFirst = [AKContact sectionKeyForName: nameByFirst];
        sectionKeyByLast = [AKContact sectionKeyForName: nameByLast];
    }
    
    NSUInteger indexByFirst = [AKAddressBook removeRecordID: contact.recordID withSectionKey: sectionKeyByFirst fromContactIdentifierDictionary: self.hashTableSortedByFirst];
    NSUInteger indexByLast = [AKAddressBook removeRecordID: contact.recordID withSectionKey: sectionKeyByLast fromContactIdentifierDictionary: self.hashTableSortedByLast];
    
    if ((indexByFirst != NSNotFound || indexByLast != NSNotFound) && self.status == kAddressBookLoading)
    {
        if ([self.presentationDelegate respondsToSelector:@selector(addressBook:didRemoveRecordID:)])
        {
            [self.presentationDelegate addressBook: self didRemoveRecordID: contact.recordID];
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

+ (NSString *)fileNameForSelector: (SEL)selector
{
    NSString *fileName;
    
    if ([NSStringFromSelector(selector) isEqualToString: NSStringFromSelector(@selector(hashTableSortedByFirst))])
    {
        fileName = @"cacheFirst.plist";
    }
    else if ([NSStringFromSelector(selector) isEqualToString: NSStringFromSelector(@selector(hashTableSortedByLast))])
    {
        fileName = @"cacheLast.plist";
    }
    else if ([NSStringFromSelector(selector) isEqualToString: NSStringFromSelector(@selector(hashTableSortedByPhone))])
    {
        fileName = @"cacheDigit.plist";
    }
    return fileName;
}

+ (NSString *)documentsDirectoryPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex: 0];
}

#pragma mark - Comparators

+ (NSComparator)recordIDBasedComparatorWithSortOrdering: (ABPersonSortOrdering)sortOrdering andAddressBookRef: (ABAddressBookRef)addressBookRef
{
    NSComparator comparator = ^NSComparisonResult(id obj1, id obj2) {
        ABRecordID recordID1 = [(NSNumber *)obj1 intValue];
        ABRecordID recordID2 = [(NSNumber *)obj2 intValue];
        
        __weak AKContact *contact1 = [[AKAddressBook sharedInstance] contactForContactId: recordID1 withAddressBookRef: addressBookRef];
        __weak AKContact *contact2 = [[AKAddressBook sharedInstance] contactForContactId: recordID2 withAddressBookRef: addressBookRef];
        
        ABPropertyID prop1 = (sortOrdering == kABPersonSortByFirstName) ? kABPersonFirstNameProperty : kABPersonLastNameProperty;
        ABPropertyID prop2 = (sortOrdering == kABPersonSortByFirstName) ? kABPersonFirstNameProperty : kABPersonLastNameProperty;
        
        NSString *elem1, *elem2;
        NSComparisonResult result = NSOrderedSame;
        
        if (contact1.isPerson && contact2.isPerson)
        {
            elem1 = [contact1 valueForProperty: prop1];
            elem2 = [contact2 valueForProperty: prop2];
            
            result = [elem1 localizedCaseInsensitiveCompare: elem2];
            if (result == NSOrderedSame)
            {
                prop1 = prop2 = (sortOrdering == kABPersonSortByFirstName) ? kABPersonLastNameProperty : kABPersonFirstNameProperty;
                
                elem1 = [contact1 valueForProperty: prop1];
                elem2 = [contact2 valueForProperty: prop2];
                
                result = [elem1 localizedCaseInsensitiveCompare: elem2];
            }
        }
        else if (contact1.isPerson && contact2.isOrganization)
        {
            prop2 = kABPersonOrganizationProperty;
            
            elem1 = [contact1 valueForProperty: prop1];
            elem2 = [contact2 valueForProperty: prop2];
            
            result = [elem1 localizedCaseInsensitiveCompare: elem2];
            if (result == NSOrderedSame)
            {
                prop1 = (sortOrdering == kABPersonSortByFirstName) ? kABPersonLastNameProperty : kABPersonFirstNameProperty;
                
                elem1 = [contact1 valueForProperty: prop1];
                result = [elem1 localizedCaseInsensitiveCompare: elem2];
            }
        }
        else if (contact1.isOrganization && contact2.isPerson)
        {
            prop1 = kABPersonOrganizationProperty;
            
            elem1 = [contact1 valueForProperty: prop1];
            elem2 = [contact2 valueForProperty: prop2];
            
            result = [elem1 localizedCaseInsensitiveCompare: elem2];
            if (result == NSOrderedSame)
            {
                prop2 = (sortOrdering == kABPersonSortByFirstName) ? kABPersonLastNameProperty : kABPersonFirstNameProperty;
                
                elem2 = [contact2 valueForProperty: prop2];
                result = [elem1 localizedCaseInsensitiveCompare: elem2];
            }
        }
        else if (contact1.isOrganization && contact2.isOrganization)
        {
            prop1 = prop2 = kABPersonOrganizationProperty;
            
            elem1 = [contact1 valueForProperty: prop1];
            elem2 = [contact2 valueForProperty: prop2];
            
            result = [elem1 localizedCaseInsensitiveCompare: elem2];
        }
        return result;
    };
    return comparator;
}

#pragma mark - Cache Archival

- (BOOL)archiveDictionary: (NSDictionary *)dictionary withFileName: (NSString *)fileName
{
    BOOL success = NO;
    
    NSString *path = [[AKAddressBook documentsDirectoryPath] stringByAppendingPathComponent: fileName];
    
    NSOutputStream *stream = [NSOutputStream outputStreamToFileAtPath: path append: NO];
    if (stream)
    {
        CFStringRef err;
        [stream open];
        
        CFIndex index = CFPropertyListWriteToStream((__bridge CFPropertyListRef)(dictionary), (__bridge CFWriteStreamRef)stream, kCFPropertyListBinaryFormat_v1_0, &err);
        if (index == 0)
        {
            NSLog(@"CFPropertyListWriteToStream error: %@", err);
        }
        [stream close];
        success = YES;
    }
    else
    {
        NSLog(@"Failed to create output stream");
    }
    return success;
}

- (NSMutableDictionary *)unarchiveDictionaryWithFileName: (NSString *)fileName
{
    NSMutableDictionary *dictionary;
    
    NSString *path = [[AKAddressBook documentsDirectoryPath] stringByAppendingPathComponent: fileName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath: path])
    {
        NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath: path];
        if (stream != nil)
        {
            CFStringRef error;
            CFPropertyListFormat format;
            
            [stream open];
            
            CFMutableDictionaryRef plist = (CFMutableDictionaryRef)CFPropertyListCreateFromStream(CFAllocatorGetDefault(), (__bridge CFReadStreamRef)(stream), 0, kCFPropertyListMutableContainers, &format, &error);
            
            [stream close];
            
            if (!error && plist)
            {
                dictionary = (NSMutableDictionary *)CFBridgingRelease(plist);
            }
            else
            {
                if (plist) {
                    CFRelease(plist);
                }
                NSLog(@"CFPropertyListCreateFromStream error: %@", error);
            }
        }
        else
        {
            NSLog(@"Failed to create input stream");
        }
    }
    return dictionary;
}

- (BOOL)unarchiveCache
{
    NSMutableDictionary *dictionary = [self unarchiveDictionaryWithFileName: [AKAddressBook fileNameForSelector: @selector(hashTableSortedByFirst)]];
    self.hashTableSortedByFirst = dictionary;
    
    dictionary = [self unarchiveDictionaryWithFileName: [AKAddressBook fileNameForSelector: @selector(hashTableSortedByLast)]];
    self.hashTableSortedByLast = dictionary;
    
    dictionary = [self unarchiveDictionaryWithFileName: [AKAddressBook fileNameForSelector: @selector(hashTableSortedByPhone)]];
    self.hashTableSortedByPhone = dictionary;
    
    return (self.hashTableSortedByFirst && self.hashTableSortedByLast && self.hashTableSortedByPhone) ? YES : NO;
}

- (BOOL)archiveCache
{
    BOOL success_1 = [self archiveDictionary: self.hashTableSortedByFirst withFileName: [AKAddressBook fileNameForSelector: @selector(hashTableSortedByFirst)]];
    
    BOOL success_2 = [self archiveDictionary: self.hashTableSortedByLast withFileName: [AKAddressBook fileNameForSelector: @selector(hashTableSortedByLast)]];
    
    BOOL success_3 = [self archiveDictionary: self.hashTableSortedByPhone withFileName: [AKAddressBook fileNameForSelector: @selector(hashTableSortedByPhone)]];
    
    return (success_1 && success_2 && success_3);
}

- (BOOL)deleteArchiveWithFileName: (NSString *)fileName
{
    BOOL success = NO;
    NSString *path = [[AKAddressBook documentsDirectoryPath] stringByAppendingPathComponent: fileName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath: path])
    {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath: path error: &error];
        if (!error)
        {
            success = YES;
        }
    }
    return success;
}

- (BOOL)deleteArchive
{
    BOOL success_1 = [self deleteArchiveWithFileName: [AKAddressBook fileNameForSelector: @selector(hashTableSortedByFirst)]];
    BOOL success_2 = [self deleteArchiveWithFileName: [AKAddressBook fileNameForSelector: @selector(hashTableSortedByLast)]];
    BOOL success_3 = [self deleteArchiveWithFileName: [AKAddressBook fileNameForSelector: @selector(hashTableSortedByPhone)]];
    
    return (success_1 && success_2 && success_3);
}

@end
