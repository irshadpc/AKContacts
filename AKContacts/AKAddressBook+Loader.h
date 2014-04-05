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


#import "AKAddressBook.h"

@interface AKAddressBook (Loader)

- (void)loadSourcesWithABAddressBookRef: (ABAddressBookRef)addressBookRef;
- (void)loadGroupsWithABAddressBookRef: (ABAddressBookRef)addressBookRef;
- (void)loadContactsWithABAddressBookRef: (ABAddressBookRef)addressBookRef;

- (void)processPhoneNumbersOfContact: (AKContact *)contact withABAddressBookRef: (ABAddressBookRef)addressBookRef;

- (void)loadAddressBookWithCompletionHandler: (void (^)(BOOL))completionHandler;
/**
 * Insert recordID of contact into the sorted array of the section corresponding to the sectionKey of the record
 */
- (void)insertRecordIDinContactIdentifiersForContact: (AKContact *)contact withAddressBookRef: (ABAddressBookRef)addressBookRef;
/**
 * Remove a recordID of contact from the sorted array of the section corresponding to the sectionKey of the record
 */
- (void)deleteRecordIDfromContactIdentifiersForContact: (AKContact *)contact;

- (BOOL)archiveDictionary: (NSDictionary *)dictionary withFileName: (NSString *)fileName;
- (NSMutableDictionary *)unarchiveDictionaryWithFileName: (NSString *)fileName;
- (BOOL)unarchiveCache;
- (BOOL)archiveCache;
- (BOOL)deleteArchiveWithFileName: (NSString *)fileName;
- (BOOL)deleteArchive;
/**
 * The index where a record should appear in an alphabetically sorted array
 */
+ (NSUInteger)indexOfRecordID: (ABRecordID)recordID inArray: (NSArray *)array withSortOrdering: (ABPersonSortOrdering)sortOrdering andAddressBookRef: (ABAddressBookRef)addressBookRef;
/**
 * Removes a recordID from a dictionary storing recordIDs organized into sections
 */
+ (NSUInteger)removeRecordID: (ABRecordID)recordID withSectionKey: (NSString *)sectionKey fromContactIdentifierDictionary: (NSMutableDictionary *)contactIDs;
/**
 * Returns a filename for a given selector
 */
+ (NSString *)fileNameForSelector: (SEL)selector;

+ (NSComparator)recordIDBasedComparatorWithSortOrdering: (ABPersonSortOrdering)sortOrdering andAddressBookRef: (ABAddressBookRef)addressBookRef;

+ (NSString *)documentsDirectoryPath;

@end
