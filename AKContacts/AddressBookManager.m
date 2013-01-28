//
//  AddressBookManager.m
//
//  Copyright (c) 2013 Adam Kornafeld All rights reserved.
//

#import "AddressBookManager.h"
#import "AKContact.h"
#import "Constants.h"
#import "AppDelegate.h"

@implementation AddressBookManager

@synthesize addressBook;
@synthesize status;
@synthesize abContacts;
@synthesize allContactIdentifiers;
@synthesize allKeys;
@synthesize keys;
@synthesize contactIdentifiersToDisplay;

void addressBookChanged(ABAddressBookRef reference, CFDictionaryRef dictionary, void *context);

-(id)init {
  self = [super init];
  if (self) {
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    contactIdentifiersToDisplay = nil;
    dispatch_queue = dispatch_queue_create("com.AKContacts.addressBookManager", NULL);

    CFErrorRef error = NULL;
    addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    status = kAddressBookOffline;

    addressBookSemaphore = dispatch_semaphore_create(1);
    
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
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
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
    people = ABAddressBookCopyArrayOfAllPeople(addressBook);
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
       
      dispatch_semaphore_wait(addressBookSemaphore, DISPATCH_TIME_FOREVER);
      ABRecordRef record = (__bridge ABRecordRef)obj;
      AKContact *contact = [[AKContact alloc] initWithABRecordRef: record];
      NSNumber *recordId = [NSNumber numberWithUnsignedInteger: [contact recordID]];
       
      NSLog(@"%d : %@", [contact recordID], [contact displayName]);
       
      [tempABContacts setObject: contact forKey: recordId];
      dispatch_semaphore_signal(addressBookSemaphore);

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
    
    // Although not necessary for ARC, we want the change to be instant
    // Address book loading can take a long time
    [self setAbContacts: tempABContacts];
    [self setAllContactIdentifiers: tempContactIdentifiers];
    
    allKeys = [[NSMutableArray alloc] init];
    [allKeys addObject: UITableViewIndexSearch];
    [allKeys addObjectsFromArray: [[allContactIdentifiers allKeys] 
                                sortedArrayUsingSelector: @selector(compare:)]];
    // Little hack to move # to the end of the list
    if ([allKeys count] > 0) {
      [allKeys addObject: [allKeys objectAtIndex: 1]];
      [allKeys removeObjectAtIndex: 1];
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

  dispatch_async(dispatch_queue, block);
}

-(NSInteger)contactsCount {
  return [[self.abContacts allKeys] count];
}

-(AKContact *)contactForIdentifier: (NSInteger)recordId {
  return [abContacts objectForKey: [NSNumber numberWithInteger: recordId]];
}

#pragma mark - Address Book Search

-(void)resetSearch {
  
  [self setContactIdentifiersToDisplay: [[NSMutableDictionary alloc] initWithCapacity: [allContactIdentifiers count]]];
  [self setKeys: [[NSMutableArray alloc] init]];

  NSEnumerator *enumerator = [self.allContactIdentifiers keyEnumerator];
  NSString *key;
    
  while ((key = [enumerator nextObject])) {
    NSArray *arrayForKey = [self.allContactIdentifiers objectForKey: key];
    NSMutableArray *sectionArray = [[NSMutableArray alloc] initWithCapacity: [arrayForKey count]];
    [sectionArray addObjectsFromArray: [allContactIdentifiers objectForKey: key]];
    [self.contactIdentifiersToDisplay setObject: sectionArray forKey: key];
  }
    
  [self.keys addObject: UITableViewIndexSearch];
  [self.keys addObjectsFromArray: [[self.allContactIdentifiers allKeys]
                                sortedArrayUsingSelector: @selector(compare:)]];
  // Little hack to move # to the end of the list
  if ([keys count] > 0) {
    [self.keys addObject: [keys objectAtIndex: 1]];
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
  
  for (NSString *key in keys) {
    NSMutableArray *array = [contactIdentifiersToDisplay valueForKey: key];
    NSMutableArray *toRemove = [[NSMutableArray alloc] init];
    for (NSNumber *identifier in array) {
      NSString *displayName = [[abContacts objectForKey: identifier] displayName];
      
      if ([displayName rangeOfString: searchTerm options: NSCaseInsensitiveSearch].location == NSNotFound)
        [toRemove addObject: identifier];
    }
    
    if ([array count] == [toRemove count])
      [sectionsToRemove addObject: key];
    [array removeObjectsInArray: toRemove];
  }
  [keys removeObjectsInArray: sectionsToRemove];
}

@end
