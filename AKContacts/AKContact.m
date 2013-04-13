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

@interface AKContact ()

@end


@implementation AKContact

- (id)initWithABRecordID: (ABRecordID) recordID
{
  self = [super init];
  if (self)
  {
    super.recordID = recordID;
  }
  return  self;
}

- (ABRecordRef)recordRef
{
  __block ABRecordRef ret;

  dispatch_block_t block = ^{
    if (super.recordRef == nil)
    {
      ABAddressBookRef addressBookRef = [[AKAddressBook sharedInstance] addressBookRef];
      super.recordRef = ABAddressBookGetPersonWithRecordID(addressBookRef, super.recordID);
    }
    ret = super.recordRef;
    super.age = [NSDate date];
  };

  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);

  return ret;
}

- (NSString *)name
{
  __block NSString *ret;

  dispatch_block_t block = ^{
		ret = (NSString *)CFBridgingRelease(ABRecordCopyCompositeName([self recordRef])); // kABStringPropertyType
	};

  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);

  return ret;
}

- (NSString *)searchName
{
  return [self.name stringByFoldingWithOptions: NSDiacriticInsensitiveSearch locale: [NSLocale currentLocale]];
}

- (NSString *)displayNameByOrdering: (ABPersonSortOrdering)ordering
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

    if (ordering == kABPersonSortByFirstName)
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

    ret = [array componentsJoinedByString: @" "];
  }
  else if (kind == [(NSNumber *)kABPersonKindOrganization integerValue])
  {
    ret = [self valueForProperty: kABPersonOrganizationProperty];
  }
  return ret;
}

- (NSString *)phoneticNameByOrdering: (ABPersonSortOrdering)ordering
{
  NSString *ret = nil;
  NSInteger kind = [(NSNumber *)[self valueForProperty: kABPersonKindProperty] integerValue];

  if (kind == [(NSNumber *)kABPersonKindPerson integerValue])
  {
    NSMutableArray *array = [[NSMutableArray alloc] init];

    NSString *last = [self valueForProperty: kABPersonLastNamePhoneticProperty];
    NSString *middle = [self valueForProperty: kABPersonMiddleNamePhoneticProperty];
    NSString *first = [self valueForProperty: kABPersonFirstNamePhoneticProperty];

    if (ordering == kABPersonSortByFirstName)
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

    ret = [array componentsJoinedByString: @" "];

  }
  else if (kind == [(NSNumber *)kABPersonKindOrganization integerValue])
  {
    ret = [self valueForProperty: kABPersonOrganizationProperty];
  }
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

    NSString *phonetic = [self phoneticNameByOrdering: ABPersonGetSortOrdering()];
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
      [ret addObject: [NSNumber numberWithInteger: recordID]];
    }
	};

  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);

  return [[NSArray alloc] initWithArray: ret];
}

- (NSString *)dictionaryKey
{
  return [self dictionaryKeyBySortOrdering: ABPersonGetSortOrdering()];
}

- (NSString *)dictionaryKeyBySortOrdering: (ABPersonSortOrdering)ordering
{
  NSString *ret = @"#";
  if ([[self displayNameByOrdering: ordering] length] > 0)
  {
    NSString *key = [[[[[self displayNameByOrdering: ordering] substringToIndex: 1]
                                 decomposedStringWithCanonicalMapping] substringToIndex: 1] uppercaseString];
    if (isalpha([key characterAtIndex: 0]))
      ret = key;
  }
  return ret;
}

- (NSData*)pictureData
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

- (UIImage *)picture
{
  UIImage *ret = nil;
  NSData *data = [self pictureData];
  if (data)
  {
    ret = [UIImage imageWithData: [self pictureData]];
  }
  else
  {
    NSInteger kind = [(NSNumber *)[self valueForProperty: kABPersonKindProperty] integerValue];
    ret = [UIImage imageNamed: (kind == [(NSNumber *)kABPersonKindOrganization integerValue]) ? @"Company.png" : @"Contact"];
  }
  return ret;
}

- (NSComparisonResult)compareByName:(AKContact *)otherContact
{
  return [self.name localizedCaseInsensitiveCompare: otherContact.name];
}

@end
