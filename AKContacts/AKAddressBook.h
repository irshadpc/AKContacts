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

@property (strong, nonatomic, readonly) dispatch_queue_t ab_queue;

@property (strong, nonatomic, readonly) dispatch_semaphore_t ab_semaphore;

@property (assign, nonatomic) NSInteger status;

@property (strong, nonatomic) NSProgress *loadProgress;
/**
 * AKContact objects with their recordIDs as keys
 **/
@property (strong, nonatomic) NSMutableDictionary *contacts;
/**
 * AKSource objects in the order of display
 **/
@property (strong, nonatomic) NSMutableArray *sources;
/**
 * Arrays of Contact IDs with alphabetic lookup letters as keys
 **/
@property (strong, nonatomic) NSMutableDictionary *contactIDsSortedByFirst;
@property (strong, nonatomic) NSMutableDictionary *contactIDsSortedByLast;
/**
 * Arrays of Contact IDs with phone number first numbers as keys
 **/
@property (strong, nonatomic) NSMutableDictionary *contactIDsSortedByPhone;
/**
 * ID of displayed source and group
 **/
@property (assign, nonatomic) ABRecordID sourceID;
@property (assign, nonatomic) ABRecordID groupID;

@property (assign, nonatomic) BOOL needReload;

@property (assign, nonatomic, readonly) NSInteger contactsCount;

@property (strong, nonatomic, readonly) NSDate *dateAddressBookLoaded;

@property (assign, nonatomic, readonly) ABPersonSortOrdering sortOrdering;

+ (AKAddressBook *)sharedInstance;
+ (NSArray *)sectionKeys;
- (void)requestAddressBookAccess;
- (NSDictionary *)contactIDs;
- (NSDictionary *)inverseSortedContactIDs;
- (AKSource *)defaultSource;
- (AKSource *)sourceForSourceId: (ABRecordID)recordId;
- (AKContact *)contactForContactId: (ABRecordID)recordId;
- (AKSource *)sourceForContactId: (ABRecordID)recordId;
- (void)deleteRecordID: (ABRecordID)recordID;

@end
