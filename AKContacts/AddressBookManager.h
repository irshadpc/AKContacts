//
//  AddressBookManager.h
//
//  Copyright (c) 2013 Adam Kornafeld All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@class AppDelegate;
@class AKContact;

typedef enum {
  kAddressBookOffline = 0,
  kAddressBookInitializing,
  kAddressBookOnline,
  kAddressBookReloading,
} AddressBookStatus;

@interface AddressBookManager : NSObject {

  AppDelegate *appDelegate;

  ABAddressBookRef addressBook;
  NSInteger status;
  dispatch_semaphore_t addressBookSemaphore;
  dispatch_queue_t dispatch_queue;
  
  NSMutableDictionary *abContacts;
  NSMutableDictionary *allContactIdentifiers;
  NSMutableArray *allKeys;
  NSMutableArray *keys;
  NSMutableDictionary *contactIdentifiersToDisplay;
  
}

@property (assign) ABAddressBookRef addressBook;
@property (assign) NSInteger status;
@property (strong) NSMutableDictionary *abContacts;
@property (strong) NSMutableDictionary *allContactIdentifiers;
@property (strong) NSMutableArray *allKeys;
@property (strong) NSMutableArray *keys;
@property (strong) NSMutableDictionary *contactIdentifiersToDisplay;

-(void)requestAddressBookAccess;
-(void)loadAddressBook;
-(NSInteger)contactsCount;
-(AKContact *)contactForIdentifier: (NSInteger)recordId;
-(void)resetSearch;
-(void)removeEmptyKeysFromContactIdentifiersToDisplay;

-(void)handleSearchForTerm:(NSString *)searchTerm;

@end
