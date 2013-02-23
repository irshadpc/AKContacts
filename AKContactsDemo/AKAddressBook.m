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
#import "AppDelegate.h"

NSString *const AKAddressBookQueueName = @"AKAddressBookQueue";

NSString *const AddressBookDidInitializeNotification = @"AddressBookDidInitializeNotification";
NSString *const AddressBookDidLoadNotification = @"AddressBookDidLoadNotification";

const void *const IsOnMainQueueKey = &IsOnMainQueueKey;

@interface AKAddressBook ()

@property (nonatomic, assign) AppDelegate *appDelegate;

@property (nonatomic, assign) dispatch_queue_t ab_queue;

/*
 * ABAddressBookRegisterExternalChangeCallback tends to fire multiple times
 * for a single change, so we store the last date when the addressbook
 * is reloaded and skip callbacks that fire too close to this date
 */
@property (nonatomic, strong) NSDate *dateAddressBookLoaded;

-(void)reloadAddressBook;
-(void)loadContactsWithABAddressBookRef: (ABAddressBookRef)addressBook;
-(void)loadGroupsWithABAddressBookRef: (ABAddressBookRef)addressBook;

@end

@implementation AKAddressBook

@synthesize appDelegate = _appDelegate;
@synthesize ab_queue = _ab_queue;
@synthesize dateAddressBookLoaded = _dateAddressBookLoaded;

@synthesize addressBookRef = _addressBookRef;
@synthesize status = _status;
@synthesize contacts = _contacts;
@synthesize allContactIdentifiers = _allContactIdentifiers;
@synthesize keys = _keys;
@synthesize contactIdentifiers = _contactIdentifiers;

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

    _status = kAddressBookOffline;

    /*
     * The ABAddressBook API is not thread safe. ABAddressBook related calls are dispatched on the main queue.
     * The only exception to this is the initial loading of the contacts data that needs to be executed in
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

  if (_status != kAddressBookReloading) {
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
      [self setStatus: kAddressBookReloading];
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
    
    [self loadContactsWithABAddressBookRef: addressBook];
    
    [self loadGroupsWithABAddressBookRef: addressBook];
    
    CFRelease(addressBook);
    
    NSDate *finish = [NSDate date];
    NSLog(@"Address book loaded in %f", [finish timeIntervalSinceDate: start]);

    [self resetSearch];

    if (self.status == kAddressBookInitializing) {
      [self setStatus: kAddressBookOnline];
      dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName: AddressBookDidInitializeNotification object: nil];
      });
    } else if (self.status == kAddressBookReloading) {
      [self setStatus: kAddressBookOnline];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName: AddressBookDidLoadNotification object: nil];
    });

  };

  dispatch_async(_ab_queue, block);
}

-(void)loadContactsWithABAddressBookRef: (ABAddressBookRef)addressBook {

  NSMutableDictionary *tempContactIdentifiers = [[NSMutableDictionary alloc] init];
  NSMutableDictionary *tempContacts = [[NSMutableDictionary alloc] init];

  NSString *sectionKeys = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ#";

  for (int i = 0; i < [sectionKeys length]; i++) {
    NSString *sectionKey = [NSString stringWithFormat: @"%c", [sectionKeys characterAtIndex: i]];
    NSMutableArray *sectionArray = [[NSMutableArray alloc] init];
    [tempContactIdentifiers setObject: sectionArray forKey: sectionKey];
  }

  // Get array of records in Address Book
  CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
  // Make mutable copy of array
  CFMutableArrayRef peopleMutable = CFArrayCreateMutableCopy(kCFAllocatorDefault,
                                                             CFArrayGetCount(people),
                                                             people);
  CFRelease(people);

  // Sort array or records
  CFArraySortValues(peopleMutable,
                    CFRangeMake(0, CFArrayGetCount(peopleMutable)),
                    (CFComparatorFunction) ABPersonComparePeopleByName,
                    (void*) ABPersonGetSortOrdering());

  for (id obj in (__bridge NSMutableArray *)(peopleMutable)) {

    ABRecordRef record = (__bridge ABRecordRef)obj;

    ABRecordID recordID = ABRecordGetRecordID(record);
    NSNumber *contactID = [NSNumber numberWithInteger: recordID];
    AKContact *contact = [[AKContact alloc] initWithABRecordID: recordID andAddressBookRef: _addressBookRef];

    NSString *name = (NSString *)CFBridgingRelease(ABRecordCopyCompositeName(record));

    NSLog(@"% 3d : %@", recordID, name);

    NSString *dictionaryKey = @"#";
    if ([name length] > 0) {
      dictionaryKey = [[[[name substringToIndex: 1] decomposedStringWithCanonicalMapping] substringToIndex: 1] uppercaseString];
    }

    [tempContacts setObject: contact forKey: [NSNumber numberWithInteger: recordID]];

    // Put the recordID in the corresponding section of contactIdentifiers
    NSMutableArray *tArray = (NSMutableArray *)[tempContactIdentifiers objectForKey: dictionaryKey];
    if (tArray) {
      [tArray addObject: contactID];
    } else {
      tArray = (NSMutableArray *)[tempContactIdentifiers objectForKey: @"#"];
      [tArray addObject: contactID];
    }
  }

  CFRelease(peopleMutable);

  [self setContacts: tempContacts];
  [self setAllContactIdentifiers: tempContactIdentifiers];

}

-(void)loadGroupsWithABAddressBookRef: (ABAddressBookRef)addressBook {

  NSArray *groups = (__bridge NSMutableArray *)ABAddressBookCopyArrayOfAllGroups(addressBook);

  for (id obj in groups) {

    ABRecordRef groupRef = (__bridge ABRecordRef)obj;

    NSArray *group = CFBridgingRelease(ABGroupCopyArrayOfAllMembers(groupRef)); // CFRelease crashes

    for (id member in group) {

      ABRecordRef record = (__bridge ABRecordRef)member;
      // From ABGRoup Reference: Groups may not contain other groups
      if(ABRecordGetRecordType(record) == kABPersonType) {
        
      }
    }
  }

  CFRelease((__bridge CFArrayRef)groups);
  
}

-(NSInteger)contactsCount {
  return [[self.contacts allKeys] count];
}

-(AKContact *)contactForIdentifier: (NSInteger)recordId {
  return [self.contacts objectForKey: [NSNumber numberWithInteger: recordId]];
}

#pragma mark - Address Book Search

-(void)resetSearch {

  [self setContactIdentifiers: [[NSMutableDictionary alloc] initWithCapacity: [self.allContactIdentifiers count]]];
  [self setKeys: [[NSMutableArray alloc] init]];

  NSEnumerator *enumerator = [self.allContactIdentifiers keyEnumerator];
  NSString *key;

  while ((key = [enumerator nextObject])) {
    NSArray *arrayForKey = [self.allContactIdentifiers objectForKey: key];
    NSMutableArray *sectionArray = [[NSMutableArray alloc] initWithCapacity: [arrayForKey count]];
    [sectionArray addObjectsFromArray: [self.allContactIdentifiers objectForKey: key]];
    [self.contactIdentifiers setObject: sectionArray forKey: key];
  }

  [self.keys addObject: UITableViewIndexSearch];
  [self.keys addObjectsFromArray: [[self.allContactIdentifiers allKeys]
                                sortedArrayUsingSelector: @selector(compare:)]];
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
  NSMutableArray *sectionsToRemove = [[NSMutableArray alloc ]init];
  [self resetSearch];
  
  for (NSString *key in self.keys) {
    NSMutableArray *array = [self.contactIdentifiers valueForKey: key];
    NSMutableArray *toRemove = [[NSMutableArray alloc] init];
    for (NSNumber *identifier in array) {
//      AKContact *contact = [self contactForIdentifier: [identifier integerValue]]
      NSString *displayName = [[self.contacts objectForKey: identifier] displayName];

      if ([displayName rangeOfString: searchTerm options: NSCaseInsensitiveSearch].location == NSNotFound)
        [toRemove addObject: identifier];
    }
    
    if ([array count] == [toRemove count])
      [sectionsToRemove addObject: key];
    [array removeObjectsInArray: toRemove];
  }
  [self.keys removeObjectsInArray: sectionsToRemove];
}

@end