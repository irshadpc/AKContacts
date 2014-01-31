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
/**
 * Insert a recordID to the sorted array of the section corresponding to the sectionKey of the record
 */
- (void)contactIdentifiersInsertRecordID: (ABRecordID)recordID withAddressBookRef: (ABAddressBookRef)addressBook;
/**
 * Remove a recordID from the sorted array of the section corresponding to the sectionKey of the record
 */
- (void)contactIdentifiersDeleteRecordID: (ABRecordID)recordID withAddressBookRef: (ABAddressBookRef)addressBook;
/**
 * The index where a record should appear in an alphabetically sorted array
 */
+ (NSUInteger)indexOfRecordID: (ABRecordID) recordID inArray: (NSArray *)array withSortOrdering: (ABPersonSortOrdering)sortOrdering andAddressBookRef: (ABAddressBookRef)addressBook;
/**
 * Return the name of a record from which the section can be determined
 * This name does not include any prefix or suffix
 */
+ (NSString *)nameToDetermineSectionForRecordRef: (ABRecordRef)recordRef withSortOrdering: (ABPersonSortOrdering)sortOrdering;

@end