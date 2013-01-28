//
//  AKRecord.m
//
//  Copyright 2013 (c) Adam Kornafeld All rights reserved.
//

#import "AKRecord.h"

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

@synthesize record = _record;
@synthesize recordID = _recordID;

-(id)initWithABRecordRef: (ABRecordRef) aRecord {
  self = [super init];
  if (self) {
    _record = aRecord;
    _recordID = ABRecordGetRecordID(aRecord);
  }
  return  self;
}

-(id)valueForProperty: (ABPropertyID)property {
  return (__bridge id)ABRecordCopyValue(self.record, property);
}

-(NSInteger)countForProperty: (ABPropertyID) property {
  
  NSInteger ret = 0;
  ABMultiValueRef multiValueRecord = (ABMultiValueRef)ABRecordCopyValue(self.record, property);
  if (multiValueRecord) {
    ret = ABMultiValueGetCount(multiValueRecord);
    CFRelease(multiValueRecord);
  }
  return ret;
}

-(NSArray *)identifiersForProperty: (ABPropertyID) property {

  NSArray *ret = nil;
  ABMultiValueRef multiValueRecord =(ABMultiValueRef)ABRecordCopyValue(self.record, property);
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
  return ret;
}

-(id)valueForMultiValueProperty: (ABPropertyID)property forIdentifier: (NSInteger)identifier {
  
  id ret = nil;
  ABMultiValueRef multiValueRecord = (ABMultiValueRef)ABRecordCopyValue(self.record, property);
  if (multiValueRecord){
    CFIndex index = ABMultiValueGetIndexForIdentifier(multiValueRecord, (ABMultiValueIdentifier)identifier);
    if (index != -1) {
      ret = (__bridge id)ABMultiValueCopyValueAtIndex(multiValueRecord, index);
    }
  }
  return ret;
}

-(NSString *)valueForMultiDictKey: (NSString *)key forIdentifier: (NSInteger)identifier {

  ABPropertyID property = [AKRecord propertyForMultiDictKey: key];

  NSDictionary *dict = [self valueForMultiValueProperty: property forIdentifier: identifier];

  return [dict objectForKey: key];
}

-(NSString *)labelForMultiValueProperty: (ABPropertyID)property forIdentifier: (NSInteger)identifier {
  
  NSString *ret = nil;
  ABMultiValueRef multiValueRecord = (ABMultiValueRef)ABRecordCopyValue(self.record, property);
  if (multiValueRecord) {
    CFIndex index = ABMultiValueGetIndexForIdentifier(multiValueRecord, (ABMultiValueIdentifier)identifier);
    if (index != -1) {
      ret = (__bridge NSString *)ABAddressBookCopyLocalizedLabel(ABMultiValueCopyLabelAtIndex(multiValueRecord, index));
    }
  }
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

-(void)commitWithAddressBook: (ABAddressBookRef)addressBook {

  CFErrorRef error = NULL;
  if (ABAddressBookHasUnsavedChanges(addressBook)) {
    ABAddressBookSave(addressBook, &error);
    if (error) NSLog(@"%@", error);
  }

  for (NSNumber *key in self.createDict) {

    ABPropertyID property = (ABPropertyID)[key integerValue];
    ABPropertyType type = ABPersonGetTypeOfProperty(property);
    id dictValue = [self.createDict objectForKey: key];

    switch (type) {
      case kABStringPropertyType:
      case kABDateTimePropertyType:

        ABRecordSetValue(self.record, property, (__bridge CFTypeRef)dictValue, NULL);
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
          ABRecordSetValue(self.record, property, mutableMultiValue, nil);
          CFRelease(mutableMultiValue);

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

        ABRecordSetValue(self.record, property, (__bridge CFTypeRef)dictValue, NULL);
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
          ABRecordSetValue(self.record, property, mutableMultiValue, nil);
          CFRelease(mutableMultiValue);

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
            NSMutableDictionary *oldValuesDict = [(__bridge NSDictionary *)ABMultiValueCopyValueAtIndex(mutableMultiValue, index) mutableCopy];
            [oldValuesDict addEntriesFromDictionary: newValuesDict];

            if ([label length] > 0) {
              ABMultiValueReplaceLabelAtIndex(mutableMultiValue, (__bridge CFTypeRef)label, index);
            }
          }
        }

        ABRecordSetValue(self.record, property, mutableMultiValue, nil);
        CFRelease(mutableMultiValue);

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

        ABRecordRemoveValue(self.record, property, NULL);
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
          ABRecordSetValue(self.record, property, mutableMultiValue, nil);
          CFRelease(mutableMultiValue);

        }
        break;
      }        
    }
  }

  [self setCreateDict: nil];
  [self setUpdateDict: nil];
  [self setDeleteDict: nil];
}

-(void)revertWithAddressBook: (ABAddressBookRef)addressBook {
  [self setCreateDict: nil];
  [self setUpdateDict: nil];
  [self setDeleteDict: nil];
}

#pragma mark - Helper Methods

-(ABMultiValueRef)mutableMultiValueForProperty: (ABPropertyID)property {

  ABMultiValueRef mutableMultiValue = NULL;
  ABMultiValueRef multiValue = (ABMultiValueRef)ABRecordCopyValue(self.record, property);
  if (multiValue) {
    mutableMultiValue = ABMultiValueCreateMutableCopy(multiValue);
    CFRelease(multiValue);
  } else {
    mutableMultiValue = ABMultiValueCreateMutable(ABPersonGetTypeOfProperty(property));
  }
  return mutableMultiValue;
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
  for (int i = 0; i < [array count]; i++) {
    NSNumber *nIdentifier = [[array objectAtIndex: i] objectForKey: kIdentifier];
    if ([nIdentifier integerValue] == identifier) {
      ret = [array objectAtIndex: i];
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
