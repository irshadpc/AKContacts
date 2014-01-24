//
//  AKContact.m
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

#import "AKContact.h"
#import "AKAddressBook.h"
#import "AKGroup.h"
#import "AKSource.h"

const int newContactID = -1<<9;

@interface AKContact ()

@end

@implementation AKContact

- (ABRecordRef)recordRef
{
  __block ABRecordRef ret;

  dispatch_block_t block = ^{
    if (super.recordRef == nil)
    {
      AKAddressBook *addressBook = [AKAddressBook sharedInstance];
      if (self.recordID != newContactID)
      {
        super.recordRef = ABAddressBookGetPersonWithRecordID(addressBook.addressBookRef, super.recordID);
      }
      else
      {
        AKSource *source = [addressBook sourceForSourceId: addressBook.sourceID];

        [[AKAddressBook sharedInstance] setNeedReload: NO];

        ABRecordRef recordRef = ABPersonCreateInSource((source.recordID >= 0) ? source.recordRef : NULL);

        CFErrorRef error = NULL;
        ABAddressBookAddRecord(addressBook.addressBookRef, recordRef, &error);
        if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }

        ABAddressBookSave(addressBook.addressBookRef, &error);
        if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }
        
        // Do not set super.recordID here!
        ABRecordID recordID = ABRecordGetRecordID(recordRef);
        CFRelease(recordRef);

        super.recordRef = ABAddressBookGetPersonWithRecordID(addressBook.addressBookRef, recordID);
      }
    }
    ret = super.recordRef;
    super.age = [NSDate date];
  };

  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);

  return ret;
}

- (NSString *)searchName
{
  return [self.sortName stringByFoldingWithOptions: NSDiacriticInsensitiveSearch locale: [NSLocale currentLocale]];
}

- (NSString *)sortName
{
    NSString *ret = nil;
    NSInteger kind = [(NSNumber *)[self valueForProperty: kABPersonKindProperty] integerValue];

    if (kind == [(NSNumber *)kABPersonKindPerson integerValue])
    {
        NSString *first = [self valueForProperty: kABPersonSortByFirstName];
        NSString *last = [self valueForProperty: kABPersonSortByLastName];

        if (kABPersonSortByFirstName == [AKAddressBook sharedInstance].sortOrdering)
        {
            ret = [NSString stringWithFormat: @"%@%@%@", first, self.nameDelimiter, last];
        }
        else
        {
            ret = [NSString stringWithFormat: @"%@%@%@", last, self.nameDelimiter, first];
        }
    }
    else if (kind == [(NSNumber *)kABPersonKindOrganization integerValue])
    {
        ret = [self valueForProperty: kABPersonOrganizationProperty];
    }
    return ret;
}

- (NSString *)compositeName
{
  NSString *ret = nil;
  NSInteger kind = [(NSNumber *)[self valueForProperty: kABPersonKindProperty] integerValue];

  if (kind == [(NSNumber *)kABPersonKindPerson integerValue])
  {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSString *prefix = [self valueForProperty: kABPersonPrefixProperty];
    if (prefix) [array addObject: prefix];

    NSString *last = [self valueForProperty: kABPersonLastNameProperty];
    NSString *first = [self valueForProperty: kABPersonFirstNameProperty];
    NSString *middle = [self valueForProperty: kABPersonMiddleNameProperty];

    if (ABPersonGetCompositeNameFormatForRecord(self.recordRef) == kABPersonCompositeNameFormatFirstNameFirst)
    {
      if (first) [array addObject: first];
      if (middle) [array addObject: middle];
      if (last) [array addObject: last];
      
    }
    else
    {
      if (last) [array addObject: last];
      if (first) [array addObject: first];
      if (middle) [array addObject: middle];
    }

    NSString *suffix = [self valueForProperty: kABPersonSuffixProperty];
    if (suffix) [array addObject: suffix];

    ret = [array componentsJoinedByString: self.nameDelimiter];
  }
  else if (kind == [(NSNumber *)kABPersonKindOrganization integerValue])
  {
    ret = [self valueForProperty: kABPersonOrganizationProperty];
  }
  return ret;
}

- (NSString *)phoneticName
{
  NSString *ret = nil;
  NSInteger kind = [(NSNumber *)[self valueForProperty: kABPersonKindProperty] integerValue];

  if (kind == [(NSNumber *)kABPersonKindPerson integerValue])
  {
    NSMutableArray *array = [[NSMutableArray alloc] init];

    NSString *last = [self valueForProperty: kABPersonLastNamePhoneticProperty];
    NSString *middle = [self valueForProperty: kABPersonMiddleNamePhoneticProperty];
    NSString *first = [self valueForProperty: kABPersonFirstNamePhoneticProperty];

    if (ABPersonGetCompositeNameFormatForRecord(self.recordRef) == kABPersonCompositeNameFormatFirstNameFirst)
    {
      if (first) [array addObject: first];
      if (middle) [array addObject: middle];
      if (last) [array addObject: last];
    }
    else
    {
      if (last) [array addObject: last];
      if (first) [array addObject: first];
      if (middle) [array addObject: middle];
    }

    ret = [array componentsJoinedByString: self.nameDelimiter];
  }
  else if (kind == [(NSNumber *)kABPersonKindOrganization integerValue])
  {
    ret = [self valueForProperty: kABPersonOrganizationProperty];
  }
  return ret;
}

- (NSString *)nameDelimiter
{
    __block NSString *ret;
    
    dispatch_block_t block = ^{
        ret = (NSString *)CFBridgingRelease(ABPersonCopyCompositeNameDelimiterForRecord(self.recordRef));
    };
    
    if (dispatch_get_specific(IsOnMainQueueKey)) block();
    else dispatch_sync(dispatch_get_main_queue(), block);
    
    return ret;
}

- (NSString *)displayDetails
{
  NSString *ret = nil;
  NSInteger kind = [(NSNumber *)[self valueForProperty: kABPersonKindProperty] integerValue];
  
  if (kind == [(NSNumber *)kABPersonKindOrganization integerValue])
  {
    ret = [self valueForProperty: kABPersonDepartmentProperty];
  }
  else if (kind == [(NSNumber *)kABPersonKindPerson integerValue])
  {
    NSMutableArray *array = [[NSMutableArray alloc] init];

    NSString *phonetic = [self phoneticName];
    if (phonetic) [array addObject: phonetic];

    NSString *nick = [self valueForProperty: kABPersonNicknameProperty];
    if (nick) [array addObject: nick];
    
    NSString *job = [self valueForProperty: kABPersonJobTitleProperty];
    if (job) [array addObject: job];
    
    NSString *org = [self valueForProperty: kABPersonOrganizationProperty];
    if (org) [array addObject: org];
    
    ret = [array componentsJoinedByString: @" "];
    
  }
  return ret;
}

- (NSArray *)linkedContactIDs
{
  __block NSMutableArray *ret = [[NSMutableArray alloc] init];

  dispatch_block_t block = ^{

    NSArray *array = (NSArray *)CFBridgingRelease(ABPersonCopyArrayOfAllLinkedPeople([self recordRef]));

    for (id obj in array)
    {
      ABRecordRef record = (__bridge ABRecordRef)obj;
      ABRecordID recordID = ABRecordGetRecordID(record);
      if (recordID != self.recordID)
      {
        [ret addObject: [NSNumber numberWithInteger: recordID]];
      }
    }
  };

  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);

  return [ret copy];
}

- (NSData*)imageData
{
  __block NSData *ret = nil;
  
  dispatch_block_t block = ^{
    if (ABPersonHasImageData([self recordRef]))
    {
      ret = (NSData *)CFBridgingRelease(ABPersonCopyImageDataWithFormat([self recordRef], kABPersonImageFormatThumbnail));
    }
  };
  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);

  return ret;
}

- (void)setImageData: (NSData *)pictureData
{
  dispatch_block_t block = ^{
    CFErrorRef error = NULL; // Remove first to update full and thumbnail image
    ABPersonRemoveImageData([self recordRef], &error);
    if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }
    if (pictureData != nil)
    {
      ABPersonSetImageData([self recordRef], (__bridge CFDataRef)pictureData, &error);
      if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }
    }
  };
  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);
}

- (UIImage *)image
{
  UIImage *ret = nil;
  NSData *data = [self imageData];
  if (data != nil)
  {
    ret = [UIImage imageWithData: data];
  }
  else
  {
    NSInteger kind = [(NSNumber *)[self valueForProperty: kABPersonKindProperty] integerValue];
    NSString *imageName = (kind == [(NSNumber *)kABPersonKindOrganization integerValue]) ? @"Company.png" : @"Contact.png";
    ret = [UIImage imageNamed: imageName];
  }
  return ret;
}

- (NSString *)addressForIdentifier: (NSInteger)identifier andNumRows: (NSInteger *)numRows
{
  NSDictionary *address = [self valueForMultiValueProperty: kABPersonAddressProperty andIdentifier: identifier];

  NSMutableArray *rows = [[NSMutableArray alloc] init];
  NSMutableArray *row = [[NSMutableArray alloc] init];
  NSString *street = [address objectForKey: (NSString *)kABPersonAddressStreetKey];
  NSString *city = [address objectForKey: (NSString *)kABPersonAddressCityKey];
  NSString *state = [address objectForKey: (NSString *)kABPersonAddressStateKey];
  NSString *ZIP = [address objectForKey: (NSString *)kABPersonAddressZIPKey];
  NSString *country = [address objectForKey: (NSString *)kABPersonAddressCountryKey];
  
  if ([city length] > 0) [row addObject: city];
  if ([state length] > 0) [row addObject: state];
  if ([ZIP length] > 0) [row addObject: ZIP];
  
  if ([street length] > 0) [rows addObject: street];
  if ([row count] > 0) [rows addObject: [row componentsJoinedByString: @" "]];
  if ([country length] > 0) [rows addObject: country];

  if (numRows != NULL)
  {
    *numRows = [rows count];
  }
  return [rows componentsJoinedByString: @"\n"];
}

- (NSString *)instantMessageDescriptionForIdentifier: (NSInteger)identifier
{
  NSDictionary *instantMessage = [self valueForMultiValueProperty: kABPersonInstantMessageProperty andIdentifier: identifier];
  
  NSString *username = [instantMessage objectForKey: (NSString *)kABPersonInstantMessageUsernameKey];
  NSString *service = [instantMessage objectForKey: (NSString *)kABPersonInstantMessageServiceKey];

  return [NSString stringWithFormat: @"%@ (%@)", username, service];
}

- (NSComparisonResult)compareByName:(AKContact *)otherContact
{
  NSString *name1 = [self sortName];
  NSString *name2 = [otherContact sortName];

  return [name1 localizedCaseInsensitiveCompare: name2];
}

- (void)commit
{
  ABAddressBookRef addressBookRef = [AKAddressBook sharedInstance].addressBookRef;

  if (ABAddressBookHasUnsavedChanges(addressBookRef))
  {
    [[AKAddressBook sharedInstance] setNeedReload: NO];

    CFErrorRef error = NULL;
    ABAddressBookSave(addressBookRef, &error);
    if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }
  }

  if (self.recordID == newContactID)
  {
    super.recordID = ABRecordGetRecordID(self.recordRef);
    
    AKAddressBook *addressBook = [AKAddressBook sharedInstance];
    
    [addressBook.contacts setObject: self forKey: [NSNumber numberWithInteger: self.recordID]];
    [addressBook.contacts removeObjectForKey: [NSNumber numberWithInteger: newContactID]];
    
    NSString *sectionKey = [AKContact sectionKeyForName: [self sortName]];

    [addressBook insertRecordID: self.recordID inDictionary: [addressBook allContactIdentifiers] forKey: sectionKey withAddressBookRef: addressBookRef];
    
    if (addressBook.groupID >= 0)
    { // Add to group
      AKSource *source = [addressBook sourceForSourceId: addressBook.sourceID];
      AKGroup *group = [source groupForGroupId: addressBook.groupID];
      [group addMemberWithID: self.recordID];
    }
  }
}

- (void)revert
{
  ABAddressBookRef addressBookRef = [AKAddressBook sharedInstance].addressBookRef;

  if (self.recordID == newContactID)
  { // Reference super.recordRef not self.recordRef here

    [[AKAddressBook sharedInstance] setNeedReload: NO];

    CFErrorRef error = NULL;
    ABAddressBookRemoveRecord(addressBookRef, super.recordRef, &error);
    if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }

    ABAddressBookSave(addressBookRef, &error);
    if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }
  }

  if (ABAddressBookHasUnsavedChanges(addressBookRef))
  {
    ABAddressBookRevert(addressBookRef);
  }
}

+ (NSString *)localizedNameForProperty: (ABPropertyID)property
{
  __block NSString *ret;

  dispatch_block_t block = ^{
    ret = (NSString *)CFBridgingRelease(ABPersonCopyLocalizedPropertyName(property));
  };

  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);

  return ret;
}

+ (NSString *)sectionKeyForName: (NSString *)name
{
  NSString *sectionKey = @"#";
  if ([name length] > 0)
  {
    NSString *key = [[[[name substringToIndex: 1] decomposedStringWithCanonicalMapping] substringToIndex: 1] uppercaseString];
    if (isalpha([key characterAtIndex: 0])) sectionKey = key;
  }
  return sectionKey;
}

@end
