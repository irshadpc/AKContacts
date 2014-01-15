//
//  AKContactsTableViewDataSource.h
//  AKContacts
//
//  Created by Adam Kornafeld on 1/15/14.
//  Copyright (c) 2014 Adam Kornafeld. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AKContactsTableViewDataSource : NSObject

/**
 * Dictionary keys of displayed contacts
 **/
@property (strong, nonatomic) NSMutableArray *keys;
/**
 * Subset of allContactIdentifiers that are displayed
 **/
@property (strong, nonatomic) NSMutableDictionary *contactIdentifiers;

- (NSInteger)displayedContactsCount;

- (void)resetSearch;
- (void)handleSearchForTerm:(NSString *)searchTerm;

@end
