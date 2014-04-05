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
FOUNDATION_EXPORT const BOOL ShowGroups;
FOUNDATION_EXPORT const NSInteger kUnkownContactID;

@class AKAddressBook;
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

- (void)addressBookWillBeginUpdates: (AKAddressBook *)addressBook;
- (void)addressBook: (AKAddressBook *)addressBook didInsertRecordID: (ABRecordID)recordID;
- (void)addressBook: (AKAddressBook *)addressBook didRemoveRecordID: (ABRecordID)recordID;
- (void)addressBookDidEndUpdates: (AKAddressBook *)addressBook;

@end

@interface AKAddressBook : NSObject

@property (assign, nonatomic) id<AKAddressBookPresentationDelegate> presentationDelegate;

@property (assign, nonatomic) ABAddressBookRef addressBookRef;

@property (strong, nonatomic, readonly) dispatch_queue_t serial_queue;

@property (strong, nonatomic, readonly) dispatch_semaphore_t semaphore;

@property (assign, nonatomic) AddressBookStatus status;

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
/**
 * ID of displayed source and group
 **/
@property (assign, nonatomic) ABRecordID sourceID;
@property (assign, nonatomic) ABRecordID groupID;

@property (assign, nonatomic) BOOL needReload;

@property (assign, nonatomic, readonly) NSInteger contactsCount;

@property (nonatomic) NSDate *dateAddressBookLoaded;

@property (assign, nonatomic, readonly) ABPersonSortOrdering sortOrdering;

@property (assign, nonatomic, readonly) ABAuthorizationStatus authorizationStatus;

+ (AKAddressBook *)sharedInstance;
+ (NSArray *)sectionKeys;
+ (NSArray *)prefixesToDiscardOnSearch;

- (void)requestAddressBookAccessWithCompletionHandler:(void (^)(BOOL))completionHandler;
- (void)reloadAddressBook;
- (void)loadAddressBook;
- (void)deleteRecordID: (ABRecordID)recordID;

- (AKSource *)defaultSource;
- (AKSource *)sourceForSourceId: (ABRecordID)recordId;
- (AKContact *)contactForContactId: (ABRecordID)recordId;
- (AKContact *)contactForContactId: (ABRecordID)recordId withAddressBookRef: (ABAddressBookRef)addressBookRef;
- (AKContact *)contactForPhoneNumber: (NSString *)phoneNumber;
- (AKSource *)sourceForContactId: (ABRecordID)recordId;

@end
