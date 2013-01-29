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

#import "AddressBookManager.h"
#import "AKContact.h"
#import "AppDelegate.h"
#import "Constants.h"

@interface AddressBookManager ()

@property (nonatomic, weak) AppDelegate *appDelegate;

@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, strong) dispatch_queue_t dispatch_queue;

@end

@implementation AddressBookManager

@synthesize appDelegate = _appDelegate;
@synthesize semaphore = _semaphore;
@synthesize dispatch_queue = _dispatch_queue;

@synthesize addressBook = _addressBook;
@synthesize status = _status;
@synthesize abContacts = _abContacts;
@synthesize allContactIdentifiers = _allContactIdentifiers;
@synthesize allKeys = _allKeys;
@synthesize keys = _keys;
@synthesize contactIdentifiersToDisplay = _contactIdentifiersToDisplay;

void addressBookChanged(ABAddressBookRef reference, CFDictionaryRef dictionary, void *context);

-(id)init {
  self = [super init];
  if (self) {
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _contactIdentifiersToDisplay = nil;
    _dispatch_queue = dispatch_queue_create("com.AKContacts.addressBookManager", NULL);

    CFErrorRef error = NULL;
    _addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    _status = kAddressBookOffline;

    _semaphore = dispatch_semaphore_create(1);
    
  }
  return self;
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark - Address Book

-(void)requestAddressBookAccess {
  
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_6_1
  ABAuthorizationStatus stat = ABAddressBookGetAuthorizationStatus();

  if (stat == kABAuthorizationStatusNotDetermined) {
    ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error) {
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
#else
  [self loadAddressBook];
#endif
}

-(void)loadAddressBook {

  switch (self.status) {
    case kAddressBookOffline:
      [self setStatus: kAddressBookInitializing];
      break;
    case kAddressBookOnline:
      [self setStatus: kAddressBookReloading];
      break;
  }

  dispatch_block_t block = ^{
    NSMutableDictionary *tempContactIdentifiers = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *tempABContacts = [[NSMutableDictionary alloc] init];

    NSString *sectionKeys = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ#";

    for (int i = 0; i < [sectionKeys length]; i++) {
      NSString *sectionKey = [NSString stringWithFormat: @"%c", [sectionKeys characterAtIndex: i]];
      NSMutableArray *sectionArray = [[NSMutableArray alloc] init];
      [tempContactIdentifiers setObject: sectionArray forKey: sectionKey];
    }

    CFArrayRef people = nil;
    CFMutableArrayRef peopleMutable = nil;

    // Get array of records in Address Book
    people = ABAddressBookCopyArrayOfAllPeople(_addressBook);
    // Make mutable copy of array
    peopleMutable = CFArrayCreateMutableCopy(kCFAllocatorDefault,
                                             CFArrayGetCount(people),
                                             people);
    CFRelease(people);

    // Sort array or records
    CFArraySortValues(peopleMutable,
                      CFRangeMake(0, CFArrayGetCount(peopleMutable)),
                      (CFComparatorFunction) ABPersonComparePeopleByName,
                      (void*) ABPersonGetSortOrdering());

    NSMutableArray *peopleArray = (__bridge NSMutableArray *)peopleMutable;

    NSDate *start = [NSDate date];

    [peopleArray enumerateObjectsWithOptions: NSEnumerationConcurrent usingBlock:
     ^(id obj, NSUInteger idx, BOOL *stop){
       
      dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
      ABRecordRef record = (__bridge ABRecordRef)obj;
      AKContact *contact = [[AKContact alloc] initWithABRecordRef: record];
      NSNumber *recordId = [NSNumber numberWithUnsignedInteger: [contact recordID]];
       
      NSLog(@"%d : %@", [contact recordID], [contact displayName]);
       
      [tempABContacts setObject: contact forKey: recordId];
      dispatch_semaphore_signal(self.semaphore);

      // Put the recordID in the corresponding section of contactIdentifiers
      NSMutableArray *tArray = (NSMutableArray *)[tempContactIdentifiers objectForKey: [contact dictionaryKey]];
      if (tArray) {
        [tArray addObject: recordId];
      } else {
        tArray = (NSMutableArray *)[tempContactIdentifiers objectForKey: @"#"];
        [tArray addObject: recordId];
      }
    }]; // End [peopleArray enumerateObjectsWithOptions:

    NSDate *finish = [NSDate date];
    NSLog(@"Address book loaded in %f", [finish timeIntervalSinceDate: start]);

    [self setAbContacts: tempABContacts];
    [self setAllContactIdentifiers: tempContactIdentifiers];

    self.allKeys = [[NSMutableArray alloc] init];
    [self.allKeys addObject: UITableViewIndexSearch];
    [self.allKeys addObjectsFromArray: [[self.allContactIdentifiers allKeys]
                                sortedArrayUsingSelector: @selector(compare:)]];
    // Little hack to move # to the end of the list
    if ([self.allKeys count] > 0) {
      [self.allKeys addObject: [self.allKeys objectAtIndex: 1]];
      [self.allKeys removeObjectAtIndex: 1];
    }

    [self resetSearch];

    if (self.status == kAddressBookInitializing) {
      [self setStatus: kAddressBookOnline];
      dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName: AddressBookDidLoadNotification object: nil];
      });
    } else if (self.status == kAddressBookReloading) {
      [self setStatus: kAddressBookOnline];
    }
  };

  dispatch_async(self.dispatch_queue, block);
}

-(NSInteger)contactsCount {
  return [[self.abContacts allKeys] count];
}

-(AKContact *)contactForIdentifier: (NSInteger)recordId {
  return [self.abContacts objectForKey: [NSNumber numberWithInteger: recordId]];
}

#pragma mark - Address Book Search

-(void)resetSearch {

  [self setContactIdentifiersToDisplay: [[NSMutableDictionary alloc] initWithCapacity: [self.allContactIdentifiers count]]];
  [self setKeys: [[NSMutableArray alloc] init]];

  NSEnumerator *enumerator = [self.allContactIdentifiers keyEnumerator];
  NSString *key;

  while ((key = [enumerator nextObject])) {
    NSArray *arrayForKey = [self.allContactIdentifiers objectForKey: key];
    NSMutableArray *sectionArray = [[NSMutableArray alloc] initWithCapacity: [arrayForKey count]];
    [sectionArray addObjectsFromArray: [self.allContactIdentifiers objectForKey: key]];
    [self.contactIdentifiersToDisplay setObject: sectionArray forKey: key];
  }

  [self.keys addObject: UITableViewIndexSearch];
  [self.keys addObjectsFromArray: [[self.allContactIdentifiers allKeys]
                                sortedArrayUsingSelector: @selector(compare:)]];
  // Little hack to move # to the end of the list
  if ([self.keys count] > 0) {
    [self.keys addObject: [self.keys objectAtIndex: 1]];
    [self.keys removeObjectAtIndex: 1];
  }

  [self removeEmptyKeysFromContactIdentifiersToDisplay];
}

-(void)removeEmptyKeysFromContactIdentifiersToDisplay {

  NSMutableArray *emptyKeys = [[NSMutableArray alloc] init];
  for (NSString *key in [self.contactIdentifiersToDisplay allKeys]) {
    NSMutableArray *array = [self.contactIdentifiersToDisplay objectForKey: key];
    if ([array count] == 0)
      [emptyKeys addObject: key];
  }
  [self.contactIdentifiersToDisplay removeObjectsForKeys: emptyKeys];
  [self.keys removeObjectsInArray: emptyKeys];
}

-(void)handleSearchForTerm: (NSString *)searchTerm {
  NSMutableArray *sectionsToRemove = [[NSMutableArray alloc ]init];
  [self resetSearch];
  
  for (NSString *key in self.keys) {
    NSMutableArray *array = [self.contactIdentifiersToDisplay valueForKey: key];
    NSMutableArray *toRemove = [[NSMutableArray alloc] init];
    for (NSNumber *identifier in array) {
      NSString *displayName = [[self.abContacts objectForKey: identifier] displayName];
      
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
