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

//
//  AKContactsTableViewDataSource.m
//  AKContacts
//
//  Created by Adam Kornafeld on 1/15/14.
//  Copyright (c) 2014 Adam Kornafeld. All rights reserved.
//

#import "AKContactsTableViewDataSource.h"
#import "AKAddressBook.h"
#import "AKAddressBook+Loader.h"
#import "AKContact.h"
#import "AKGroup.h"
#import "AKSource.h"

@interface AKSearchStackElement : NSObject

@property (copy, nonatomic) NSString *character;
@property (strong, nonatomic) NSArray *matches;

@end

@implementation AKSearchStackElement

@end

@interface AKContactsTableViewDataSource ()

- (AKSearchStackElement *)searchStackElementForTerm: (NSString *)searchTerm withCharacterIndex: (NSInteger)characterIndex;
- (NSArray *)contactIDsHavingPrefix: (NSString *)prefix;
- (NSArray *)contactIDsHavingNamePrefix: (NSString *)prefix;
- (NSArray *)contactIDsHavingNumberPrefix: (NSString *)prefix;
- (NSArray *)filterArray: (NSArray *)array withTerms:(NSArray *)terms andSortOrdering: (ABPersonSortOrdering)sortOrdering;

@property (strong, nonatomic) NSString *searchTerm;
@property (strong, nonatomic) NSMutableArray *searchStack;

/**
 Terminates array operations if waiting on the addressbook semaphore
 */
@property (assign, nonatomic) BOOL shouldTerminate;

@end

@implementation AKContactsTableViewDataSource

#pragma mark - Instance methods

- (id)init
{
    self = [super init];
    if (self)
    {
        _manifoldingPropertyID = kABMultiValueInvalidIdentifier;
    }
    return self;
}

- (NSInteger)displayedContactsCount
{
    return [self.displayedContactIDs count];
}

- (AKContact *)contactForIndexPath: (NSIndexPath *)indexPath
{
    NSAssert([NSThread isMainThread], @"Must be dispatched on main thread");
    
    AKContact *contact;
    if ([[AKAddressBook sharedInstance] hasStatus: kAddressBookOnline]) {
        if (self.searchTerm.length > 0) {
            if (indexPath.row < self.filteredContactIDs.count) {
                NSNumber *recordID = [self.filteredContactIDs objectAtIndex: indexPath.row];
                contact = [[AKAddressBook sharedInstance] contactForContactId: recordID.intValue];
            }
        }
        else {
            if ([self.keys count] > indexPath.section) {
                NSString *key = [self.keys objectAtIndex: indexPath.section];
                NSArray *identifiersArray = [self.contactIDs objectForKey: key];
                if (identifiersArray.count > 0 && indexPath.row <= identifiersArray.count) {
                    NSNumber *recordID = [identifiersArray objectAtIndex: indexPath.row];
                    contact = [[AKAddressBook sharedInstance] contactForContactId: recordID.intValue];
                }
            }
        }
    }
    return contact;
}

- (void)loadData
{
    AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];
    
    AKSource *source = [akAddressBook sourceForSourceId: akAddressBook.sourceID];
    AKGroup *group = [source groupForGroupId: akAddressBook.groupID];
    NSMutableSet *groupMembers = [group memberIDs];
    
    NSArray *sectionKeys = [AKAddressBook sectionKeys];
    
    NSMutableDictionary *contactIDs = [[NSMutableDictionary alloc] initWithCapacity: [akAddressBook.hashTable count]];
    NSMutableArray *keys = [[NSMutableArray alloc] init];
    NSMutableSet *displayedContactIDs = [[NSMutableSet alloc] init];
    
    for (NSString *key in sectionKeys)
    {
        NSArray *arrayForKey = [akAddressBook.hashTable objectForKey: key];
        NSMutableArray *sectionArray = [arrayForKey mutableCopy];
        
        NSMutableArray *recordsToRemove = [[NSMutableArray alloc] init];
        for (NSNumber *contactID in sectionArray)
        {
            if (![groupMembers member: contactID]) {
                [recordsToRemove addObject: contactID];
            }
        }
        [sectionArray removeObjectsInArray: recordsToRemove];
        [displayedContactIDs addObjectsFromArray: sectionArray];
        
        if (sectionArray.count > 0)
        {
            [contactIDs setObject: sectionArray forKey: key];
            [keys addObject: key];
        }
    }
    self.contactIDs = [contactIDs copy];
    self.keys = [keys copy];
    self.displayedContactIDs = [displayedContactIDs copy];
    self.searchTerm = nil;
}

- (void)handleSearchForTerm:(NSString *)searchTerm {
    
    NSAssert([NSThread isMainThread], @"Must be dispatched on main thread");
    
    // Don't trim trailing whitespace needed for tokenization
    searchTerm = [searchTerm stringByTrimmingLeadingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
    
    NSString *previousSearchTerm = self.searchTerm;
    NSString *commonPrefix = [previousSearchTerm commonPrefixWithString: searchTerm options: 0];
    NSInteger nextCharacterIndex = (searchTerm.length > 0) ? (searchTerm.length - 1) : 0;
    
    if (commonPrefix.length < previousSearchTerm.length) {
        self.shouldTerminate = YES;
        
        NSDate *start = [NSDate date];
        dispatch_semaphore_wait([AKAddressBook sharedInstance].semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"Semaphore raised in %.2f", fabs([[NSDate date] timeIntervalSinceDate: start]));
        
        self.shouldTerminate = NO;
        
        [self clearSearchStackFromIndex: commonPrefix.length];
        
        nextCharacterIndex = commonPrefix.length;
        
        dispatch_semaphore_signal([AKAddressBook sharedInstance].semaphore);
    }
    
    dispatch_block_t block = ^{
        
        dispatch_semaphore_wait([AKAddressBook sharedInstance].semaphore, DISPATCH_TIME_FOREVER);
        
        if (searchTerm.length > 0) {
            if (searchTerm.length > self.searchStack.count)
            {
                for (NSInteger index = nextCharacterIndex; index < searchTerm.length; ++index)
                {
                    NSString *character = [searchTerm substringWithRange: NSMakeRange(index, 1)];
                    
                    if (![character isMemberOfCharacterSet: [NSCharacterSet whitespaceCharacterSet]])
                    {
                        AKSearchStackElement *element = [self searchStackElementForTerm: searchTerm withCharacterIndex: index];
                        if (element) {
                            [self.searchStack addObject: element];
                        }
                    }
                    else if (self.searchStack.count > 0)
                    {
                        AKSearchStackElement *previousStackElement = [self.searchStack lastObject];
                        
                        AKSearchStackElement *element = [[AKSearchStackElement alloc] init];
                        element.character = character;
                        element.matches = [previousStackElement.matches copy];
                        [self.searchStack addObject: element];
                    }
                }
            }
            
        }
        
        if (self.searchStack.count > 0) {
            self.searchTerm = searchTerm;
            self.filteredContactIDs = [self.searchStack.lastObject matches];
        }
        else {
            [self finishSearch];
        }
        
        if ([self.delegate respondsToSelector: @selector(dataSourceDidEndSearch:)]) {
            [self.delegate dataSourceDidEndSearch: self];
        }
        
        dispatch_semaphore_signal([AKAddressBook sharedInstance].semaphore);
    };
    
    dispatch_async([AKAddressBook sharedInstance].serial_queue, block);
}

- (void)clearSearchStackFromIndex: (NSInteger)clearStackFromIndex {
    if (clearStackFromIndex < self.searchStack.count) {
        if (clearStackFromIndex == 0) {
            [self finishSearch];
        }
        else {
            NSRange range = NSMakeRange(clearStackFromIndex, self.searchStack.count - clearStackFromIndex);
            [self.searchStack removeObjectsAtIndexes: [NSIndexSet indexSetWithIndexesInRange: range]];
        }
    }
}

- (AKSearchStackElement *)searchStackElementForTerm: (NSString *)searchTerm withCharacterIndex: (NSInteger)characterIndex
{
    AKSearchStackElement *element;
    if(characterIndex<[searchTerm length]) {
        searchTerm = [searchTerm substringToIndex: (characterIndex + 1)]; // Cut tail when the cursor is not at the end of the text
        NSArray *terms = [searchTerm componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
        
        NSString *character = [searchTerm substringWithRange: NSMakeRange(characterIndex, 1)];
        element = [[AKSearchStackElement alloc] init];
        element.character = character;
        
        if (characterIndex == 0)
        {
            element.character = character;
            element.matches = [self contactIDsHavingPrefix: character];
        }
        else
        {
            NSArray *matchingIDs = [self.searchStack.lastObject matches];
            matchingIDs = [self filterArray: matchingIDs withTerms: terms andSortOrdering: [AKAddressBook sharedInstance].sortOrdering];
            element.matches = [matchingIDs copy];
        }
    }
    return element;
}

- (NSArray *)contactIDsHavingPrefix: (NSString *)prefix
{
    NSArray *contactIDs;
    if ([prefix isMemberOfCharacterSet: [NSCharacterSet letterCharacterSet]])
    {
        contactIDs = [self contactIDsHavingNamePrefix: prefix];
    }
    else
    {
        contactIDs = [self contactIDsHavingNumberPrefix: prefix];
    }
    
    if (self.manifoldingPropertyID == kABPersonPhoneProperty) {
        NSMutableSet *manifoldedSet = [[NSMutableSet alloc] initWithArray: contactIDs];
        [manifoldedSet minusSet: [AKAddressBook sharedInstance].contactIDsWithoutPhoneNumber];
        contactIDs = [manifoldedSet allObjects];
    }
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    CFErrorRef error = NULL;
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, &error);
    if (error) { CFStringRef desc = CFErrorCopyDescription(error); NSLog(@"ABAddressBookCreateWithOptions (%ld): %@", CFErrorGetCode(error), desc); CFRelease(desc); error = NULL; }
#else
    ABAddressBookRef addressBookRef = ABAddressBookCreate();
#endif
    
    contactIDs = [self sortedArray: contactIDs withAddressBookRef: addressBookRef];
    
    if (addressBookRef) {
        CFRelease(addressBookRef);
    }
    return contactIDs;
}

- (NSArray *)contactIDsHavingNamePrefix: (NSString *)prefix
{
    prefix = prefix.uppercaseString;
    AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];
    
    NSArray *sectionArray = [akAddressBook.hashTableSortedByFirst objectForKey: prefix];
    NSMutableSet *sectionSet = [NSMutableSet setWithArray: sectionArray];
    
    NSArray *inverseSortedSectionArray = [akAddressBook.hashTableSortedByLast objectForKey: prefix];
    NSMutableSet *inverseSortedSectionSet = [NSMutableSet setWithArray: inverseSortedSectionArray];
    
    [sectionSet unionSet: inverseSortedSectionSet];
    
    if (self.searchStack.count == 0) {
        [sectionSet intersectSet: self.displayedContactIDs];
    }
    else {
        NSSet *displayedContactIDs = [[NSSet alloc] initWithArray: [self.searchStack.lastObject matches]];
        [sectionSet intersectSet: displayedContactIDs];
    }
    return [sectionSet allObjects];
}

- (NSArray *)contactIDsHavingNumberPrefix: (NSString *)prefix
{
    prefix = prefix.uppercaseString;
    AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];
    
    NSArray *sectionArraySortedByFirst = [akAddressBook.hashTableSortedByFirst objectForKey: prefix];
    NSMutableSet *sectionSet = [NSMutableSet setWithArray: sectionArraySortedByFirst];
    
    NSArray *sectionArraySortedByLast = [akAddressBook.hashTableSortedByLast objectForKey: prefix];
    NSSet *sectionSetSortedByLast = [NSMutableSet setWithArray: sectionArraySortedByLast];
    
    [sectionSet unionSet: sectionSetSortedByLast];
    
    NSArray *sectionArraySortedByPhone = [akAddressBook.hashTableSortedByPhone objectForKey: prefix];
    NSSet *sectionSetSortedByPhone = [NSMutableSet setWithArray: sectionArraySortedByPhone];
    
    [sectionSet unionSet: sectionSetSortedByPhone];
    
    if (self.searchStack.count == 0) {
        [sectionSet intersectSet: self.displayedContactIDs];
    }
    else {
        NSSet *displayedContactIDs = [[NSSet alloc] initWithArray: [self.searchStack.lastObject matches]];
        [sectionSet intersectSet: displayedContactIDs];
    }
    return [sectionSet allObjects];
}

- (NSArray *)filterArray: (NSArray *)array withTerms:(NSArray *)terms andSortOrdering: (ABPersonSortOrdering)sortOrdering
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    CFErrorRef error = NULL;
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, &error);
    if (error) { NSLog(@"Address book reference error (%ld): %@", CFErrorGetCode(error), CFErrorCopyDescription(error)); error = NULL; }
#else
    ABAddressBookRef addressBookRef = ABAddressBookCreate();
#endif
    
    NSCountedSet *countedSet = [[NSCountedSet alloc] init];
    for (NSNumber *recordID in array)
    {
        if (self.shouldTerminate) {
            NSLog(@"Terminating filterArray:withTerms:andSortOrdering:");
            break;
        }
        AKContact *contact = [[AKAddressBook sharedInstance] contactForContactId: recordID.intValue withAddressBookRef: addressBookRef];
        
        NSInteger matchingTerms = [contact numberOfMatchingTerms: terms];
        if (self.manifoldingPropertyID != kABMultiValueInvalidIdentifier) {
            NSInteger propertyCount = [contact countForLinkedMultiValueProperty: self.manifoldingPropertyID];
            if (propertyCount == 0) { // Don't match contacts who doesn't have the properties of type manifoldingPropertyID
                matchingTerms = 0;
            }
        }
        
        NSArray *matchingPhoneIndexes = [contact indexesOfPhoneNumbersMatchingTerms: terms preciseMatch: NO];
        if (matchingPhoneIndexes.count > 0) {
            matchingTerms += 1;
        }
        
        if (matchingTerms == terms.count)
        {
            NSUInteger count = (self.manifoldingPropertyID == kABMultiValueInvalidIdentifier) ? 1 : matchingPhoneIndexes.count;
            if (count == 0)
            {
                count = [contact countForLinkedMultiValueProperty: self.manifoldingPropertyID];
            }
            count -= [countedSet countForObject: recordID];
            
            for (NSUInteger index = 0; index < count; ++index)
            {
                [countedSet addObject: recordID];
            }
        }
    }
    
    NSMutableArray *manifoldedArray = [[NSMutableArray alloc] init];
    for (NSNumber *recordID in [countedSet objectEnumerator])
    {
        for (NSUInteger index = 0; index < [countedSet countForObject: recordID]; ++index)
        {
            [manifoldedArray addObject: recordID];
        }
    }
    
    NSArray *sortedArray = [self sortedArray: manifoldedArray withAddressBookRef: addressBookRef];
    
    if (addressBookRef) {
        CFRelease(addressBookRef);
    }
    self.manifoldingPropertyID = kABMultiValueInvalidIdentifier;
    
    return sortedArray;
}

- (NSArray *)sortedArray: (NSArray *)array withAddressBookRef: (ABAddressBookRef)addressBookRef
{
    NSMutableArray *sortedArray = [[NSMutableArray alloc] init];
    for (NSNumber *recordID in array) {
        if (self.shouldTerminate) {
            NSLog(@"Terminating sortedArray:withAddressBookRef:");
            break;
        }
        NSInteger index = [AKAddressBook indexOfRecordID: recordID.intValue inArray: sortedArray withSortOrdering: [AKAddressBook sharedInstance].sortOrdering andAddressBookRef: addressBookRef];
        [sortedArray insertObject: recordID atIndex: index];
    }
    return [sortedArray copy];
}

- (void)finishSearch
{
    self.filteredContactIDs = nil;
    self.searchTerm = nil;
    [self.searchStack removeAllObjects];
}

- (NSMutableArray *)searchStack
{
    if (!_searchStack)
    {
        _searchStack = [[NSMutableArray alloc] init];
    }
    return _searchStack;
}

@end
