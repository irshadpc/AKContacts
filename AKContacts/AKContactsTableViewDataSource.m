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

@implementation AKContactsTableViewDataSource

- (NSInteger)displayedContactsCount
{
    NSInteger ret = 0;
    for (NSMutableArray *section in [self.contactIdentifiers allValues])
    {
        ret += [section count];
    }
    return ret;
}

- (void)resetSearch
{
    AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];
    
    if (akAddressBook.status != kAddressBookOnline) return;
    
    self.keys = [[NSMutableArray alloc] initWithObjects: UITableViewIndexSearch, nil];
    
    AKSource *source = [akAddressBook sourceForSourceId: akAddressBook.sourceID];
    AKGroup *group = [source groupForGroupId: akAddressBook.groupID];
    NSMutableSet *groupMembers = [group memberIDs];
    
    NSArray *keyArray = [akAddressBook.contactIDs.allKeys sortedArrayUsingSelector: @selector(compare:)];

    if ([groupMembers count] == akAddressBook.contactsCount)
    { // Shortcut for aggregate group if there's only a single source
        NSMutableDictionary *contactIdentifiers = [NSKeyedUnarchiver unarchiveObjectWithData: [NSKeyedArchiver archivedDataWithRootObject: akAddressBook.contactIDs]]; // Mutable deep copy
        self.contactIdentifiers = contactIdentifiers;
        [self.keys addObjectsFromArray: keyArray];
    }
    else
    {
        [self setContactIdentifiers: [[NSMutableDictionary alloc] initWithCapacity: [akAddressBook.contactIDs count]]];
        
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
            if ([sectionArray count] > 0)
            {
                [self.contactIdentifiers setObject: sectionArray forKey: key];
                [self.keys addObject: key];
            }
        }
    }
    
    if ([self.keys count] > 1 && [[self.keys objectAtIndex: 1] isEqualToString: @"#"])
    { // Little hack to move # to the end of the list
        [self.keys addObject: [self.keys objectAtIndex: 1]];
        [self.keys removeObjectAtIndex: 1];
    }
}

- (void)handleSearchForTerm: (NSString *)searchTerm
{
    static NSInteger previousTermLength = 1;
    
    AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];
    
    dispatch_block_t block = ^{
        
        dispatch_semaphore_wait(akAddressBook.ab_semaphore, DISPATCH_TIME_FOREVER);
        
        NSMutableArray *sectionsToRemove = [[NSMutableArray alloc ]init];
        
        if (previousTermLength >= [searchTerm length])
        {
            [self resetSearch];
        }
        previousTermLength = [searchTerm length];
        
        for (NSString *key in self.keys)
        {
            if ([key isEqualToString: UITableViewIndexSearch])
                continue;
            
            NSMutableArray *array = [self.contactIdentifiers valueForKey: key];
            NSMutableArray *toRemove = [[NSMutableArray alloc] init];
            for (NSNumber *identifier in array)
            {
                AKContact *contact = [akAddressBook contactForContactId: [identifier integerValue]];
                NSString *firstName = [contact valueForProperty: kABPersonFirstNameProperty];
                NSString *lastName = [contact valueForProperty: kABPersonLastNameProperty];
                
                BOOL firstNameMatches = (firstName && [firstName rangeOfString: searchTerm options: NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch|NSAnchoredSearch].location != NSNotFound);
                BOOL lastNameMatches = (lastName && [lastName rangeOfString: searchTerm options: NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch|NSAnchoredSearch].location != NSNotFound);
                
                if (firstNameMatches == NO && lastNameMatches == NO)
                    [toRemove addObject: identifier];
            }
            
            if ([array count] == [toRemove count])
                [sectionsToRemove addObject: key];
            [array removeObjectsInArray: toRemove];
        }
        [self.keys removeObjectsInArray: sectionsToRemove];
        
        dispatch_semaphore_signal(akAddressBook.ab_semaphore);
        
      if ([self.delegate respondsToSelector: @selector(dataSourceDidEndSearch:)]) {
        [self.delegate dataSourceDidEndSearch: self];
      }
    };
    
    dispatch_async(akAddressBook.ab_queue, block);
}

@end
