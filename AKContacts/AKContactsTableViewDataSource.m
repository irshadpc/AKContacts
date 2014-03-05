//
//  AKContactsTableViewDataSource.m
//  AKContacts
//
//  Created by Adam Kornafeld on 1/15/14.
//  Copyright (c) 2014 Adam Kornafeld. All rights reserved.
//

#import "AKContactsTableViewDataSource.h"
#import "AKAddressBook.h"
#import "AKContact.h"
#import "AKGroup.h"
#import "AKSource.h"

@interface AKContactsTableViewDataSource ()

- (void)handleSearchForTerm: (NSString *)term atIndex: (NSUInteger)index withCompletionHandler: (void (^)(void))completionHandler;

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
    AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];
    
    if (akAddressBook.status != kAddressBookOnline) return;
    
    self.keys = [[NSMutableArray alloc] initWithObjects: UITableViewIndexSearch, nil];
    
    AKSource *source = [akAddressBook sourceForSourceId: akAddressBook.sourceID];
    AKGroup *group = [source groupForGroupId: akAddressBook.groupID];
    NSMutableSet *groupMembers = [group memberIDs];
    
    NSArray *keyArray = [akAddressBook.contactIDs.allKeys sortedArrayUsingSelector: @selector(compare:)];

    if (groupMembers.count == akAddressBook.contactsCount)
    {   // Shortcut for aggregate group if there's only a single source
        self.contactIDs = [NSKeyedUnarchiver unarchiveObjectWithData: [NSKeyedArchiver archivedDataWithRootObject: akAddressBook.contactIDs]]; // Mutable deep copy
        [self.keys addObjectsFromArray: keyArray];
    }
    else
    {
        [self setContactIDs: [[NSMutableDictionary alloc] initWithCapacity: [akAddressBook.contactIDs count]]];

        for (NSString *key in keyArray)
        {
            NSArray *arrayForKey = [akAddressBook.contactIDs objectForKey: key];
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
    
    if (self.keys.count > 1 && [[self.keys objectAtIndex: 1] isEqualToString: @"#"])
    { // Little hack to move # to the end of the list
        [self.keys addObject: [self.keys objectAtIndex: 1]];
        [self.keys removeObjectAtIndex: 1];
    }
}

- (void)handleSearchForTerm: (NSString *)searchTerm
{
    if (searchTerm.length > self.searchStack.count)
    {
        [self.searchStack addObject: [searchTerm substringWithRange: NSMakeRange(searchTerm.length - 1, 1)]];

        [self handleSearchForTerm: searchTerm atIndex: (self.searchStack.count - 1) withCompletionHandler:^{
            if ([self.delegate respondsToSelector: @selector(dataSourceDidEndSearch:)]) {
                [self.delegate dataSourceDidEndSearch: self];
            }
        }];
    }
    else if (self.searchStack.count)
    {
        [self.searchStack removeLastObject];
        [self.searchCache removeLastObject];
        if (self.searchCache.count)
        {
            self.contactIDs = [[NSMutableDictionary alloc] initWithObjectsAndKeys: self.searchCache.lastObject, self.searchStack.firstObject, nil];
        }
        else
        {
            [self loadData];
        }
        if ([self.delegate respondsToSelector: @selector(dataSourceDidEndSearch:)]) {
            [self.delegate dataSourceDidEndSearch: self];
        }
    }
}

- (void)handleSearchForTerm: (NSString *)term atIndex: (NSUInteger)index withCompletionHandler: (void (^)(void))completionHandler
{
    if (!term.length) return;

    NSString *character = [term substringWithRange: NSMakeRange(index, 1)];
    NSLog(@"%d %@", index, character);

    AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];

    dispatch_block_t block = ^{

        dispatch_semaphore_wait(akAddressBook.ab_semaphore, DISPATCH_TIME_FOREVER);

        if (index == 0)
        {
            if ([[NSCharacterSet letterCharacterSet] characterIsMember: [character characterAtIndex: 0]])
            {
                NSArray *sectionArray = [[self.contactIDs objectForKey: character.uppercaseString] copy];
                NSMutableSet *sectionSet = [NSMutableSet setWithArray: sectionArray];

                NSArray *otherSectionArray = (akAddressBook.sortOrdering == kABPersonSortByFirstName) ? [akAddressBook.contactIDsSortedByLast objectForKey: character.uppercaseString] : [akAddressBook.contactIDsSortedByFirst objectForKey: character.uppercaseString];
                NSSet *otherSectionSet = [NSSet setWithArray: otherSectionArray];

                [sectionSet unionSet: otherSectionSet];
                [self.searchCache addObject: [sectionSet allObjects]];
            }
        }
        else
        {
            NSMutableArray *sectionArray = [[self.searchCache objectAtIndex: (index - 1)] mutableCopy];

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
            CFErrorRef error = NULL;
            ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, &error);
            if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }
#else
            ABAddressBookRef addressBook = ABAddressBookCreate();
#endif

            NSMutableSet *recordIDsToRemove = [[NSMutableSet alloc] init];
            for (NSNumber *recordID in sectionArray)
            {
                ABRecordRef recordRef = ABAddressBookGetPersonWithRecordID(addressBookRef, recordID.integerValue);
                if (recordRef)
                {
                    NSInteger kind = [(NSNumber *)CFBridgingRelease(ABRecordCopyValue(recordRef, kABPersonKindProperty)) integerValue];
                    if (kind == [(NSNumber *)kABPersonKindPerson integerValue])
                    {
                        NSString *name = CFBridgingRelease(ABRecordCopyValue(recordRef, kABPersonFirstNameProperty));
                        if ([name hasPrefix: @"Adam"])
                        {
                            NSLog(@"");
                        }
                        name = [name stringByFoldingWithOptions: NSDiacriticInsensitiveSearch locale: [NSLocale currentLocale]];
                        if ([name.lowercaseString hasPrefix: term.lowercaseString])
                        {
                            continue;
                        }
                        else
                        {
                            name = CFBridgingRelease(ABRecordCopyValue(recordRef, kABPersonLastNameProperty));
                            name = [name stringByFoldingWithOptions: NSDiacriticInsensitiveSearch locale: [NSLocale currentLocale]];
                            if ([name.lowercaseString hasPrefix: term.lowercaseString])
                            {
                                continue;
                            }
                            [recordIDsToRemove addObject: recordID];
                        }
                    }
                    else if (kind == [(NSNumber *)kABPersonKindOrganization integerValue])
                    {
                        NSString *name = CFBridgingRelease(ABRecordCopyValue(recordRef, kABPersonOrganizationProperty));
                        name = [name stringByFoldingWithOptions: NSDiacriticInsensitiveSearch locale: [NSLocale currentLocale]];
                        if (![name.lowercaseString hasPrefix: term.lowercaseString])
                        {
                            [recordIDsToRemove addObject: recordID];
                        }
                    }
                }
            }
            CFRelease(addressBookRef);

            for (NSNumber *recordID in recordIDsToRemove)
            {
                [sectionArray removeObject: recordID];
            }
            [self.searchCache addObject: sectionArray];
        }
        self.contactIDs = [[NSMutableDictionary alloc] initWithObjectsAndKeys: self.searchCache.lastObject, self.searchStack.firstObject, nil];

        dispatch_semaphore_signal(akAddressBook.ab_semaphore);

        if (completionHandler) {
            completionHandler();
        }
    };

    dispatch_async(akAddressBook.ab_queue, block);
}

- (void)finishSearch
{
    [self.searchStack removeAllObjects];
    [self.searchCache removeAllObjects];
}

- (NSMutableArray *)searchStack
{
    if (!_searchStack)
    {
        _searchStack = [[NSMutableArray alloc] init];
    }
    return _searchStack;
}

- (NSMutableArray *)searchCache
{
    if (!_searchCache)
    {
        _searchCache = [[NSMutableArray alloc] init];
    }
    return _searchCache;
}

@end
