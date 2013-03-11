//
//  AddressBookManager.m
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
#import "AppDelegate.h"

NSString *const AKAddressBookQueueName = @"AKAddressBookQueue";

NSString *const AddressBookDidInitializeNotification = @"AddressBookDidInitializeNotification";
NSString *const AddressBookDidLoadNotification = @"AddressBookDidLoadNotification";
NSString *const AddressBookSearchDidFinishNotification = @"AddressBookSearchDidFinishNotification";

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

@property (nonatomic, unsafe_unretained) AppDelegate *appDelegate;

@property (nonatomic, assign, readonly) dispatch_queue_t ab_queue;

@property (nonatomic, assign, readonly) dispatch_semaphore_t ab_semaphore;

/*
 * ABAddressBookRegisterExternalChangeCallback tends to fire multiple times
 * for a single change, so we store the last date when the addressbook
 * is reloaded and skip callbacks that fire too close to this date
 */
@property (nonatomic, strong) NSDate *dateAddressBookLoaded;

-(void)reloadAddressBook;
-(void)loadSourcesWithABAddressBookRef: (ABAddressBookRef)addressBook;
-(void)loadGroupsWithABAddressBookRef: (ABAddressBookRef)addressBook;
-(void)loadContactsWithABAddressBookRef: (ABAddressBookRef)addressBook;

@end

@implementation AKAddressBook

@synthesize appDelegate = _appDelegate;
@synthesize ab_queue = _ab_queue;
@synthesize ab_semaphore = _ab_semaphore;
@synthesize dateAddressBookLoaded = _dateAddressBookLoaded;

@synthesize addressBookRef = _addressBookRef;
@synthesize status = _status;
@synthesize sources = _sources;
@synthesize contacts = _contacts;
@synthesize allContactIdentifiers = _allContactIdentifiers;
@synthesize keys = _keys;
@synthesize contactIdentifiers = _contactIdentifiers;
@synthesize sourceID = _sourceID;
@synthesize groupID = _groupID;

#pragma mark - Address Book Changed Callback

void addressBookChanged(ABAddressBookRef reference, CFDictionaryRef dictionary, void *context) {
  @autoreleasepool {
    AKAddressBook *addressBook = (__bridge AKAddressBook *)context;
    [addressBook reloadAddressBook];
  }
}

-(id)init {
  self = [super init];
  if (self) {
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    _contactIdentifiers = nil;

    _ab_queue = dispatch_queue_create([AKAddressBookQueueName UTF8String], NULL);

    _ab_semaphore = dispatch_semaphore_create(1);
    
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

    NSAssert(dispatch_get_specific(IsOnMainQueueKey), @"Must be dispatched on main queue");

    CFErrorRef error = NULL;
    _addressBookRef = SYSTEM_VERSION_LESS_THAN(@"6.0") ? ABAddressBookCreate() : ABAddressBookCreateWithOptions(NULL, &error);
    if (error) NSLog(@"%ld", CFErrorGetCode(error));

    ABAddressBookRegisterExternalChangeCallback(_addressBookRef, addressBookChanged, (__bridge void*) self);
  }
  return self;
}

-(void)dealloc {
  CFRelease(_addressBookRef);
  [[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark - Address Book

-(void)requestAddressBookAccess {

  NSAssert(dispatch_get_specific(IsOnMainQueueKey), @"Must be dispatched on main queue");

  if (SYSTEM_VERSION_LESS_THAN(@"6.0")) {
    [self loadAddressBook];
  } else {

    ABAuthorizationStatus stat = ABAddressBookGetAuthorizationStatus();

    if (stat == kABAuthorizationStatusNotDetermined) {

      ABAddressBookRequestAccessWithCompletion(_addressBookRef, ^(bool granted, CFErrorRef error) {
        if (granted) {
          NSLog(@"Access granted to addressBook");
          [self loadAddressBook];
        } else {
          NSLog(@"Access denied to addressBook");
        }
      });

    } else if (stat == kABAuthorizationStatusDenied) {
      NSLog(@"kABAuthorizationStatusDenied");
    } else if (stat == kABAuthorizationStatusRestricted) {
      NSLog(@"kABAuthorizationStatusRestricted");
    } else if (stat == kABAuthorizationStatusAuthorized) {
      [self loadAddressBook];
    }
  }
}

-(void)reloadAddressBook {
  NSLog(@"AKAddressBook reloadAddressBook");

  if (_dateAddressBookLoaded) {
    NSTimeInterval elapsed = fabs([_dateAddressBookLoaded timeIntervalSinceNow]);
    NSLog(@"Elasped since last AB load: %f", elapsed);
    if (elapsed < 5.0) return;
  }

  if (_status != kAddressBookLoading) {
    [self setDateAddressBookLoaded: [NSDate date]];
    [self loadAddressBook];
  }

}

-(void)loadAddressBook {

  NSAssert(dispatch_get_specific(IsOnMainQueueKey), @"Must be dispatched on main queue");

  switch (self.status) {
    case kAddressBookOffline:
      [self setStatus: kAddressBookInitializing];
      break;
    case kAddressBookOnline:
      // _addressBookRef needs a revert to recognize external changes
      ABAddressBookRevert(_addressBookRef);
      [self setStatus: kAddressBookLoading];
      break;
  }

  /*
   * Loading the addressbook runs in the background and uses a local ABAddressBookRef
   */
  dispatch_block_t block = ^{

    CFErrorRef error = NULL;
    ABAddressBookRef addressBook = SYSTEM_VERSION_LESS_THAN(@"6.0") ?
                                    ABAddressBookCreate() :
                                    ABAddressBookCreateWithOptions(NULL, &error);
    if (error) NSLog(@"%ld", CFErrorGetCode(error));

    NSDate *start = [NSDate date];

    // Do not change order of loading
    [self loadSourcesWithABAddressBookRef: addressBook];

    [self loadGroupsWithABAddressBookRef: addressBook];
    
    [self loadContactsWithABAddressBookRef: addressBook];

    CFRelease(addressBook);
    
    NSDate *finish = [NSDate date];
    NSLog(@"Address book loaded in %f", [finish timeIntervalSinceDate: start]);

    [self resetSearch];

    if (self.status == kAddressBookInitializing) {
      [self setStatus: kAddressBookOnline];
      dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName: AddressBookDidInitializeNotification object: nil];
      });
    } else if (self.status == kAddressBookLoading) {
      [self setStatus: kAddressBookOnline];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName: AddressBookDidLoadNotification object: nil];
    });
  };

  dispatch_async(_ab_queue, block);
}

-(void)loadSourcesWithABAddressBookRef: (ABAddressBookRef)addressBook {
  
  NSAssert(dispatch_get_specific(IsOnMainQueueKey) == NULL, @"Must not be dispatched on main queue");

  _sources = [[NSMutableArray alloc] init];

  NSArray *sources = (NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllSources(addressBook));

  if ([sources count] > 1) {
    AKSource *aggregatorSource = [[AKSource alloc] initWithABRecordID: kSourceAggregate andAddressBookRef: _addressBookRef];
    [_sources addObject: aggregatorSource];
  }

  ABRecordRef source = ABAddressBookCopyDefaultSource(addressBook);
  ABRecordID defaultSourceID = ABRecordGetRecordID(source);
  CFRelease(source);

  for (id obj in sources) {
    
    ABRecordRef recordRef = (__bridge ABRecordRef)obj;
    ABRecordID recordID = ABRecordGetRecordID(recordRef);

    ABSourceType type =  [(NSNumber *)CFBridgingRelease(ABRecordCopyValue(recordRef, kABSourceTypeProperty)) integerValue];
    if (type == kABSourceTypeExchangeGAL) continue; // No support for Exchange Global Address List, yet
    
    AKSource *source = [[AKSource alloc] initWithABRecordID: recordID andAddressBookRef: _addressBookRef];
    [source setIsDefault: (defaultSourceID == recordID) ? YES : NO];

    [_sources addObject: source];

  }
}

-(void)loadGroupsWithABAddressBookRef: (ABAddressBookRef)addressBook {
  
  NSAssert(dispatch_get_specific(IsOnMainQueueKey) == NULL, @"Must not be dispatched on main queue");

  if (ShowGroups == NO) return;
  
  AKGroup *mainAggregateGroup = nil;
  
  for (AKSource *source in _sources) {

    AKGroup *aggregateGroup = [[AKGroup alloc] initWithABRecordID: kGroupAggregate andAddressBookRef: nil];
    [source.groups addObject: aggregateGroup];

    if (source.recordID < 0) {
      mainAggregateGroup = aggregateGroup;
      continue; // Skip custom sources
    }

    NSArray *groups = (NSArray *) CFBridgingRelease(ABAddressBookCopyArrayOfAllGroupsInSource(addressBook, source.recordRef));

    for (id obj in groups) {

      ABRecordRef recordRef = (__bridge ABRecordRef)obj;
      ABRecordID recordID = ABRecordGetRecordID(recordRef);

      NSString *name = (NSString *)CFBridgingRelease(ABRecordCopyValue(recordRef, kABGroupNameProperty));
      NSLog(@"% 3d : %@", recordID, name);

      AKGroup *group = [[AKGroup alloc] initWithABRecordID: recordID andAddressBookRef: _addressBookRef];
      [source.groups addObject: group];

      NSArray *members = (NSArray *) CFBridgingRelease(ABGroupCopyArrayOfAllMembers(recordRef));
      for (id member in members) {

        ABRecordRef record = (__bridge ABRecordRef)member;
        // From ABGRoup Reference: Groups may not contain other groups
        if(ABRecordGetRecordType(record) == kABPersonType) {

          NSNumber *contactID = [NSNumber numberWithInteger: ABRecordGetRecordID(record)];
          [group.memberIDs addObject: contactID];
          [aggregateGroup.memberIDs addObject: contactID];
          [mainAggregateGroup.memberIDs addObject: contactID];
        }
      }
    }
  }
}

-(void)loadContactsWithABAddressBookRef: (ABAddressBookRef)addressBook {

  NSAssert(dispatch_get_specific(IsOnMainQueueKey) == NULL, @"Must not be dispatched on main queue");

  NSMutableDictionary *tempContactIdentifiers = [[NSMutableDictionary alloc] init];
  NSMutableDictionary *tempContacts = [[NSMutableDictionary alloc] init];

  NSString *sectionKeys = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ#";

  for (int i = 0; i < [sectionKeys length]; i++) {
    NSString *sectionKey = [NSString stringWithFormat: @"%c", [sectionKeys characterAtIndex: i]];
    NSMutableArray *sectionArray = [[NSMutableArray alloc] init];
    [tempContactIdentifiers setObject: sectionArray forKey: sectionKey];
  }

  AKSource *aggregateSource = [self sourceForSourceId: kSourceAggregate];
  AKGroup *mainAggregateGroup = [aggregateSource groupForGroupId: kGroupAggregate];
  
  // Get array of records in Address Book
  for (AKSource *source in _sources) {

    if (source.recordID < 0)
      continue; // Skip custom sources
    
    AKGroup *aggregateGroup = [source groupForGroupId: kGroupAggregate];
    
    NSArray *people = (NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook,
                                                                                                             source.recordRef,
                                                                                                             ABPersonGetSortOrdering()));

    for (id obj in people) {

      ABRecordRef recordRef = (__bridge ABRecordRef)obj;

      ABRecordID recordID = ABRecordGetRecordID(recordRef);
      NSNumber *contactID = [NSNumber numberWithInteger: recordID];
      AKContact *contact = [[AKContact alloc] initWithABRecordID: recordID andAddressBookRef: _addressBookRef];

      /*
       NSArray *linkedContactIDs = [contact linkedContactIDs];
       NSMutableArray *allContactIDs = aggregateGroup.memberIDs;
       for (NSNumber *linkedID in linkedContactIDs) {
        if ([allContactIDs indexOfObject: linkedID] == NSNotFound) {
          [allContactIDs addObject: linkedID];
          break;
        }
      }
      */

      if ([mainAggregateGroup.memberIDs indexOfObject: contactID] == NSNotFound)
        [mainAggregateGroup.memberIDs addObject: contactID];

      if ([aggregateGroup.memberIDs indexOfObject: contactID] == NSNotFound)
        [aggregateGroup.memberIDs addObject: contactID];

      NSString *name = (NSString *)CFBridgingRelease(ABRecordCopyCompositeName(recordRef));
      
      NSLog(@"% 3d : %@", recordID, name);
            
      NSString *dictionaryKey = @"#";
      if ([name length] > 0) {
        dictionaryKey = [[[[name substringToIndex: 1] decomposedStringWithCanonicalMapping] substringToIndex: 1] uppercaseString];
      }
      
      [tempContacts setObject: contact forKey: contactID];
      
      // Put the recordID in the corresponding section of contactIdentifiers
      NSMutableArray *tArray = (NSMutableArray *)[tempContactIdentifiers objectForKey: dictionaryKey];
      if (tArray) {
        [tArray addObject: contactID];
      } else {
        tArray = (NSMutableArray *)[tempContactIdentifiers objectForKey: @"#"];
        [tArray addObject: contactID];
      }
    }
    
    [self setContacts: tempContacts];
    [self setAllContactIdentifiers: tempContactIdentifiers];
    
  }
}

-(AKSource *)defaultSource {

  AKSource *ret = nil;

  for (AKSource *source in _sources) {
    if ([source isDefault] == YES) {
      ret = source;
      break;
    }
  }

  NSAssert(ret != nil, @"No default source present");
  
  return ret;
}

-(NSInteger)contactsCount {
  return [[self.contacts allKeys] count];
}

-(NSInteger)displayedContactsCount {
  NSInteger ret = 0;
  for (NSMutableArray *section in [_contactIdentifiers allValues]) {
    ret += [section count];
  }
  return ret;
}

-(AKSource *)sourceForSourceId: (NSInteger)recordId {
  
  AKSource *ret = nil;
  
  for (AKSource *source in _sources) {
    if (source.recordID == recordId) {
      ret = source;
      break;
    }
  }
  
  if (recordId >= 0)
    NSAssert(ret != nil, @"Source does not exist");

  return ret;
}

-(AKContact *)contactForContactId: (NSInteger)recordId {
  return [self.contacts objectForKey: [NSNumber numberWithInteger: recordId]];
}

#pragma mark - Address Book Search

-(void)resetSearch {

  [self setContactIdentifiers: [[NSMutableDictionary alloc] initWithCapacity: [self.allContactIdentifiers count]]];
  [self setKeys: [[NSMutableArray alloc] init]];

  NSEnumerator *enumerator = [self.allContactIdentifiers keyEnumerator];
  NSString *key;

  AKSource *source = [self sourceForSourceId: _sourceID];
  AKGroup *group = [source groupForGroupId: _groupID];
  NSMutableArray *groupMembers = [group memberIDs];

  while ((key = [enumerator nextObject])) {
    NSArray *arrayForKey = [self.allContactIdentifiers objectForKey: key];
    NSMutableArray *sectionArray = [[NSMutableArray alloc] initWithCapacity: [arrayForKey count]];
    [self.contactIdentifiers setObject: sectionArray forKey: key];
    [sectionArray addObjectsFromArray: [self.allContactIdentifiers objectForKey: key]];

    NSMutableArray *recordsToRemove = [[NSMutableArray alloc] init];
    for (NSNumber *contactID in sectionArray) {
      if ([groupMembers indexOfObject: contactID] == NSNotFound)
        [recordsToRemove addObject: contactID];
    }
    [sectionArray removeObjectsInArray: recordsToRemove];
  }

  [self.keys addObject: UITableViewIndexSearch];
  [self.keys addObjectsFromArray: [[self.allContactIdentifiers allKeys] sortedArrayUsingSelector: @selector(compare:)]];
  // Little hack to move # to the end of the list
  if ([self.keys count] > 0) {
    [self.keys addObject: [self.keys objectAtIndex: 1]];
    [self.keys removeObjectAtIndex: 1];
  }

  // Remove empty keys
  NSMutableArray *emptyKeys = [[NSMutableArray alloc] init];
  for (NSString *key in [self.contactIdentifiers allKeys]) {
    NSMutableArray *array = [self.contactIdentifiers objectForKey: key];
    if ([array count] == 0)
      [emptyKeys addObject: key];
  }
  [self.contactIdentifiers removeObjectsForKeys: emptyKeys];
  [self.keys removeObjectsInArray: emptyKeys];
}

-(void)handleSearchForTerm: (NSString *)searchTerm {

  dispatch_block_t block = ^{

    dispatch_semaphore_wait(self.ab_semaphore, DISPATCH_TIME_FOREVER);

    NSMutableArray *sectionsToRemove = [[NSMutableArray alloc ]init];
    [self resetSearch];

    for (NSString *key in self.keys) {
      NSMutableArray *array = [self.contactIdentifiers valueForKey: key];
      NSMutableArray *toRemove = [[NSMutableArray alloc] init];
      for (NSNumber *identifier in array) {
        NSString *name = [[self.contacts objectForKey: identifier] searchName];
        
        if ([name rangeOfString: searchTerm options: NSCaseInsensitiveSearch].location == NSNotFound)
          [toRemove addObject: identifier];
      }
      
      if ([array count] == [toRemove count])
        [sectionsToRemove addObject: key];
      [array removeObjectsInArray: toRemove];
    }
    [self.keys removeObjectsInArray: sectionsToRemove];

    dispatch_semaphore_signal(self.ab_semaphore);

    [[NSNotificationCenter defaultCenter] postNotificationName: AddressBookSearchDidFinishNotification object: nil];
  };

  dispatch_async(self.ab_queue, block);
}

@end
