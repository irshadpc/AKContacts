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

NSString *const AKAddressBookQueueName = @"AKAddressBookQueue";

NSString *const AddressBookDidInitializeNotification = @"AddressBookDidInitializeNotification";
NSString *const AddressBookDidLoadNotification = @"AddressBookDidLoadNotification";

const BOOL ShowGroups = YES;

static const NSTimeInterval UnusedContactsReleaseTime = 600;

/**
 * This key is set for the main_queue to tell if we are on the main queue
 * From the docs:  
 * Keys are only compared as pointers and are never dereferenced.
 * Thus, you can use a pointer to a static variable for a specific 
 * subsystem or any other value that allows you to identify the value uniquely.
 **/
const void *const IsOnMainQueueKey = &IsOnMainQueueKey;

@interface AKAddressBook ()

@property (strong, nonatomic) dispatch_source_t ab_timer;
@property (assign, nonatomic) BOOL ab_timer_suspended;

/**
 * ABAddressBookRegisterExternalChangeCallback tends to fire multiple times
 * for a single change, so we store the last date when the addressbook
 * is reloaded and skip callbacks that fire too close to this date
 */
@property (strong, nonatomic) NSDate *dateAddressBookLoaded;

-(void)reloadAddressBook;
-(void)loadSourcesWithABAddressBookRef: (ABAddressBookRef)addressBook;
-(void)loadGroupsWithABAddressBookRef: (ABAddressBookRef)addressBook;
-(void)loadContactsWithABAddressBookRef: (ABAddressBookRef)addressBook;

/**
 * AKContacts are released from the contacts dictionary
 * after being unused for at least UnusedContactsReleaseTime seconds
 */
-(void)releaseUnusedContacts;
-(void)resume_ab_timer;
-(void)suspend_ab_timer;

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

- (id)init 
{
  self = [super init];
  if (self) 
  {
    _ab_queue = dispatch_queue_create([AKAddressBookQueueName UTF8String], NULL);

    _ab_semaphore = dispatch_semaphore_create(1);

    _ab_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _ab_queue);

    _ab_timer_suspended = YES;

    _needReload = YES;

    dispatch_source_set_event_handler(_ab_timer, ^{
      [self releaseUnusedContacts];
      [self suspend_ab_timer];
      [self resume_ab_timer];
    });

    _status = kAddressBookOffline;

    _sourceID = kSourceAggregate;
    _groupID = kGroupAggregate;

    _contacts = [[NSMutableDictionary alloc] init];

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
    if (error) NSLog(@"%ld", CFErrorGetCode(error));
#else
    _addressBookRef = ABAddressBookCreate();
#endif

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
    ABAuthorizationStatus stat = ABAddressBookGetAuthorizationStatus();

    if (stat == kABAuthorizationStatusNotDetermined)
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
    else if (stat == kABAuthorizationStatusDenied)
    {
      NSLog(@"kABAuthorizationStatusDenied");
    }
    else if (stat == kABAuthorizationStatusRestricted)
    {
      NSLog(@"kABAuthorizationStatusRestricted");
    }
    else if (stat == kABAuthorizationStatusAuthorized) 
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

  if (self.status != kAddressBookLoading && self.needReload == YES)
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
      [self setStatus: kAddressBookInitializing];
      break;
    case kAddressBookOnline:
      // self.addressBookRef needs a revert to recognize external changes
      ABAddressBookRevert(self.addressBookRef);
      [self setStatus: kAddressBookLoading];
      break;
  }

  /*
   * Loading the addressbook runs in the background and uses a local ABAddressBookRef
   */
  dispatch_block_t block = ^{

    [self suspend_ab_timer];
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    CFErrorRef error = NULL;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    if (error) NSLog(@"%ld", CFErrorGetCode(error));
#else
    ABAddressBookRef addressBook = ABAddressBookCreate();
#endif

    NSDate *start = [NSDate date];

    // Do not change order of loading
    [self loadSourcesWithABAddressBookRef: addressBook];

    [self loadGroupsWithABAddressBookRef: addressBook];

    [self loadContactsWithABAddressBookRef: addressBook];

    CFRelease(addressBook);
    
    [self setDateAddressBookLoaded: [NSDate date]];
    NSLog(@"Address book loaded in %.2f", fabs([self.dateAddressBookLoaded timeIntervalSinceDate: start]));

    if (self.status == kAddressBookInitializing) 
    {
      [self setStatus: kAddressBookOnline];
      dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName: AddressBookDidInitializeNotification object: nil];
      });
    }
    else if (self.status == kAddressBookLoading) 
    {
      [self setStatus: kAddressBookOnline];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName: AddressBookDidLoadNotification object: nil];
    });
    [self resume_ab_timer];
  };

  dispatch_async(_ab_queue, block);
}

- (void)loadSourcesWithABAddressBookRef: (ABAddressBookRef)addressBook 
{
  NSAssert(!dispatch_get_specific(IsOnMainQueueKey), @"Must not be dispatched on main queue");

  if (!self.sources) {
    self.sources = [[NSMutableArray alloc] init];
  }

  NSArray *sources = (NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllSources(addressBook));

  if ([sources count] > 1)
  {
    AKSource *aggregatorSource = [self sourceForSourceId: kSourceAggregate];
    if (!aggregatorSource) {
      aggregatorSource = [[AKSource alloc] initWithABRecordID: kSourceAggregate];
      aggregatorSource.canCreateRecord = YES;
      [self.sources addObject: aggregatorSource];
    }
  }

  ABRecordRef source = ABAddressBookCopyDefaultSource(addressBook);
  ABRecordID defaultSourceID = ABRecordGetRecordID(source);
  CFRelease(source);

  for (id obj in sources) 
  {
    ABRecordRef recordRef = (__bridge ABRecordRef)obj;
    ABRecordID recordID = ABRecordGetRecordID(recordRef);

    ABSourceType type =  [(NSNumber *)CFBridgingRelease(ABRecordCopyValue(recordRef, kABSourceTypeProperty)) integerValue];
    if (type == kABSourceTypeExchangeGAL) continue; // No support for Exchange Global Address List, yet

    AKSource *source = [self sourceForSourceId: recordID];
    if (!source) {
      source = [[AKSource alloc] initWithABRecordID: recordID];
      source.isDefault = (defaultSourceID == recordID) ? YES : NO;
      
      ABRecordRef tryRecordRef = ABPersonCreateInSource(source.recordRef);
      if (tryRecordRef != nil)
      { // Check if source supports create records
        source.canCreateRecord = YES;
        CFRelease(tryRecordRef);
      }
      [self.sources addObject: source];
    }
  }
  self.sourceID = (sources.count > 1) ? kSourceAggregate : defaultSourceID;
}

- (void)loadGroupsWithABAddressBookRef: (ABAddressBookRef)addressBook
{
  NSAssert(!dispatch_get_specific(IsOnMainQueueKey), @"Must not be dispatched on main queue");

  if (ShowGroups == NO) return;

  [self setGroupID: kGroupAggregate];

  AKGroup *mainAggregateGroup = nil;
    
  for (AKSource *source in self.sources)
  {
    AKGroup *aggregateGroup = [source groupForGroupId: kGroupAggregate];
    if (!aggregateGroup) {
      aggregateGroup = [[AKGroup alloc] initWithABRecordID: kGroupAggregate];
      [source.groups addObject: aggregateGroup];
    }

    if (source.recordID < 0) 
    {
      if (source.recordID == kSourceAggregate)
      {
        mainAggregateGroup = aggregateGroup;
        [mainAggregateGroup setIsMainAggregate: YES];
      }
      continue; // Skip custom sources
    }

    NSArray *groups = (NSArray *) CFBridgingRelease(ABAddressBookCopyArrayOfAllGroupsInSource(addressBook, source.recordRef));

    for (id obj in groups) 
    {
      ABRecordRef recordRef = (__bridge ABRecordRef)obj;
      ABRecordID recordID = ABRecordGetRecordID(recordRef);

      NSString *name = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef, kABGroupNameProperty));
      NSLog(@"% 3d : %@", recordID, name);

      AKGroup *group = [source groupForGroupId: recordID];
      if (!group) {
        group = [[AKGroup alloc] initWithABRecordID: recordID];
        [source.groups addObject: group];
      }

      NSArray *members = (NSArray *) CFBridgingRelease(ABGroupCopyArrayOfAllMembers(recordRef));
      [group.memberIDs removeAllObjects];
      for (id member in members)
      {
        ABRecordRef record = (__bridge ABRecordRef)member;
        // From ABGRoup Reference: Groups may not contain other groups
        if (ABRecordGetRecordType(record) == kABPersonType)
        {
          NSNumber *contactID = [NSNumber numberWithInteger: ABRecordGetRecordID(record)];
          [group.memberIDs addObject: contactID];
        }
      }
    }
    [source revertGroupsOrder];
  }
}

- (void)loadContactsWithABAddressBookRef: (ABAddressBookRef)addressBook 
{
  NSAssert(!dispatch_get_specific(IsOnMainQueueKey), @"Must not be dispatched on main queue");

  NSMutableDictionary *tempContactIdentifiers = [[NSMutableDictionary alloc] init];
    
  NSMutableSet *nativeContactIdentifiers = [[NSMutableSet alloc] init];

  NSMutableSet *appContactIdentifiers = [[NSMutableSet alloc] init];
  if (self.status == kAddressBookLoading)
  {
    for (NSString *key in self.allContactIdentifiers) {
      NSArray *section = [self.allContactIdentifiers objectForKey: key];
      [appContactIdentifiers addObjectsFromArray: section];
    }
  }

  NSString *sectionKeys = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ#";

  for (int i = 0; i < [sectionKeys length]; i++) 
  {
    NSString *sectionKey = [NSString stringWithFormat: @"%c", [sectionKeys characterAtIndex: i]];
    NSMutableArray *sectionArray = [[NSMutableArray alloc] init];
    [tempContactIdentifiers setObject: sectionArray forKey: sectionKey];
  }

  AKSource *aggregateSource = [self sourceForSourceId: kSourceAggregate];
  AKGroup *mainAggregateGroup = [aggregateSource groupForGroupId: kGroupAggregate];

  NSMutableSet *linkedRecords = [[NSMutableSet alloc] init];

  [self setContactsCount: ABAddressBookGetPersonCount(addressBook)];
  NSLog(@"Number of contacts: %d", self.contactsCount);
  NSInteger i = 0;
  // Get array of records in Address Book
  for (AKSource *source in self.sources)
  {
    if (source.recordID < 0) {
      continue; // Skip custom sources
    }

    AKGroup *aggregateGroup = [source groupForGroupId: kGroupAggregate];

    NSArray *people = (NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook,
                                                                                                             source.recordRef,ABPersonGetSortOrdering()));
    for (id obj in people)
    {
      ABRecordRef recordRef = (__bridge ABRecordRef)obj;

      ABRecordID recordID = ABRecordGetRecordID(recordRef);
      NSNumber *contactID = [NSNumber numberWithInteger: recordID];

      [nativeContactIdentifiers addObject: contactID];

      NSDate *created = (NSDate *)CFBridgingRelease(ABRecordCopyValue(recordRef, kABPersonCreationDateProperty));
      NSDate *modified = (NSDate *)CFBridgingRelease(ABRecordCopyValue(recordRef, kABPersonModificationDateProperty));

      if (self.status == kAddressBookLoading)
      {
        if ([self.dateAddressBookLoaded compare: modified] != NSOrderedDescending)
        {
          NSString *name = (NSString *)CFBridgingRelease(ABRecordCopyCompositeName(recordRef));
          NSString *sectionKey = [AKContact sectionKeyForName: name];
          [self deleteRecordID: recordID inDictionary: self.allContactIdentifiers forKey: sectionKey withAddressBookRef: addressBook];
          [self insertRecordID: recordID inDictionary: self.allContactIdentifiers forKey: sectionKey withAddressBookRef: addressBook];

          NSLog(@"%@ did change", name);
        }
        else if ([self.dateAddressBookLoaded compare: created] != NSOrderedDescending)
        {
          NSString *name = (NSString *)CFBridgingRelease(ABRecordCopyCompositeName(recordRef));
          NSString *sectionKey = [AKContact sectionKeyForName: name];
          [self insertRecordID: recordID inDictionary: self.allContactIdentifiers forKey: sectionKey withAddressBookRef: addressBook];

          NSLog(@"%@ is new", name);
        }
        continue;
      }

      NSString *name = (NSString *)CFBridgingRelease(ABRecordCopyCompositeName(recordRef));
      NSString *sectionKey = [AKContact sectionKeyForName: name];

      //NSLog(@"% 3d : %@", recordID, name);

      [self.delegate setProgress: (CGFloat)++i / self.contactsCount];

      NSArray *linked = CFBridgingRelease(ABPersonCopyArrayOfAllLinkedPeople(recordRef));
      for (id obj in linked)
      {
        ABRecordRef linkedRef = (__bridge ABRecordRef)obj;
        ABRecordID linkedID = ABRecordGetRecordID(linkedRef);
        if (linkedID != recordID)
        {
          [linkedRecords addObject: [NSNumber numberWithInteger: linkedID]];
        }
      }

      if (![mainAggregateGroup.memberIDs member: contactID] && ![linkedRecords member: contactID])
      {
        [mainAggregateGroup.memberIDs addObject: contactID];
      }

      if (![aggregateGroup.memberIDs member: contactID])
      {
        [aggregateGroup.memberIDs addObject: contactID];
      }

      [self insertRecordID: recordID inDictionary: tempContactIdentifiers forKey: sectionKey withAddressBookRef: addressBook];
    }
  }

  if (self.status == kAddressBookInitializing)
  {
    self.allContactIdentifiers = tempContactIdentifiers;
  }
  else
  {
    NSLog(@"Count all: %d Count native: %d", appContactIdentifiers.count, nativeContactIdentifiers.count);
    [appContactIdentifiers minusSet: nativeContactIdentifiers];
    NSLog(@"Deleted contactIDs: %@", [appContactIdentifiers allObjects]);
  }
}

- (void)insertRecordID: (ABRecordID)recordID inDictionary: (NSMutableDictionary *)dictionary forKey: (NSString *)key withAddressBookRef: (ABAddressBookRef)addressBook
{
  NSMutableArray *sectionArray = (NSMutableArray *)[dictionary objectForKey: key];

  NSUInteger index = [self indexOfRecordID: recordID inArray: sectionArray withAddressBookRef: addressBook];

  [sectionArray insertObject: [NSNumber numberWithInteger: recordID] atIndex: index];
}

- (void)deleteRecordID: (ABRecordID)recordID inDictionary: (NSMutableDictionary *)dictionary forKey: (NSString *)key withAddressBookRef: (ABAddressBookRef)addressBook
{
    NSMutableArray *sectionArray = [self.allContactIdentifiers objectForKey: key];

    NSUInteger index = [sectionArray indexOfObject: @(recordID)];
    if (index != NSNotFound)
    {   // Got lucky
        [sectionArray removeObjectAtIndex: index];
        NSLog(@"Stayed in same section");
    }
    else
    {   // Moved to another section
        for (NSString *sectionKey in self.allContactIdentifiers)
        {   // This is slow but should run seldom
            if ([sectionKey isEqualToString: key])
            {   // It's not here if the else branch is executes
                continue;
            }
            NSMutableArray *prevSectionArray = [self.allContactIdentifiers objectForKey: key];
            index = [prevSectionArray indexOfObject: @(recordID)];
            if (index != NSNotFound)
            {
                NSLog(@"Moved from section: %@", key);
                [prevSectionArray removeObjectAtIndex: index];
                break;
            }
        }
    }
}

- (NSUInteger)indexOfRecordID: (ABRecordID) recordID inArray: (NSArray *)array withAddressBookRef: (ABAddressBookRef)addressBook
{
  NSComparator comparator = ^(id obj1, id obj2) {
      ABRecordRef recordRef_1 = ABAddressBookGetPersonWithRecordID(addressBook, [(NSNumber *)obj1 integerValue]);
      ABRecordRef recordRef_2 = ABAddressBookGetPersonWithRecordID(addressBook, [(NSNumber *)obj2 integerValue]);
        
      NSString *name_1 = (NSString *)CFBridgingRelease(ABRecordCopyCompositeName(recordRef_1));
      NSString *name_2 = (NSString *)CFBridgingRelease(ABRecordCopyCompositeName(recordRef_2));
        
      return (NSComparisonResult)[name_1 compare: name_2];
  };

  return [array indexOfObject: [NSNumber numberWithInteger: recordID]
                inSortedRange: (NSRange){0, array.count}
                      options: NSBinarySearchingInsertionIndex
              usingComparator: comparator];
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
  NSNumber *contactID = [NSNumber numberWithInteger: recordId];
  AKContact *ret = [self.contacts objectForKey: contactID];
  if (ret == nil)
  {
    ret = [[AKContact alloc] initWithABRecordID: recordId];
    if (recordId != newContactID)
    {
      [self.contacts setObject: ret forKey: contactID];
    }
  }
  return ret;
}

- (AKSource *)sourceForContactId: (ABRecordID)recordId
{
  AKSource *ret = nil;
  NSNumber *contactId = [NSNumber numberWithInteger: recordId];
  for (AKSource *source in self.sources)
  {
    if (source.recordID == kSourceAggregate) continue;

    AKGroup *group = [source groupForGroupId: kGroupAggregate];
    if ([group.memberIDs member: contactId] != nil)
    {
      ret = source;
      break;
    }
  }
  return ret;
}

- (void)removeRecordID: (ABRecordID)recordID
{
  AKContact *contact = [self contactForContactId: recordID];

  for (NSMutableArray *array in [self.allContactIdentifiers allValues])
  {
    [array removeObject: [NSNumber numberWithInteger: recordID]];
  }

  [self setNeedReload: NO];

  CFErrorRef error = NULL;
  ABAddressBookRemoveRecord(self.addressBookRef, contact.recordRef, &error);
  if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }

  ABAddressBookSave(self.addressBookRef, &error);
  if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }
}

- (void)releaseUnusedContacts 
{
  NSMutableArray *staleIDs = [[NSMutableArray alloc] init];

  for (NSNumber *contactID in [self.contacts allKeys]) 
  {
    AKContact *contact = [self.contacts objectForKey: contactID];
    NSDate *age = [contact age];

    NSTimeInterval elapsed = fabs([age timeIntervalSinceNow]);
    if (elapsed > 60) 
    {
      [staleIDs addObject: contactID];
    }
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    [self.contacts removeObjectsForKeys: staleIDs];
    ABAddressBookRevert(self.addressBookRef);
  });
}

- (void)resume_ab_timer 
{
  if (self.ab_timer_suspended == YES) {
    dispatch_source_set_timer(self.ab_timer,
                              dispatch_time(DISPATCH_TIME_NOW, UnusedContactsReleaseTime * NSEC_PER_SEC),
                              DISPATCH_TIME_FOREVER, 0ull);
    dispatch_resume(self.ab_timer);
    self.ab_timer_suspended = NO;
  }
}

- (void)suspend_ab_timer 
{
  if (self.ab_timer_suspended == NO) 
  {
    dispatch_suspend(self.ab_timer);
    self.ab_timer_suspended = YES;
  }
}

@end
