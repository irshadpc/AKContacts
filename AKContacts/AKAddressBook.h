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
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

FOUNDATION_EXPORT const void *const IsOnMainQueueKey;
FOUNDATION_EXPORT const BOOL ShowGroups;

@class AKContact;
@class AKGroup;
@class AKSource;

typedef NS_ENUM(NSInteger, AddressBookStatus)
{
  kAddressBookOffline = 0,
  kAddressBookInitializing,
  kAddressBookLoading,
  kAddressBookOnline
};

@protocol AKAddressBookDelegate <NSObject>
- (void)setProgressTotal: (NSUInteger)progressTotal;
- (void)setProgressCurrent: (NSUInteger)progressCurrent;
@end

@interface AKAddressBook : NSObject

@property (assign, nonatomic) id<AKAddressBookDelegate> delegate;

@property (assign, nonatomic) ABAddressBookRef addressBookRef;

@property (strong, nonatomic, readonly) dispatch_queue_t ab_queue;

@property (strong, nonatomic, readonly) dispatch_semaphore_t ab_semaphore;

@property (assign, nonatomic) NSInteger status;
/**
 * AKContact objects with their recordIDs as keys
 **/
@property (strong, nonatomic) NSMutableDictionary *contacts;
/**
 * AKSource objects in the order of display
 **/
@property (strong, nonatomic) NSMutableArray *sources;
/**
 * Arrays of AKContact objects with their alphabetic lookup letters as keys
 **/
@property (strong, nonatomic) NSMutableDictionary *allContactIdentifiers;
/**
 * ID of displayed source and group
 **/
@property (assign, nonatomic) NSInteger sourceID;
@property (assign, nonatomic) NSInteger groupID;

@property (assign, nonatomic) BOOL needReload;

@property (assign, nonatomic) NSInteger contactsCount;

@property (assign, nonatomic) ABPersonSortOrdering sortOrdering;
@property (assign, nonatomic) ABPersonCompositeNameFormat compositeNameFormat;

+ (AKAddressBook *)sharedInstance;
- (void)requestAddressBookAccess;
- (void)insertRecordID: (ABRecordID)recordID inDictionary: (NSMutableDictionary *)dictionary forKey: (NSString *)key withAddressBookRef: (ABAddressBookRef)addressBook;
- (NSUInteger)indexOfRecordID: (ABRecordID) recordID inArray: (NSArray *)array withAddressBookRef: (ABAddressBookRef)addressBook;
- (AKSource *)defaultSource;
- (AKSource *)sourceForSourceId: (ABRecordID)recordId;
- (AKContact *)contactForContactId: (ABRecordID)recordId;
- (AKSource *)sourceForContactId: (ABRecordID)recordId;
- (void)removeRecordID: (ABRecordID)recordID;

@end
