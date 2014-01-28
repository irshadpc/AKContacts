//
//  AKAddressBook+Loader.h
//  AKContacts
//
//  Created by Adam Kornafeld on 1/28/14.
//  Copyright (c) 2014 Adam Kornafeld. All rights reserved.
//

#import "AKAddressBook.h"

@interface AKAddressBook (Loader)

-(void)loadSourcesWithABAddressBookRef: (ABAddressBookRef)addressBook;
-(void)loadGroupsWithABAddressBookRef: (ABAddressBookRef)addressBook;
-(void)loadContactsWithABAddressBookRef: (ABAddressBookRef)addressBook;

- (void)loadAddressBookWithCompletionHandler: (void (^)(BOOL))completionHandler;

+ (NSUInteger)indexOfRecordID: (ABRecordID) recordID inArray: (NSArray *)array withSortOrdering: (ABPersonSortOrdering)sortOrdering andAddressBookRef: (ABAddressBookRef)addressBook;
+ (NSString *)nameToDetermineSectionForRecordRef: (ABRecordRef)recordRef withSortOrdering: (ABPersonSortOrdering)sortOrdering;

@end
