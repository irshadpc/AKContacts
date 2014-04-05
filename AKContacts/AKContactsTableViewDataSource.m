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

#import "AKContactsTableViewDataSource.h"
#import "AKAddressBook.h"
#import "AKContact.h"
#import "AKGroup.h"
#import "AKSource.h"

@interface AKSearchStackElement : NSObject

@property (nonatomic, copy) NSString *character;
@property (nonatomic, strong) NSMutableArray *matches;

@end

@implementation AKSearchStackElement

@end

@interface AKContactsTableViewDataSource ()

/**
 * index is the character index of the last term
 */
- (AKSearchStackElement *)searchStackElementForTerms: (NSArray *)terms andCharacterIndex: (NSUInteger)index;
- (NSMutableArray *)contactIDsHavingPrefix: (NSString *)prefix;
- (NSArray *)contactIDsHavingNamePrefix: (NSString *)prefix;
- (NSArray *)contactIDsHavingNumberPrefix: (NSString *)prefix;
+ (NSArray *)array: (NSArray *)array filteredWithTerms:(NSArray *)terms andSortOrdering: (ABPersonSortOrdering)sortOrdering;

@end

@implementation AKContactsTableViewDataSource

- (NSInteger)displayedContactsCount
{
    NSInteger ret = 0;
    for (NSMutableArray *section in [self.contactIDs allValues])
    {
        ret += [section count];
    }
    return ret;
}

- (void)loadData
{
    void(^block)(void) = ^{
        
        AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];
        
        self.keys = [[NSMutableArray alloc] initWithObjects: UITableViewIndexSearch, nil];
        
        AKSource *source = [akAddressBook sourceForSourceId: akAddressBook.sourceID];
        AKGroup *group = [source groupForGroupId: akAddressBook.groupID];
        NSMutableSet *groupMembers = [group memberIDs];
        
        NSArray *sectionKeys = [AKAddressBook sectionKeys];
        
        if (groupMembers.count == akAddressBook.contactsCount)
        {   // Shortcut for aggregate group if there's only a single source
            self.contactIDs = [akAddressBook.hashTable mutableCopy];
            [self.keys addObjectsFromArray: sectionKeys];
        }
        else
        {
            [self setContactIDs: [[NSMutableDictionary alloc] initWithCapacity: [akAddressBook.hashTable count]]];
            
            for (NSString *key in sectionKeys)
            {
                NSArray *arrayForKey = [akAddressBook.hashTable objectForKey: key];
                NSMutableArray *sectionArray = [arrayForKey mutableCopy];
                
                NSMutableArray *recordsToRemove = [[NSMutableArray alloc] init];
                for (NSNumber *contactID in sectionArray)
                {
                    if (groupMembers != nil && ![groupMembers member: contactID]) {
                        [recordsToRemove addObject: contactID];
                    }
                }
                [sectionArray removeObjectsInArray: recordsToRemove];
                if (sectionArray.count > 0)
                {
                    [self.contactIDs setObject: sectionArray forKey: key];
                    [self.keys addObject: key];
                }
            }
        }
    };
    if (dispatch_get_specific(IsOnMainQueueKey)) block();
    else dispatch_async(dispatch_get_main_queue(), block);
}

- (void)handleSearchForTerm: (NSString *)searchTerm
{
    // Don't trim trailing whitespace needed for tokenization
    searchTerm = [searchTerm stringByTrimmingLeadingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
    
    dispatch_block_t block = ^{
        
        dispatch_semaphore_wait([AKAddressBook sharedInstance].semaphore, DISPATCH_TIME_FOREVER);
        
        if (searchTerm.length > self.searchStack.count)
        {
            NSString *character = [searchTerm substringWithRange: NSMakeRange(searchTerm.length - 1, 1)];
            
            NSInteger(^nextCharacterIndex)(void) = ^{
                NSInteger index = 0;
                for (AKSearchStackElement *elem in [self.searchStack reverseObjectEnumerator]) {
                    if ([elem.character isMemberOfCharacterSet: [NSCharacterSet whitespaceCharacterSet]]) {
                        break;
                    }
                    index += 1;
                }
                return index;
            };
            
            NSInteger(^whiteSpaceCountOnStack)(void) = ^{
                NSInteger count = 0;
                for (AKSearchStackElement *elem in self.searchStack)
                {
                    if ([elem.character isMemberOfCharacterSet: [NSCharacterSet whitespaceCharacterSet]])
                    {
                        count += 1;
                    }
                }
                return count;
            };
            
            NSInteger whiteSpacesOnStack = whiteSpaceCountOnStack();
            
            NSArray *terms = [searchTerm componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
            for (NSInteger index = whiteSpacesOnStack; index < terms.count; ++index)
            {
                NSString *term = [terms objectAtIndex: index];
                if (!term.length) continue;
                
                if (![character isMemberOfCharacterSet: [NSCharacterSet whitespaceCharacterSet]])
                {
                    NSInteger characterIndex = nextCharacterIndex();
                    
                    AKSearchStackElement *element = [self searchStackElementForTerms: terms andCharacterIndex: characterIndex];
                    [self.searchStack addObject: element];
                }
                else if (self.searchStack.count)
                { // Ignore whitespace
                    AKSearchStackElement *previousStackElement = [self.searchStack lastObject];
                    
                    AKSearchStackElement *element = [[AKSearchStackElement alloc] init];
                    element.character = character;
                    element.matches = [previousStackElement.matches mutableCopy];
                    [self.searchStack addObject: element];
                }
            }
        }
        else if (self.searchStack.count)
        {
            [self.searchStack removeLastObject];
        }
        
        if (self.searchStack.count)
        {
            self.contactIDs = [[NSMutableDictionary alloc] initWithObjectsAndKeys: [self.searchStack.lastObject matches], [self.searchStack.firstObject character], nil];
        }
        else
        {
            [self loadData];
        }
        
        dispatch_semaphore_signal([AKAddressBook sharedInstance].semaphore);
        
        if ([self.delegate respondsToSelector: @selector(dataSourceDidEndSearch:)]) {
            [self.delegate dataSourceDidEndSearch: self];
        }
    };
    
    dispatch_async([AKAddressBook sharedInstance].serial_queue, block);
}

- (AKSearchStackElement *)searchStackElementForTerms: (NSArray *)terms andCharacterIndex: (NSUInteger)index
{
    NSString *term = [terms lastObject];
    NSString *character = [term substringWithRange: NSMakeRange(index, 1)];
    AKSearchStackElement *element = [[AKSearchStackElement alloc] init];
    element.character = character;
    
    if (terms.count == 1 && !index)
    {
        element.character = (![character isMemberOfCharacterSet: [NSCharacterSet decimalDigitCharacterSet]]) ? character : @"#";
        element.matches = [self contactIDsHavingPrefix: character];
    }
    else
    {
        NSArray *matchingIDs;
        if (!index)
        {
            matchingIDs = [self.searchStack.lastObject matches];
            NSMutableSet *matchingSet = [[NSMutableSet alloc] initWithArray: matchingIDs];
            
            NSMutableArray *matchingCandidates = [self contactIDsHavingPrefix: character];
            NSSet *candidateSet = [[NSSet alloc] initWithArray: matchingCandidates];
            [matchingSet intersectSet: candidateSet];
            
            matchingIDs = [matchingSet allObjects];
        }
        else
        {
            matchingIDs = [self.searchStack.lastObject matches];
        }
        matchingIDs = [AKContactsTableViewDataSource array: matchingIDs filteredWithTerms: terms andSortOrdering: [AKAddressBook sharedInstance].sortOrdering];
        element.matches = [matchingIDs mutableCopy];
    }
    return element;
}

- (NSMutableArray *)contactIDsHavingPrefix: (NSString *)prefix
{
    if ([prefix isMemberOfCharacterSet: [NSCharacterSet letterCharacterSet]])
    {
        return [[self contactIDsHavingNamePrefix: prefix] mutableCopy];
    }
    else
    {
        return [[self contactIDsHavingNumberPrefix: prefix] mutableCopy];
    }
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
    
    NSMutableSet *displayedContactIDs = [[NSMutableSet alloc] init];
    for (NSArray *section in self.contactIDs.allValues)
    {
        [displayedContactIDs addObjectsFromArray: section];
    }
    [sectionSet intersectSet: displayedContactIDs];
    
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
    
    NSMutableSet *displayedContactIDs = [[NSMutableSet alloc] init];
    for (NSArray *section in self.contactIDs.allValues)
    {
        [displayedContactIDs addObjectsFromArray: section];
    }
    [sectionSet intersectSet: displayedContactIDs];
    
    return [sectionSet allObjects];
}

+ (NSArray *)array: (NSArray *)array filteredWithTerms:(NSArray *)terms andSortOrdering: (ABPersonSortOrdering)sortOrdering;
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    CFErrorRef error = NULL;
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, &error);
    if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }
#else
    ABAddressBookRef addressBookRef = ABAddressBookCreate();
#endif
    
    NSMutableSet *filteredSet = [[NSMutableSet alloc] init];
    for (NSNumber *recordID in array)
    {
        AKContact *contact = [[AKContact alloc] initWithABRecordID: recordID.intValue sortOrdering: sortOrdering andAddressBookRef: addressBookRef];
        
        NSInteger termsMatched = [contact numberOfMatchingTerms: terms];
        
        termsMatched += [contact numberOfPhoneNumbersMatchingTerms: terms preciseMatch: NO];
        if (termsMatched == terms.count)
        {
            [filteredSet addObject: recordID];
        }
    }
    CFRelease(addressBookRef);
    
    return filteredSet.allObjects;
}

- (void)finishSearch
{
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
