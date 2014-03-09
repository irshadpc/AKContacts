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
#import "AKLabel.h"

@interface AKRecord ()

@end

@implementation AKRecord

#pragma mark - Instance methods

- (instancetype)initWithABRecordID: (ABRecordID) recordID andRecordType: (ABRecordType)recordType
{
  self = [super init];
  if (self)
  {
    _recordID = recordID;
    _recordType = recordType;
  }
  return  self;
}

- (ABRecordRef)recordRef
{
  __block ABRecordRef ret = NULL;

  dispatch_block_t block = ^{
    if (self.recordID >= 0)
    {
      ABAddressBookRef addressBookRef = [[AKAddressBook sharedInstance] addressBookRef];
      switch (self.recordType) {
        case kABPersonType:
          ret = ABAddressBookGetPersonWithRecordID(addressBookRef, self.recordID);
          break;
        case kABGroupType:
          ret = ABAddressBookGetGroupWithRecordID(addressBookRef, self.recordID);
          break;
        case kABSourceType:
          ret = ABAddressBookGetSourceWithRecordID(addressBookRef, self.recordID);
          break;
      }
    }
  };

  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);

  return ret;
}

- (NSString *)description
{
  NSString *type = nil;
  switch (self.recordType)
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
  return [NSString stringWithFormat: @"<AK%@ %p> %d", type, self.recordRef, self.recordID];
}

- (id)valueForProperty: (ABPropertyID)property
{
  if (self.recordID < 0) return nil;

  __block id ret;

  dispatch_block_t block = ^{
    ret = (id)CFBridgingRelease(ABRecordCopyValue(self.recordRef, property));
  };

  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);

  return ret;
}

- (void)setValue: (id)value forProperty: (ABPropertyID)property
{
  if (self.recordID < 0) return;

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
  if (self.recordID < 0) return 0;

  __block NSInteger ret = 0;
  
  dispatch_block_t block = ^{
    ABMultiValueRef multiValueRecord = (ABMultiValueRef)ABRecordCopyValue(self.recordRef, property);
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
  if (self.recordID < 0) return nil;
  
  __block NSArray *ret = nil;
  
  dispatch_block_t block = ^{
    ABMultiValueRef multiValueRecord =(ABMultiValueRef)ABRecordCopyValue(self.recordRef, property);
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
  if (self.recordID < 0) return nil;

  __block id ret = nil;
  
  dispatch_block_t block = ^{
    ABMultiValueRef multiValueRecord = (ABMultiValueRef)ABRecordCopyValue(self.recordRef, property);
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
  if (self.recordID < 0) return nil;
  
  __block NSString *ret = nil;
  
  dispatch_block_t block = ^{

    ABMultiValueRef multiValueRecord = (ABMultiValueRef)ABRecordCopyValue(self.recordRef, property);
    if (multiValueRecord)
    {
      CFIndex index = ABMultiValueGetIndexForIdentifier(multiValueRecord, (ABMultiValueIdentifier)identifier);
      if (index != -1)
      {
        ret = (NSString *)CFBridgingRelease(ABMultiValueCopyLabelAtIndex(multiValueRecord, index));
      }
      else
      {
        ret = [AKLabel defaultLabelForABPropertyID: property];
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
      ret = [AKLabel defaultLocalizedLabelForABPropertyID: property];
  }
  else
  {
    ret = (NSString *)CFBridgingRelease(ABAddressBookCopyLocalizedLabel((__bridge CFStringRef)(ret)));
  }
  return ret;
}

- (void)setValue: (id)value andLabel: (NSString *)label forMultiValueProperty: (ABPropertyID)property andIdentifier: (NSInteger *)identifier
{
  if (self.recordID < 0) return;
  
  dispatch_block_t block = ^{
    ABMultiValueRef record = (ABMultiValueRef)ABRecordCopyValue(self.recordRef, property);
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
