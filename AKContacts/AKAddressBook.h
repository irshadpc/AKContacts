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

FOUNDATION_EXPORT const void *const IsOnMainQueueKey;
FOUNDATION_EXPORT const void *const IsOnSerialBackgroundQueueKey;
FOUNDATION_EXPORT const BOOL ShowGroups;
FOUNDATION_EXPORT const ABRecordID kUnkownContactID;
FOUNDATION_EXPORT NSString *const noPhoneNumberKey;

@class AKAddressBook;
@class AKContact;
@class AKGroup;
@class AKSource;
@protocol HWContactProtocol;

#define kAddressBookLoadingMask (1 << 8)

typedef NS_ENUM(uint32_t, AddressBookStatus)
{
    kAddressBookOffline = 0x0,
    kAddressBookInitializing = 0x1,
    kAddressBookOnline = 0x2,
};

typedef struct AKSourceGroup {
    NSInteger source;
    NSInteger group;
} AKSourceGroup;

NS_INLINE AKSourceGroup AKMakeSourceGroup(NSUInteger source, NSUInteger group) {
    AKSourceGroup ret;
    ret.source = source;
    ret.group = group;
    return ret;
}

@protocol AKAddressBookPresentationDelegate <NSObject>

@optional
- (void)addressBookWillBeginLoading: (AKAddressBook *)addressBook;
- (void)addressBookDidEndLoading: (AKAddressBook *)addressBook;
@optional
- (void)addressBookWillBeginUpdates: (AKAddressBook *)addressBook;
- (void)addressBook: (AKAddressBook *)addressBook didInsertRecordID: (ABRecordID)recordID;
- (void)addressBook: (AKAddressBook *)addressBook didRemoveRecordID: (ABRecordID)recordID;
- (void)addressBookDidEndUpdates: (AKAddressBook *)addressBook;
- (void)addressBook:(AKAddressBook *)addressBook didMakeLoadProgress: (CGFloat)progress;

@end

@interface AKAddressBook : NSObject

@property (assign, nonatomic) id<AKAddressBookPresentationDelegate> presentationDelegate;

@property (assign, nonatomic) ABAddressBookRef addressBookRef;

@property (strong, nonatomic, readonly) dispatch_queue_t serial_queue;

@property (strong, nonatomic, readonly) dispatch_semaphore_t semaphore;

@property (assign, nonatomic) AddressBookStatus status;
@property (assign, nonatomic, getter = isLoading) BOOL loading;

@property (assign, readonly, nonatomic) BOOL canAccessNativeAddressBook;
@property (assign, readonly, nonatomic) ABAuthorizationStatus nativeAddressBookAuthorizationStatus;

@property (strong, nonatomic) NSProgress *loadProgress;
/**
 * AKSource objects in the order of display
 **/
@property (strong, nonatomic) NSMutableArray *sources;
/**
 * Arrays of Contact IDs with alphabetic lookup letters as keys
 **/
@property (strong, nonatomic) NSMutableDictionary *hashTableSortedByFirst;
@property (strong, nonatomic) NSMutableDictionary *hashTableSortedByLast;
/**
 * Arrays of Contact IDs with phone number first numbers as keys
 **/
@property (strong, nonatomic) NSMutableDictionary *hashTableSortedByPhone;
@property (strong, nonatomic) NSCache *phoneNumberCache;

@property (nonatomic, readonly) NSDictionary *hashTable;
@property (nonatomic, readonly) NSDictionary *hashTableSortedInverse;
@property (nonatomic, readonly) NSArray *allContactIDs;
@property (nonatomic, readonly) NSSet *contactIDsWithoutPhoneNumber;
/**
 * ID of displayed source and group
 **/
@property (assign, nonatomic) ABRecordID sourceID;
@property (assign, nonatomic) ABRecordID groupID;

@property (assign, nonatomic) BOOL needReload;

@property (assign, nonatomic) NSInteger contactsCount;
@property (assign, nonatomic) NSInteger nativeContactsCount;

@property (nonatomic) NSDate *dateAddressBookLoaded;

@property (assign, nonatomic, readonly) ABPersonSortOrdering sortOrdering;

+ (AKAddressBook *)sharedInstance;
+ (NSArray *)sectionKeys;
+ (NSArray *)countryCodePrefixes;
+ (NSString *)documentsDirectoryPath;
- (BOOL)hasStatus: (AddressBookStatus)status;
- (void)requestAddressBookAccessWithCompletionHandler:(void (^)(BOOL))completionHandler;
- (void)reloadAddressBook;
- (void)loadAddressBook;
- (AKSource *)defaultSource;
- (AKSource *)sourceForSourceId: (ABRecordID)recordId;
- (AKContact *)contactForContactId: (ABRecordID)recordId;
- (AKContact *)contactForContactId: (ABRecordID)recordId withAddressBookRef: (ABAddressBookRef)addressBookRef;
- (AKContact *)contactForPhoneNumber: (NSString *)phoneNumber;
- (AKContact *)contactForPhoneNumber: (NSString *)phoneNumber withAddressBookRef: (ABAddressBookRef)addressBookRef;
- (AKSource *)sourceForContactId: (ABRecordID)recordId;
- (void)deleteRecordID: (ABRecordID)recordID;

@end
