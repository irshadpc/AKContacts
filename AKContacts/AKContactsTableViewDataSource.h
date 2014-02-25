//
//  AKContactsTableViewDataSource.h
//  AKContacts
//
//  Created by Adam Kornafeld on 1/15/14.
//  Copyright (c) 2014 Adam Kornafeld. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AKContactsTableViewDataSource;

@protocol AKContactsTableViewDataSourceDelegate <NSObject>
- (void)dataSourceWillBeginSearch: (AKContactsTableViewDataSource *)dataSource;
- (void)dataSourceDidBeginSearch: (AKContactsTableViewDataSource *)dataSource;
- (void)dataSourceWillEndSearch: (AKContactsTableViewDataSource *)dataSource;
- (void)dataSourceDidEndSearch: (AKContactsTableViewDataSource *)dataSource;
@end

@interface AKContactsTableViewDataSource : NSObject

/**
 * Dictionary keys of displayed contacts
 **/
@property (strong, nonatomic) NSMutableArray *keys;
/**
 * Subset of allContactIdentifiers that are displayed
 **/
@property (strong, nonatomic) NSMutableDictionary *contactIdentifiers;

@property (assign, nonatomic) id<AKContactsTableViewDataSourceDelegate> delegate;

- (NSInteger)displayedContactsCount;

- (void)resetSearch;
- (void)handleSearchForTerm:(NSString *)searchTerm;

@end
