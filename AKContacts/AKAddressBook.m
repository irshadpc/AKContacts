//
//  AKAddressBook.m
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
#import "AKContact.h"
#import "AKGroup.h"
#import "AKSource.h"
#import "AKAddressBook+Loader.h"

NSString *const AKAddressBookQueueName = @"AKAddressBookQueue";

const BOOL ShowGroups = YES;

/**
 * This key is set for the main_queue to tell if we are on the main queue
 * From the docs:  
 * Keys are only compared as pointers and are never dereferenced.
 * Thus, you can use a pointer to a static variable for a specific 
 * subsystem or any other value that allows you to identify the value uniquely.
 **/
const void *const IsOnMainQueueKey = &IsOnMainQueueKey;

@interface AKAddressBook ()

@property (strong, nonatomic) NSDate *dateAddressBookLoaded;

@property (assign, nonatomic) ABPersonSortOrdering sortOrdering;

@property (assign, nonatomic) NSInteger contactsCount;

-(void)reloadAddressBook;

@end

@implementation AKAddressBook

#pragma mark - Address Book Changed Callback

void addressBookChanged(ABAddressBookRef reference, CFDictionaryRef dictionary, void *context) 
{
  @autoreleasepool 
  {
    AKAddressBook *addressBook = (__bridge AKAddressBook *)context;
    [addressBook reloadAddressBook];
  }
}

+ (AKAddressBook *)sharedInstance 
{
  static dispatch_once_t once;
  static AKAddressBook *akAddressBook;
  dispatch_once(&once, ^{ akAddressBook = [[self alloc] init]; });
  return akAddressBook;
}

+ (NSArray *)prefixesToDiscardOnSearch
{
    return @[@"1"];
}

+ (NSArray *)sectionKeys;
{
    return @[@"A",@"B",@"C",@"D",@"E",@"F",@"F",@"G",@"H",
             @"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",
             @"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z",@"#"];
}

- (id)init
{
  self = [super init];
  if (self)
  {
    _ab_queue = dispatch_queue_create([AKAddressBookQueueName UTF8String], NULL);

    _ab_semaphore = dispatch_semaphore_create(1);

    _needReload = YES;

    _loadProgress = [[NSProgress alloc] initWithParent: nil userInfo: nil];

    _status = kAddressBookOffline;

    _sourceID = kSourceAggregate;
    _groupID = kGroupAggregate;

    /*
     * The ABAddressBook API is not thread safe. ABAddressBook related calls are dispatched on the main queue.
     * The only exception to this is the initial loading of the contacts data that is executed in
     * the background so the UI remains responsive. See loadAddressBook that uses a local addressBook reference.
     *
     * dispatch_queue_set_specific is used to set a unique key for the main queue that can be used to 
     * determine if the current queue is the main one
     */
    dispatch_queue_set_specific(dispatch_get_main_queue(), IsOnMainQueueKey, (__bridge void *)self, NULL);

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    CFErrorRef error = NULL;
    _addressBookRef = ABAddressBookCreateWithOptions(NULL, &error);
    if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }
#else
    _addressBookRef = ABAddressBookCreate();
#endif

    _sortOrdering = ABPersonGetSortOrdering();

    ABAddressBookRegisterExternalChangeCallback(_addressBookRef, addressBookChanged, (__bridge void*) self);
  }
  return self;
}

- (void)dealloc 
{
  CFRelease(_addressBookRef);
  [[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark - Address Book

- (void)requestAddressBookAccess 
{
  NSAssert(dispatch_get_specific(IsOnMainQueueKey), @"Must be dispatched on main queue");

  if (&ABAddressBookGetAuthorizationStatus)
  {
    ABAuthorizationStatus authStatus = ABAddressBookGetAuthorizationStatus();

    if (authStatus == kABAuthorizationStatusNotDetermined)
    {
      void (^block)(bool granted, CFErrorRef error) = ^(bool granted, CFErrorRef error){
        if (granted)
        {
          NSLog(@"Access granted to addressBook");
          dispatch_async(dispatch_get_main_queue(), ^{
            [self loadAddressBook];
          });
        }
        else
        {
          NSLog(@"Access denied to addressBook");
        }
      };
      ABAddressBookRequestAccessWithCompletion(self.addressBookRef, block);
    }
    else if (authStatus == kABAuthorizationStatusDenied)
    {
      NSLog(@"kABAuthorizationStatusDenied");
    }
    else if (authStatus == kABAuthorizationStatusRestricted)
    {
      NSLog(@"kABAuthorizationStatusRestricted");
    }
    else if (authStatus == kABAuthorizationStatusAuthorized)
    {
      [self loadAddressBook];
    }
  }
  else
  {
      [self loadAddressBook];
  }
}

- (void)reloadAddressBook 
{
  NSLog(@"AKAddressBook reloadAddressBook");

  if (self.dateAddressBookLoaded)
  {
    NSTimeInterval elapsed = fabs([self.dateAddressBookLoaded timeIntervalSinceNow]);
    NSLog(@"Elasped since last AB load: %f", elapsed);
    if (elapsed < 5.0)
    {
      return;
    }
    else
    {
      [self setNeedReload: YES];
    }
  }

  if (self.status != kAddressBookLoading && self.needReload)
  {
    [self loadAddressBook];
  }
}

- (void)loadAddressBook 
{
  NSAssert(dispatch_get_specific(IsOnMainQueueKey), @"Must be dispatched on main queue");

  switch (self.status) 
  {
    case kAddressBookOffline:
      self.status = kAddressBookInitializing;
      break;
    case kAddressBookOnline:
      // self.addressBookRef needs a revert to recognize external changes
      ABAddressBookRevert(self.addressBookRef);
      self.status = kAddressBookLoading;
      break;
  }

  NSDate *start = [NSDate date];

  self.contactsCount = ABAddressBookGetPersonCount(self.addressBookRef);

  [self loadAddressBookWithCompletionHandler:^(BOOL success) {
    if (success) {
      dispatch_async(dispatch_get_main_queue(), ^{
        self.dateAddressBookLoaded = [NSDate date];
        NSLog(@"Address book loaded in %.2f", fabs([self.dateAddressBookLoaded timeIntervalSinceDate: start]));

        self.status = kAddressBookOnline;
      });
    }
  }];
}

- (NSDictionary *)contactIDs
{
    return (self.sortOrdering == kABPersonSortByFirstName) ? self.contactIDsSortedByFirst : self.contactIDsSortedByLast;
}

- (NSDictionary *)inverseSortedContactIDs
{
    return (self.sortOrdering != kABPersonSortByFirstName) ? self.contactIDsSortedByFirst : self.contactIDsSortedByLast;
}

- (AKSource *)defaultSource
{
  AKSource *ret = nil;

  for (AKSource *source in self.sources)
  {
    if ([source isDefault] == YES) 
    {
      ret = source;
      break;
    }
  }

  NSAssert(ret != nil, @"No default source present");

  return ret;
}

- (AKSource *)sourceForSourceId: (ABRecordID)recordId
{  
  AKSource *ret = nil;
  
  for (AKSource *source in self.sources)
  {
    if (source.recordID == recordId) 
    {
      ret = source;
      break;
    }
  }
  return ret;
}

- (AKContact *)contactForContactId: (ABRecordID)recordId
{
  return [[AKContact alloc] initWithABRecordID: recordId andAddressBookRef: self.addressBookRef];
}

- (AKContact *)contactForContactId: (ABRecordID)recordId withAddressBookRef: (ABAddressBookRef)addressBookRef
{
  return [[AKContact alloc] initWithABRecordID: recordId andAddressBookRef: addressBookRef];
}

- (AKSource *)sourceForContactId: (ABRecordID)recordId
{
  AKSource *ret = nil;
  NSNumber *contactId = [NSNumber numberWithInteger: recordId];
  for (AKSource *source in self.sources)
  {
    if (source.recordID == kSourceAggregate) continue;

    AKGroup *group = [source groupForGroupId: kGroupAggregate];
    if ([group.memberIDs member: contactId])
    {
      ret = source;
      break;
    }
  }
  return ret;
}

- (void)deleteRecordID: (ABRecordID)recordID
{
  AKContact *contact = [self contactForContactId: recordID];

  for (NSString *key in self.contactIDsSortedByFirst)
  {
    NSMutableArray *sectionArray = [self.contactIDsSortedByFirst objectForKey: key];
    [sectionArray removeObject: @(recordID)];
  }
  for (NSString *key in self.contactIDsSortedByLast)
  {
    NSMutableArray *sectionArray = [self.contactIDsSortedByLast objectForKey: key];
    [sectionArray removeObject: @(recordID)];
  }

  [self setNeedReload: NO];

  CFErrorRef error = NULL;
  ABAddressBookRemoveRecord(self.addressBookRef, contact.recordRef, &error);
  if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }

  ABAddressBookSave(self.addressBookRef, &error);
  if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }
}

@end
