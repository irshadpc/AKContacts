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

-(id)initWithABRecordID: (ABRecordID) recordID andAddressBookRef: (ABAddressBookRef)addressBookRef {
  self = [super init];
  if (self) {
    _recordID = NSNotFound;
  }
  return  self;
}

-(NSString *)description {
  NSString *type = nil;
  switch ([self recordType]) {
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

-(ABRecordType)recordType {
  __block ABRecordType ret;

  if (self.recordRef == nil && self.recordID < 0) return kABGroupType; // Lazy init of recordRef

  dispatch_block_t block = ^{
		  ret = ABRecordGetRecordType(_recordRef);
	};

  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);

  return ret;
}

-(id)valueForProperty: (ABPropertyID)property {

  if (self.recordRef == nil && self.recordID < 0) return nil; // Lazy init of recordRef

  __block id ret;

  dispatch_block_t block = ^{
    ret = (id)CFBridgingRelease(ABRecordCopyValue(_recordRef, property));
	};

  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);

  return ret;
}

-(void)setValue: (id)value forProperty: (ABPropertyID)property {

  if (self.recordID < 0) return; // Lazy init of recordRef

  dispatch_block_t block = ^{
    CFErrorRef error = NULL;
    ABRecordSetValue(self.recordRef, property, (__bridge CFTypeRef)(value), &error);
	};
  
  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);
}

-(NSInteger)countForProperty: (ABPropertyID) property {
  
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

-(NSArray *)identifiersForProperty: (ABPropertyID) property {

  if (self.recordRef == nil && self.recordID < 0) return nil; // Lazy init of recordRef
  
  __block NSArray *ret = nil;
  
  dispatch_block_t block = ^{
    ABMultiValueRef multiValueRecord =(ABMultiValueRef)ABRecordCopyValue(_recordRef, property);
    if (multiValueRecord) {
      NSInteger count = ABMultiValueGetCount(multiValueRecord);
      NSMutableArray *identifiers = [[NSMutableArray alloc] initWithCapacity: count];
      for (NSInteger i = 0; i < count; ++i) {
        NSInteger identifier = (NSInteger)ABMultiValueGetIdentifierAtIndex(multiValueRecord, i);
        [identifiers addObject: [NSNumber numberWithUnsignedInt: identifier]];
      }
      ret = [identifiers copy];
      CFRelease(multiValueRecord);
    }
  };
  
  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);

  return ret;
}

-(id)valueForMultiValueProperty: (ABPropertyID)property forIdentifier: (NSInteger)identifier {
  
  if (self.recordRef == nil && self.recordID < 0) return nil; // Lazy init of recordRef
  
  __block id ret = nil;
  
  dispatch_block_t block = ^{
    ABMultiValueRef multiValueRecord = (ABMultiValueRef)ABRecordCopyValue(_recordRef, property);
    if (multiValueRecord){
      CFIndex index = ABMultiValueGetIndexForIdentifier(multiValueRecord, (ABMultiValueIdentifier)identifier);
      if (index != -1) {
        ret = (id)CFBridgingRelease(ABMultiValueCopyValueAtIndex(multiValueRecord, index));
      }
      CFRelease(multiValueRecord);
    }
  };

  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);

  return ret;
}

-(NSString *)valueForMultiDictKey: (NSString *)key forIdentifier: (NSInteger)identifier {

  ABPropertyID property = [AKRecord propertyForMultiDictKey: key];

  NSDictionary *dict = [self valueForMultiValueProperty: property forIdentifier: identifier];

  return [dict objectForKey: key];
}

-(NSString *)labelForMultiValueProperty: (ABPropertyID)property forIdentifier: (NSInteger)identifier {
  
  if (self.recordRef == nil && self.recordID < 0) return nil; // Lazy init of recordRef
  
  __block NSString *ret = nil;
  
  dispatch_block_t block = ^{
    ABMultiValueRef multiValueRecord = (ABMultiValueRef)ABRecordCopyValue(_recordRef, property);
    if (multiValueRecord) {
      CFIndex index = ABMultiValueGetIndexForIdentifier(multiValueRecord, (ABMultiValueIdentifier)identifier);
      if (index != -1) {
        CFStringRef label = ABMultiValueCopyLabelAtIndex(multiValueRecord, index);
        ret = (NSString *)CFBridgingRelease(ABAddressBookCopyLocalizedLabel(label));
        CFRelease(label);
      }
      CFRelease(multiValueRecord);
    }
  };
  
  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);

  return ret;
}

+(ABPropertyID)propertyForMultiDictKey: (NSString*)key {

  ABPropertyID ret = kABPropertyInvalidID;

  if ([key isEqualToString: (NSString *)kABPersonAddressCityKey] ||
      [key isEqualToString: (NSString *)kABPersonAddressCountryCodeKey] ||
      [key isEqualToString: (NSString *)kABPersonAddressCountryKey] ||
      [key isEqualToString: (NSString *)kABPersonAddressStateKey] ||
      [key isEqualToString: (NSString *)kABPersonAddressStreetKey] ||
      [key isEqualToString: (NSString *)kABPersonAddressZIPKey]) {

    ret = kABPersonAddressProperty;

  } else if ([key isEqualToString: (NSString *)kABPersonInstantMessageServiceKey] ||
             [key isEqualToString: (NSString *)kABPersonInstantMessageUsernameKey]) {

    ret = kABPersonInstantMessageProperty;

  } else if ([key isEqualToString: (NSString *)kABPersonSocialProfileURLKey] ||
             [key isEqualToString: (NSString *)kABPersonSocialProfileServiceKey]) {

    ret = kABPersonSocialProfileProperty;

  }
  return ret;
}

#pragma mark - Update

-(void)createValue: (id)value forProperty: (ABPropertyID)property {

  if (!value) return;
  
  if (!self.createDict)
    [self setCreateDict: [[NSMutableDictionary alloc] init]];

  [self.createDict setObject: value forKey: [NSNumber numberWithInteger: property]];
}

-(void)createValue: (id)value forMultiValueProperty: (ABPropertyID)property forIdentifier: (NSInteger)identifier {

  if (!value) return;

  if (!self.createDict)
    [self setCreateDict: [[NSMutableDictionary alloc] init]];
  
  NSMutableDictionary *dict = [AKRecord mutableDictForProperty: property
                                                  forIdentifier: identifier
                                                  forDictionary: self.createDict];

  [dict setObject: [NSNumber numberWithInteger: identifier] forKey: kIdentifier];
  [dict setObject: value forKey: kValue];

}

-(void)createLabel: (NSString *)label forMultiValueProperty: (ABPropertyID)property forIdentifier: (NSInteger)identifier {
  
  if (!label) return;
  
  if (!self.createDict)
    [self setCreateDict: [[NSMutableDictionary alloc] init]];
  
  NSMutableDictionary *dict = [AKRecord mutableDictForProperty: property
                                                  forIdentifier: identifier
                                                  forDictionary: self.createDict];
  
  [dict setObject: [NSNumber numberWithInteger: identifier] forKey: kIdentifier];
  [dict setObject: label forKey: kLabel];
  
}

-(void)createValue: (id)value forMultiDictKey: (NSString *)key forIdentifier: (NSInteger)identifier {

  if (!value) return;

  if (!self.createDict)
    [self setCreateDict: [[NSMutableDictionary alloc] init]];

  ABPropertyID property = [AKRecord propertyForMultiDictKey: key];
  if (property == kABPropertyInvalidID) return;

  NSMutableDictionary *dict = [AKRecord mutableDictForProperty: property
                                             forIdentifier: identifier
                                             forDictionary: self.createDict];

  NSMutableDictionary *valueDict = [dict objectForKey: kValue];
  if (!valueDict) {
    valueDict = [[NSMutableDictionary alloc] init];
    [dict setObject: valueDict forKey: kValue];
  }
  [valueDict setObject: value forKey: key];

  [dict setObject: [NSNumber numberWithInteger: identifier] forKey: kIdentifier];
  

}

-(void)updateValue: (id)value forProperty: (ABPropertyID)property {
  
  if (!value) return;
  
  if (!self.updateDict)
    [self setUpdateDict: [[NSMutableDictionary alloc] init]];
  
  [self.updateDict setObject: value forKey: [NSNumber numberWithInteger: property]];
}

-(void)updateValue: (id)value forMultiValueProperty: (ABPropertyID)property forIdentifier: (NSInteger)identifier {

  if (!value) return;
  
  if (!self.updateDict)
    [self setUpdateDict: [[NSMutableDictionary alloc] init]];

  NSMutableDictionary *dict = [AKRecord mutableDictForProperty: property
                                                  forIdentifier: identifier
                                                  forDictionary: self.updateDict];

  [dict setObject: [NSNumber numberWithInteger: identifier] forKey: kIdentifier];
  [dict setObject: value forKey: kValue];

}

-(void)updateValue:(id)value forMultiDictKey: (NSString *)key forIdentifier: (NSInteger)identifier {

  if (!value) return;

  if (!self.updateDict)
    [self setUpdateDict: [[NSMutableDictionary alloc] init]];

  ABPropertyID property = [AKRecord propertyForMultiDictKey: key];
  if (property == kABPropertyInvalidID) return;

  NSMutableDictionary *dict = [AKRecord mutableDictForProperty: property
                                                  forIdentifier: identifier
                                                  forDictionary: self.updateDict];

  NSMutableDictionary *valueDict = [dict objectForKey: kValue];
  if (!valueDict) {
    valueDict = [[NSMutableDictionary alloc] init];
    [dict setObject: valueDict forKey: kValue];
  }
  [valueDict setObject: value forKey: key];
  
  [dict setObject: [NSNumber numberWithInteger: identifier] forKey: kIdentifier];

}

-(void)updateLabel: (NSString *)label forMultiValueProperty: (ABPropertyID)property forIdentifier: (NSInteger)identifier {

  if (!label) return;
  
  if (!self.updateDict)
    [self setUpdateDict: [[NSMutableDictionary alloc] init]];
  
  NSMutableDictionary *dict = [AKRecord mutableDictForProperty: property
                                                  forIdentifier: identifier
                                                  forDictionary: self.updateDict];
  
  [dict setObject: [NSNumber numberWithInteger: identifier] forKey: kIdentifier];
  [dict setObject: label forKey: kLabel];

}

-(void)deleteValueForProperty: (ABPropertyID)property {

  if (!self.deleteDict)
    [self setDeleteDict: [[NSMutableDictionary alloc] init]];

  [self.deleteDict setObject: @"" forKey: [NSNumber numberWithInteger: property]];

}

-(void)deleteValueForMultiValueProperty: (ABPropertyID)property forIdentifier: (NSInteger)identifier {

  if (!self.deleteDict)
    [self setDeleteDict: [[NSMutableDictionary alloc] init]];

  NSMutableDictionary *dict = [AKRecord mutableDictForProperty: property
                                                  forIdentifier: identifier
                                                  forDictionary: self.deleteDict];

  [dict setObject: [NSNumber numberWithInteger: identifier] forKey: kIdentifier];

}

-(void)commit {

  for (NSNumber *key in self.createDict) {

    ABPropertyID property = (ABPropertyID)[key integerValue];
    ABPropertyType type = ABPersonGetTypeOfProperty(property);
    id dictValue = [self.createDict objectForKey: key];

    switch (type) {
      case kABStringPropertyType:
      case kABDateTimePropertyType:

        ABRecordSetValue(_recordRef, property, (__bridge CFTypeRef)dictValue, NULL);
        break;

      case kABMultiStringPropertyType:
      case kABMultiDateTimePropertyType:
      case kABMultiDictionaryPropertyType: {

        ABMultiValueRef mutableMultiValue = [self mutableMultiValueForProperty: property];

        for (NSMutableDictionary *dict in (NSArray *)dictValue) {
          id value = [dict objectForKey: kValue];
          NSString *label = ([dict objectForKey: kLabel]) ? [dict objectForKey: kLabel] : (NSString *)kABOtherLabel;

          ABMultiValueAddValueAndLabel(mutableMultiValue,
                                       (__bridge CFTypeRef)value,
                                       (__bridge CFStringRef)label,
                                       NULL);
          ABRecordSetValue(_recordRef, property, mutableMultiValue, nil);

        }
        break;
      }
    }
  }

  for (NSNumber *key in self.updateDict) {
    
    ABPropertyID property = (ABPropertyID)[key integerValue];
    ABPropertyType type = ABPersonGetTypeOfProperty(property);
    id dictValue = [self.createDict objectForKey: key];
    
    switch (type) {
      case kABStringPropertyType:
      case kABDateTimePropertyType:

        ABRecordSetValue(_recordRef, property, (__bridge CFTypeRef)dictValue, NULL);
        break;

      case kABMultiStringPropertyType:
      case kABMultiDateTimePropertyType: {

        ABMultiValueRef mutableMultiValue = [self mutableMultiValueForProperty: property];

        for (NSMutableDictionary *dict in (NSArray *)dictValue) {

          id value = [dict objectForKey: kValue];
          NSString *label = [dict objectForKey: kLabel];

          ABMultiValueIdentifier identifier = [[dict objectForKey: kIdentifier] integerValue];
          CFIndex index = ABMultiValueGetIndexForIdentifier(mutableMultiValue, identifier);

          if (index != -1) {
            ABMultiValueReplaceValueAtIndex(mutableMultiValue,
                                            (__bridge CFTypeRef)value,
                                            index);
            if ([label length] > 0) {
              ABMultiValueReplaceLabelAtIndex(mutableMultiValue, (__bridge CFTypeRef)label, index);
            }
          }
          ABRecordSetValue(_recordRef, property, mutableMultiValue, nil);

        }
        break;
      }

      case kABMultiDictionaryPropertyType: {

        ABMultiValueRef mutableMultiValue = [self mutableMultiValueForProperty: property];

        for (NSMutableDictionary *dict in (NSArray *)dictValue) {

          NSString *label = ([dict objectForKey: kLabel]) ? [dict objectForKey: kLabel] : (NSString *)kABOtherLabel;
          NSMutableDictionary *newValuesDict = [dict objectForKey: kValue];

          ABMultiValueIdentifier identifier = [[dict objectForKey: kIdentifier] integerValue];
          CFIndex index = ABMultiValueGetIndexForIdentifier(mutableMultiValue, identifier);
          
          if (index != -1) {
            CFTypeRef dict = ABMultiValueCopyValueAtIndex(mutableMultiValue, index);
            NSMutableDictionary *oldValuesDict = [(__bridge NSDictionary *)dict mutableCopy];
            CFRelease(dict);
            [oldValuesDict addEntriesFromDictionary: newValuesDict];

            if ([label length] > 0) {
              ABMultiValueReplaceLabelAtIndex(mutableMultiValue, (__bridge CFTypeRef)label, index);
            }
          }
        }

        ABRecordSetValue(_recordRef, property, mutableMultiValue, nil);

        break;
      }
    }
    
  }

  for (NSNumber *key in self.deleteDict) {

    ABPropertyID property = (ABPropertyID)[key integerValue];
    ABPropertyType type = ABPersonGetTypeOfProperty(property);
    id dictValue = [self.createDict objectForKey: key];

    switch (type) {
      case kABStringPropertyType:
      case kABDateTimePropertyType:

        ABRecordRemoveValue(_recordRef, property, NULL);
        break;
        
      case kABMultiStringPropertyType:
      case kABMultiDateTimePropertyType:
      case kABMultiDictionaryPropertyType: {

        ABMultiValueRef mutableMultiValue = [self mutableMultiValueForProperty: property];

        for (NSMutableDictionary *dict in (NSArray *)dictValue) {

          ABMultiValueIdentifier identifier = [[dict objectForKey: kIdentifier] integerValue];
          CFIndex index = ABMultiValueGetIndexForIdentifier(mutableMultiValue, identifier);

          if (index != -1) {
            ABMultiValueRemoveValueAndLabelAtIndex(mutableMultiValue, index);
          }
          ABRecordSetValue(_recordRef, property, mutableMultiValue, nil);

        }
        break;
      }        
    }
  }

  [self setCreateDict: nil];
  [self setUpdateDict: nil];
  [self setDeleteDict: nil];
}

-(void)revert {
  [self setCreateDict: nil];
  [self setUpdateDict: nil];
  [self setDeleteDict: nil];
}

#pragma mark - Helper Methods

-(ABMutableMultiValueRef)mutableMultiValueForProperty: (ABPropertyID)property {

  ABMutableMultiValueRef mutableMultiValue = NULL;
  ABMultiValueRef multiValue = (ABMultiValueRef)ABRecordCopyValue(_recordRef, property);
  if (multiValue) {
    mutableMultiValue = ABMultiValueCreateMutableCopy(multiValue);
    CFRelease(multiValue);
  } else {
    mutableMultiValue = ABMultiValueCreateMutable(ABPersonGetTypeOfProperty(property));
  }
  return (__bridge ABMutableMultiValueRef)(CFBridgingRelease(mutableMultiValue));
}

+(NSMutableDictionary *)mutableDictForProperty: (ABPropertyID)property
                                 forIdentifier: (NSInteger)identifier
                                 forDictionary: (NSMutableDictionary *)dictionary {
  NSMutableDictionary *ret = nil;

  NSNumber *propertyKey = [NSNumber numberWithInteger: property];

  // Locate the array for the given property
  NSMutableArray *array = [dictionary objectForKey: propertyKey];
  if (!array) {
    array = [[NSMutableArray alloc] init];
    [dictionary setObject: array forKey: propertyKey];
  }

  // Locate the dictionary in the array
  for (NSMutableDictionary *dict in array) {
    NSNumber *nIdentifier = [dict objectForKey: kIdentifier];
    if ([nIdentifier integerValue] == identifier) {
      ret = dict;
      break;
    }
    
  }
  if (!ret) { // If dictionary is not found, put it in
    ret = [[NSMutableDictionary alloc] init];
    [array addObject: ret];
  }
  
  return ret;
}


@end
