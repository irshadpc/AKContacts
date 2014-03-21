//
//  AKContactsTableViewDataSource.m
//  AKContacts
//
//  Created by Adam Kornafeld on 1/15/14.
//  Copyright (c) 2014 Adam Kornafeld. All rights reserved.
//

#import "AKContactsTableViewDataSource.h"
#import "AKAddressBook.h"
#import "AKContact.h"
#import "AKGroup.h"
#import "AKSource.h"

@interface AKSearchStackElement : NSObject

@property (nonatomic, copy) NSString *character;
@property (nonatomic, strong) NSMutableArray *matches;

@end

@implementation AKSearchStackElement

@end

@interface AKContactsTableViewDataSource ()

- (void)handleSearchForCharacterAtIndex: (NSUInteger)index inTerm: (NSString *)term isFirstTerm: (BOOL)firstTerm;
- (NSArray *)contactIDsHavingNamePrefix: (NSString *)prefix inFirstTerm: (BOOL)firstTerm;
- (NSArray *)array: (NSArray *)array filteredWithTerm: (NSString *)term;
- (BOOL)recordID: (ABRecordID)recordID matchesTerm: (NSString *)term withAddressBookRef: (ABAddressBookRef)addressBookRef;

@end

@implementation AKContactsTableViewDataSource

- (NSInteger)displayedContactsCount
{
    NSInteger ret = 0;
    for (NSMutableArray *section in [self.contactIDs allValues])
    {
        ret += [section count];
    }
    return ret;
}

- (void)loadData
{
    AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];
    
    if (akAddressBook.status != kAddressBookOnline) return;
    
    self.keys = [[NSMutableArray alloc] initWithObjects: UITableViewIndexSearch, nil];
    
    AKSource *source = [akAddressBook sourceForSourceId: akAddressBook.sourceID];
    AKGroup *group = [source groupForGroupId: akAddressBook.groupID];
    NSMutableSet *groupMembers = [group memberIDs];
    
    NSArray *sectionKeys = [AKAddressBook sectionKeys];

    if (groupMembers.count == akAddressBook.contactsCount)
    {   // Shortcut for aggregate group if there's only a single source
        self.contactIDs = [NSKeyedUnarchiver unarchiveObjectWithData: [NSKeyedArchiver archivedDataWithRootObject: akAddressBook.contactIDs]]; // Mutable deep copy
        [self.keys addObjectsFromArray: sectionKeys];
    }
    else
    {
        [self setContactIDs: [[NSMutableDictionary alloc] initWithCapacity: [akAddressBook.contactIDs count]]];

        for (NSString *key in sectionKeys)
        {
            NSArray *arrayForKey = [akAddressBook.contactIDs objectForKey: key];
            NSMutableArray *sectionArray = [arrayForKey mutableCopy];

            NSMutableArray *recordsToRemove = [[NSMutableArray alloc] init];
            for (NSNumber *contactID in sectionArray)
            {
              if (groupMembers != nil && ![groupMembers member: contactID]) {
                [recordsToRemove addObject: contactID];
              }
            }
            [sectionArray removeObjectsInArray: recordsToRemove];
            if (sectionArray.count > 0)
            {
                [self.contactIDs setObject: sectionArray forKey: key];
                [self.keys addObject: key];
            }
        }
    }
}

- (void)handleSearchForTerm: (NSString *)searchTerm
{
  // Don't trim trailing whitespace needed for tokenization
  searchTerm = [searchTerm stringByTrimmingLeadingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
  AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];
  
  dispatch_block_t block = ^{
  
    dispatch_semaphore_wait(akAddressBook.ab_semaphore, DISPATCH_TIME_FOREVER);
    
    if (searchTerm.length > self.searchStack.count)
    {
      NSString *character = [searchTerm substringWithRange: NSMakeRange(searchTerm.length - 1, 1)];
      
      NSInteger(^nextCharacterIndex)(void) = ^{
        NSInteger index = 0;
        for (AKSearchStackElement *elem in [self.searchStack reverseObjectEnumerator]) {
          if ([elem.character isMemberOfCharacterSet: [NSCharacterSet whitespaceCharacterSet]]) {
            break;
          }
          index += 1;
        }
        return index;
      };
      
      NSInteger(^whiteSpaceCountOnStack)(void) = ^{
        NSInteger count = 0;
        for (AKSearchStackElement *elem in self.searchStack)
        {
          if ([elem.character isMemberOfCharacterSet: [NSCharacterSet whitespaceCharacterSet]])
          {
            count += 1;
          }
        }
        return count;
      };
      
      NSInteger whiteSpacesOnStack = whiteSpaceCountOnStack();
      
      NSArray *terms = [searchTerm componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
      for (NSInteger index = whiteSpacesOnStack; index < terms.count; ++index)
      {
        NSString *term = [terms objectAtIndex: index];
        if (!term.length) continue;

        if (![character isMemberOfCharacterSet: [NSCharacterSet whitespaceCharacterSet]])
        {
          NSInteger characterIndex = nextCharacterIndex();
          [self handleSearchForCharacterAtIndex: characterIndex inTerm: term isFirstTerm: (index == 0)];
        }
        else if (self.searchStack.count)
        { // Ignore whitespace
          AKSearchStackElement *previousStackElement = [self.searchStack objectAtIndex: (self.searchStack.count - 1)];
          
          AKSearchStackElement *element = [[AKSearchStackElement alloc] init];
          element.character = character;
          element.matches = [previousStackElement.matches mutableCopy];
          [self.searchStack addObject: element];
        }
      }
    }
    else if (self.searchStack.count)
    {
      [self.searchStack removeLastObject];
    }

    if (self.searchStack.count)
    {
      self.contactIDs = [[NSMutableDictionary alloc] initWithObjectsAndKeys: [self.searchStack.lastObject matches], [self.searchStack.firstObject character], nil];
    }
    else
    {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self loadData];
      });
    }

    dispatch_semaphore_signal(akAddressBook.ab_semaphore);

    if ([self.delegate respondsToSelector: @selector(dataSourceDidEndSearch:)]) {
      [self.delegate dataSourceDidEndSearch: self];
    }
  };
  
  dispatch_async(akAddressBook.ab_queue, block);
}

- (void)handleSearchForCharacterAtIndex: (NSUInteger)index inTerm: (NSString *)term isFirstTerm: (BOOL)firstTerm
{
  if (!term.length) return;

  NSString *character = [term substringWithRange: NSMakeRange(index, 1)];

  if (firstTerm && !index)
  {
    AKSearchStackElement *element = [[AKSearchStackElement alloc] init];
    element.character = (![character isMemberOfCharacterSet: [NSCharacterSet decimalDigitCharacterSet]]) ? character : @"#";
    if ([character isMemberOfCharacterSet: [NSCharacterSet letterCharacterSet]])
    {
      element.matches = [[self contactIDsHavingNamePrefix: character inFirstTerm: firstTerm] mutableCopy];
    }
    else
    {
      element.matches = [[self contactIDsHavingNumberPrefix: character] mutableCopy];
    }
    [self.searchStack addObject: element];
  }
  else
  {
    NSArray *matchingIDs;
    if (!index)
    {
        if ([character isMemberOfCharacterSet: [NSCharacterSet letterCharacterSet]])
        {
            matchingIDs = [self contactIDsHavingNamePrefix: character inFirstTerm: firstTerm];
        }
        else
        {
            matchingIDs = [self contactIDsHavingNumberPrefix: character];
        }
        matchingIDs = [self array: matchingIDs filteredWithTerm: term];
        NSMutableSet *matchingSet = [NSMutableSet setWithArray: matchingIDs];
        
        NSArray *previousMatches = [self.searchStack.lastObject matches];
        NSSet *previousSet = [NSSet setWithArray: previousMatches];
        
        [matchingSet intersectSet: previousSet];
        matchingIDs = [matchingSet allObjects];
    }
    else
    {
        matchingIDs = [self array: [self.searchStack.lastObject matches] filteredWithTerm: term];
    }
    
    AKSearchStackElement *element = [[AKSearchStackElement alloc] init];
    element.character = character;
    element.matches = [matchingIDs mutableCopy];
    [self.searchStack addObject: element];
  }
}

- (NSArray *)contactIDsHavingNamePrefix: (NSString *)prefix inFirstTerm: (BOOL)firstTerm
{
  NSArray *sectionArray = (firstTerm) ? [self.contactIDs objectForKey: prefix.uppercaseString] : [[self.searchStack lastObject] matches];
  NSMutableSet *sectionSet = [NSMutableSet setWithArray: sectionArray];

  AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];
  NSDictionary *invertedContactIDs = [akAddressBook inverseSortedContactIDs];
  NSArray *invertedSectionArray = [invertedContactIDs objectForKey: prefix.uppercaseString];
  NSMutableSet *invertedSectionSet = [NSMutableSet setWithArray: invertedSectionArray];
  
  NSMutableSet *displayedContactIDs = [[NSMutableSet alloc] init];
  for (NSArray *section in self.contactIDs.allValues)
  {
    [displayedContactIDs addObjectsFromArray: section];
  }
  [invertedSectionSet intersectSet: displayedContactIDs];
  
  [sectionSet unionSet: invertedSectionSet];

  return [sectionSet allObjects];
}

- (NSArray *)contactIDsHavingNumberPrefix: (NSString *)prefix
{
    AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];

    NSArray *sectionArray = [akAddressBook.contactIDsSortedByFirst objectForKey: prefix];
    NSMutableSet *sectionSet = [NSMutableSet setWithArray: sectionArray];

    NSArray *invertedSectionArray = [akAddressBook.contactIDsSortedByLast objectForKey: prefix.uppercaseString];
    NSMutableSet *invertedSectionSet = [NSMutableSet setWithArray: invertedSectionArray];

    [sectionSet unionSet: invertedSectionSet];

    NSMutableSet *displayedContactIDs = [[NSMutableSet alloc] init];
    for (NSArray *section in self.contactIDs.allValues)
    {
        [displayedContactIDs addObjectsFromArray: section];
    }
    [sectionSet intersectSet: displayedContactIDs];

    return [sectionSet allObjects];
}

- (NSArray *)array: (NSArray *)array filteredWithTerm: (NSString *)term
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
  CFErrorRef error = NULL;
  ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, &error);
  if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }
#else
  ABAddressBookRef addressBookRef = ABAddressBookCreate();
#endif
 
  NSMutableArray *filteredArray = [[NSMutableArray alloc] init];
  for (NSNumber *recordID in array)
  {
    if ([self recordID: recordID.intValue matchesTerm: term withAddressBookRef: addressBookRef])
    {
      [filteredArray addObject: recordID];
    }
  }
  CFRelease(addressBookRef);

  return [filteredArray copy];
}

- (BOOL)recordID: (ABRecordID)recordID matchesTerm: (NSString *)term withAddressBookRef: (ABAddressBookRef)addressBookRef
{
  BOOL ret = NO;
  ABRecordRef recordRef = ABAddressBookGetPersonWithRecordID(addressBookRef, recordID);
  if (recordRef)
  {
    NSInteger kind = [(NSNumber *)CFBridgingRelease(ABRecordCopyValue(recordRef, kABPersonKindProperty)) integerValue];
    if (kind == [(NSNumber *)kABPersonKindPerson integerValue])
    {
      NSString *name = CFBridgingRelease(ABRecordCopyValue(recordRef, kABPersonFirstNameProperty));
      name = name.stringWithDiacriticsRemoved;
      if ([name.lowercaseString hasPrefix: term.lowercaseString])
      {
        ret = YES;
      }
      else
      {
        name = CFBridgingRelease(ABRecordCopyValue(recordRef, kABPersonLastNameProperty));
        if ([name.stringWithDiacriticsRemoved.lowercaseString hasPrefix: term.lowercaseString])
        {
          ret = YES;
        }
      }
    }
    else if (kind == [(NSNumber *)kABPersonKindOrganization integerValue])
    {
      NSString *name = CFBridgingRelease(ABRecordCopyValue(recordRef, kABPersonOrganizationProperty));
      if ([name.stringWithDiacriticsRemoved.lowercaseString hasPrefix: term.lowercaseString])
      {
        ret = YES;
      }
    }
  }
  return ret;
}

- (void)finishSearch
{
    [self.searchStack removeAllObjects];
}

- (NSMutableArray *)searchStack
{
    if (!_searchStack)
    {
        _searchStack = [[NSMutableArray alloc] init];
    }
    return _searchStack;
}

@end
