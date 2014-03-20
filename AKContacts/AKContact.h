//
//  AKContact.h
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
#import <AddressBook/AddressBook.h>

#import "AKRecord.h"

FOUNDATION_EXPORT const int newContactID;

@interface AKContact : AKRecord

- (instancetype)initWithABRecordID: (ABRecordID) recordID andAddressBookRef: (ABAddressBookRef)addressBookRef;
/**
 * Return displayName sans diacritics and whitespace
 **/
- (NSString *)searchName;
- (NSString *)sortName;
- (NSString *)compositeName;
- (NSString *)phoneticName;
- (NSString *)nameDelimiter;
- (NSString *)displayDetails;
- (NSArray *)linkedContactIDs;

- (NSData *)imageData;
- (void)setImageData: (NSData *)data;
- (UIImage *)image;

- (NSString *)addressForIdentifier: (ABMultiValueIdentifier)identifier andNumRows: (NSInteger *)numRows;
- (NSString *)instantMessageDescriptionForIdentifier: (ABMultiValueIdentifier)identifier;

- (NSComparisonResult)compareByName:(AKContact *)otherContact;

- (void)commit;
- (void)revert;

+ (NSString *)sectionKeyForName: (NSString *)name;
/**
 * Return the name of a record from which the section can be determined
 * This name does not include any prefix or suffix
 */
+ (NSString *)nameToDetermineSectionForRecordRef: (ABRecordRef)recordRef withSortOrdering: (ABPersonSortOrdering)sortOrdering;

@end
