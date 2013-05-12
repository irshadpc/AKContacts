//
//  AKRecord.m
//
//  Copyright 2013 (c) Adam Kornafeld All rights reserved.
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

#import "AKRecord.h"
#import "AKAddressBook.h"
#import "AKContact.h"

NSString *const kIdentifier = @"Identifier";
NSString *const kValue = @"Value";
NSString *const kLabel = @"Label";

@interface AKRecord ()

@property (nonatomic, strong) NSMutableDictionary *createDict;
@property (nonatomic, strong) NSMutableDictionary *updateDict;
@property (nonatomic, strong) NSMutableDictionary *deleteDict;

@end


@implementation AKRecord

@synthesize createDict = _createDict;
@synthesize updateDict = _updateDict;
@synthesize deleteDict = _deleteDict;

@synthesize recordRef = _recordRef;
@synthesize recordID = _recordID;
@synthesize age = _age;

#pragma mark - Class methods

+ (NSString *)defaultLabelForABPropertyID: (ABPropertyID)property
{
  if (property == kABPersonPhoneProperty)
  {
    return (__bridge NSString *)(kABPersonPhoneMobileLabel);
  }
  else if (property == kABPersonEmailProperty)
  {
    return (__bridge NSString *)(kABWorkLabel);
  }
  else if (property == kABPersonAddressProperty)
  {
    return (__bridge NSString *)(kABHomeLabel);
  }
  else if (property == kABPersonURLProperty)
  {
    return (__bridge NSString *)(kABPersonHomePageLabel);
  }
  else if (property == kABPersonDateProperty)
  {
    return (__bridge NSString *)(kABPersonAnniversaryLabel);
  }
  else if (property == kABPersonRelatedNamesProperty)
  {
    return (__bridge NSString *)(kABPersonMotherLabel);
  }
  else if (property == kABPersonSocialProfileProperty)
  {
    return (__bridge NSString *)(kABPersonSocialProfileServiceFacebook);
  }
  else
  {
    return (__bridge NSString *)(kABOtherLabel);
  }
}

+ (NSString *)defaultLocalizedLabelForABPropertyID: (ABPropertyID)property
{
  NSString *defaultLabel = [AKRecord defaultLabelForABPropertyID: property];
  return CFBridgingRelease(ABAddressBookCopyLocalizedLabel((__bridge CFStringRef)(defaultLabel)));
}

+ (NSString *)localizedNameForLabel: (CFStringRef)label
{
  return (NSString *)CFBridgingRelease(ABAddressBookCopyLocalizedLabel(label));
}

#pragma mark - Instance methods

- (id)initWithABRecordID: (ABRecordID) recordID andAddressBookRef: (ABAddressBookRef)addressBookRef
{
  self = [super init];
  if (self)
  {
    _recordID = NSNotFound;
  }
  return  self;
}

- (NSString *)description
{
  NSString *type = nil;
  switch ([self recordType])
  {
    case kABPersonType:
      type = @"Person";
      break;
    case kABGroupType:
      type = @"Group";
      break;
    case kABSourceType:
      type = @"Source";
      break;
  }
  return [NSString stringWithFormat: @"<AK%@ %p> %d", type, _recordRef, _recordID];
}

- (ABRecordType)recordType
{
  __block ABRecordType ret;

  if (self.recordRef == nil && self.recordID < 0) return kABGroupType; // Lazy init of recordRef

  dispatch_block_t block = ^{
		  ret = ABRecordGetRecordType(_recordRef);
	};

  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);

  return ret;
}

- (id)valueForProperty: (ABPropertyID)property
{
  if (self.recordRef == nil && self.recordID < 0) return nil; // Lazy init of recordRef

  __block id ret;

  dispatch_block_t block = ^{
    ret = (id)CFBridgingRelease(ABRecordCopyValue(_recordRef, property));
	};

  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);

  return ret;
}

- (void)setValue: (id)value forProperty: (ABPropertyID)property
{
  if (self.recordRef == nil && self.recordID < 0) return; // Lazy init of recordRef

  dispatch_block_t block = ^{
    CFErrorRef error = NULL;
    if (value == nil)
    {
      ABRecordRemoveValue(self.recordRef, property, &error);
    }
    else
    {
      ABRecordSetValue(self.recordRef, property, (__bridge CFTypeRef)(value), &error);
    }
    if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }
	};

  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);
}

- (NSInteger)countForProperty: (ABPropertyID) property
{  
  if (self.recordRef == nil && self.recordID < 0) return 0; // Lazy init of recordRef
  
  __block NSInteger ret = 0;
  
  dispatch_block_t block = ^{
    ABMultiValueRef multiValueRecord = (ABMultiValueRef)ABRecordCopyValue(_recordRef, property);
    if (multiValueRecord) {
      ret = ABMultiValueGetCount(multiValueRecord);
      CFRelease(multiValueRecord);
    }
  };

  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);

  return ret;
}

- (NSArray *)identifiersForProperty: (ABPropertyID) property
{
  if (self.recordRef == nil && self.recordID < 0) return nil; // Lazy init of recordRef
  
  __block NSArray *ret = nil;
  
  dispatch_block_t block = ^{
    ABMultiValueRef multiValueRecord =(ABMultiValueRef)ABRecordCopyValue(_recordRef, property);
    if (multiValueRecord) {
      NSInteger count = ABMultiValueGetCount(multiValueRecord);
      NSMutableArray *identifiers = [[NSMutableArray alloc] initWithCapacity: count];
      for (NSInteger i = 0; i < count; ++i) {
        NSInteger identifier = (NSInteger)ABMultiValueGetIdentifierAtIndex(multiValueRecord, i);
        [identifiers addObject: [NSNumber numberWithInteger: identifier]];
      }
      ret = [identifiers copy];
      CFRelease(multiValueRecord);
    }
  };
  
  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);

  return ret;
}

- (id)valueForMultiValueProperty: (ABPropertyID)property andIdentifier: (NSInteger)identifier
{
  if (self.recordRef == nil && self.recordID < 0) return nil; // Lazy init of recordRef
  
  __block id ret = nil;
  
  dispatch_block_t block = ^{
    ABMultiValueRef multiValueRecord = (ABMultiValueRef)ABRecordCopyValue(_recordRef, property);
    if (multiValueRecord)
    {
      CFIndex index = ABMultiValueGetIndexForIdentifier(multiValueRecord, (ABMultiValueIdentifier)identifier);
      if (index != -1)
      {
        ret = (id)CFBridgingRelease(ABMultiValueCopyValueAtIndex(multiValueRecord, index));
      }
      CFRelease(multiValueRecord);
    }
  };

  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);

  return ret;
}

- (NSString *)labelForMultiValueProperty: (ABPropertyID)property andIdentifier: (NSInteger)identifier
{
  if (self.recordRef == nil && self.recordID < 0) return nil; // Lazy init of recordRef
  
  __block NSString *ret = nil;
  
  dispatch_block_t block = ^{
    ABMultiValueRef multiValueRecord = (ABMultiValueRef)ABRecordCopyValue(_recordRef, property);
    if (multiValueRecord)
    {
      CFIndex index = ABMultiValueGetIndexForIdentifier(multiValueRecord, (ABMultiValueIdentifier)identifier);
      if (index != -1)
      {
        ret = (NSString *)CFBridgingRelease(ABMultiValueCopyLabelAtIndex(multiValueRecord, index));
      }
      CFRelease(multiValueRecord);
    }
  };
  
  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);
  
  return ret;
}

- (NSString *)localizedLabelForMultiValueProperty: (ABPropertyID)property andIdentifier: (NSInteger)identifier
{
  NSString *ret = [self labelForMultiValueProperty: property andIdentifier: identifier];
  if (ret == nil)
  {
    ret = [AKRecord defaultLocalizedLabelForABPropertyID: property];
  }
  else
  {
    ret = (NSString *)CFBridgingRelease(ABAddressBookCopyLocalizedLabel((__bridge CFStringRef)(ret)));
  }
  return ret;
}

- (void)setValue: (id)value andLabel: (NSString *)label forMultiValueProperty: (ABPropertyID)property andIdentifier: (NSInteger *)identifier
{
  if (self.recordRef == nil && self.recordID < 0) return; // Lazy init of recordRef
  
  dispatch_block_t block = ^{
    ABMultiValueRef record = (ABMultiValueRef)ABRecordCopyValue(_recordRef, property);
    ABMutableMultiValueRef mutableRecord = NULL;
    if (record != NULL)
    {
      mutableRecord = ABMultiValueCreateMutableCopy(record);
      CFRelease(record);
    }
    else
    {
      mutableRecord = ABMultiValueCreateMutable(ABPersonGetTypeOfProperty(property));
    }

    if (mutableRecord != NULL)
    {
      BOOL didChange = NO;
      CFIndex index = ABMultiValueGetIndexForIdentifier(mutableRecord, *identifier);
      if (index != -1)
      {
        if (value == nil)
        {
          didChange = ABMultiValueRemoveValueAndLabelAtIndex(mutableRecord, index);
        }
        else
        {
          didChange = ABMultiValueReplaceValueAtIndex(mutableRecord, (__bridge CFTypeRef)(value), index);
          ABMultiValueReplaceLabelAtIndex(mutableRecord, (__bridge CFStringRef)(label), index);
        }
      }
      else
      {
        didChange = ABMultiValueAddValueAndLabel(mutableRecord, (__bridge CFTypeRef)(value), (__bridge CFStringRef)(label), identifier);
      }
      if (didChange == YES)
      {
        CFErrorRef error = NULL;
        ABRecordSetValue(self.recordRef, property, mutableRecord, &error);
        if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }
      }
      CFRelease(mutableRecord);
    }
  };

  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);
}

@end
