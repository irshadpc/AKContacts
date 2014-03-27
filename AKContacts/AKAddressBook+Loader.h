//
//  AKAddressBook+Loader.h
//  AKContacts
//
//  Created by Adam Kornafeld on 1/28/14.
//  Copyright (c) 2014 Adam Kornafeld. All rights reserved.
//

#import "AKAddressBook.h"

@interface AKAddressBook (Loader)

-(void)loadSourcesWithABAddressBookRef: (ABAddressBookRef)addressBookRef;
-(void)loadGroupsWithABAddressBookRef: (ABAddressBookRef)addressBookRef;
-(void)loadContactsWithABAddressBookRef: (ABAddressBookRef)addressBookRef;

- (void)loadAddressBookWithCompletionHandler: (void (^)(BOOL))completionHandler;
/**
 * Insert recordID of contact into the sorted array of the section corresponding to the sectionKey of the record
 */
- (void)insertRecordIDinContactIdentifiersForContact: (AKContact *)contact;
/**
 * Remove a recordID of contact from the sorted array of the section corresponding to the sectionKey of the record
 */
- (void)deleteRecordIDfromContactIdentifiersForContact: (AKContact *)contact;

- (NSString *)fileNameForSelector: (SEL)selector;
- (BOOL)archiveDictionary: (NSDictionary *)dictionary withFileName: (NSString *)fileName;
- (NSMutableDictionary *)unarchiveDictionary: (SEL)selector;
- (BOOL)unarchiveCache;
- (BOOL)archiveCache;
- (BOOL)deleteArchiveForSelector: (SEL)selector;
- (BOOL)deleteArchive;
/**
 * The index where a record should appear in an alphabetically sorted array
 */
+ (NSUInteger)indexOfRecordID: (ABRecordID) recordID inArray: (NSArray *)array withSortOrdering: (ABPersonSortOrdering)sortOrdering andAddressBookRef: (ABAddressBookRef)addressBookRef;
/**
 * Removes a recordID from a dictionary storing recordIDs organized into sections
 */
+ (NSUInteger)removeRecordID: (ABRecordID)recordID withSectionKey: (NSString *)sectionKey fromContactIdentifierDictionary: (NSMutableDictionary *)contactIDs;

@end
