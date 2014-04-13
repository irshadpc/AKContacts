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

#import <Foundation/Foundation.h>

@class AKContactsTableViewDataSource;
@class AKContact;

@protocol AKContactsTableViewDataSourceDelegate <NSObject>
@optional
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
 * Subset of all contactIDs that are displayed
 **/
@property (strong, nonatomic) NSMutableDictionary *contactIDs;
/**
 * Set of contactIDs that are displayed
 */
@property (strong, nonatomic) NSSet *displayedContactIDs;
@property (assign, nonatomic, readonly) NSInteger displayedContactsCount;
/**
 * Search results
 */
@property (strong, nonatomic) NSArray *filteredContactIDs;

@property (strong, readonly) NSString *searchTerm;

@property (assign, nonatomic) id<AKContactsTableViewDataSourceDelegate> delegate;
/**
 * Set this to a multiValueProperty identifier (eg: kABPersonPhoneProperty)
 * and the search results array will include each contact ID as many times
 * as the count of that multiValueProperty the contact has
 * In plain english: if 2 phone numbers belong to the contact who has the
 * contactID 123 then 123 will apear twice in the search results
 * Default value is kABMultiValueInvalidIdentifier
 */
@property (assign, nonatomic) ABPropertyID manifoldingPropertyID;

- (AKContact *)contactForIndexPath: (NSIndexPath *)indexPath;

- (void)loadData;
- (void)handleSearchForTerm: (NSString *)searchTerm;
- (void)finishSearch;

@end
