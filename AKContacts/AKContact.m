//
//  AKContact.m
//
//  Copyright 2013 (c) Adam Kornafeld All rights reserved.
//

#import "AKContact.h"
#import "AddressBookManager.h"
#import "AppDelegate.h"

@interface AKContact ()

@end


@implementation AKContact

-(NSString *)displayName {
  return (NSString *)CFBridgingRelease(ABRecordCopyCompositeName(super.record)); // kABStringPropertyType
}

-(NSString *)searchName {
  NSString *ret = [self displayName];
  ret = [ret stringByFoldingWithOptions: NSDiacriticInsensitiveSearch locale: [NSLocale currentLocale]];
  return [ret stringByReplacingOccurrencesOfString: @" " withString: @""];
}

-(NSString *)displayNameByOrdering: (ABPersonSortOrdering)ordering {

  NSString *ret = nil;
  NSInteger kind = [(NSNumber *)[self valueForProperty: kABPersonKindProperty] integerValue];

  if (kind == [(NSNumber *)kABPersonKindPerson integerValue]) {

    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSString *prefix = [self valueForProperty: kABPersonPrefixProperty];
    if (prefix) [array addObject: prefix];

    NSString *last = [self valueForProperty: kABPersonLastNameProperty];
    NSString *first = [self valueForProperty: kABPersonFirstNameProperty];
    NSString *middle = [self valueForProperty: kABPersonMiddleNameProperty];

    if (ordering == kABPersonSortByFirstName) {

      if (first) [array addObject: first];
      if (middle) [array addObject: middle];
      if (last) [array addObject: last];
      
    } else {
      
      if (last) [array addObject: last];
      if (first) [array addObject: first];
      if (middle) [array addObject: middle];
      
    }

    NSString *suffix = [self valueForProperty: kABPersonSuffixProperty];
    if (suffix) [array addObject: suffix];

    ret = [array componentsJoinedByString: @" "];

  } else if (kind == [(NSNumber *)kABPersonKindOrganization integerValue]) {
    ret = [self valueForProperty: kABPersonOrganizationProperty];
  }
  return ret;
}

-(NSString *)phoneticNameByOrdering: (ABPersonSortOrdering)ordering {

  NSString *ret = nil;
  NSInteger kind = [(NSNumber *)[self valueForProperty: kABPersonKindProperty] integerValue];

  if (kind == [(NSNumber *)kABPersonKindPerson integerValue]) {

    NSMutableArray *array = [[NSMutableArray alloc] init];

    NSString *last = [self valueForProperty: kABPersonLastNamePhoneticProperty];
    NSString *middle = [self valueForProperty: kABPersonMiddleNamePhoneticProperty];
    NSString *first = [self valueForProperty: kABPersonFirstNamePhoneticProperty];

    if (ordering == kABPersonSortByFirstName) {

      if (first) [array addObject: first];
      if (middle) [array addObject: middle];
      if (last) [array addObject: last];

    } else {

      if (last) [array addObject: last];
      if (first) [array addObject: first];
      if (middle) [array addObject: middle];

    }

    ret = [array componentsJoinedByString: @" "];

  } else if (kind == [(NSNumber *)kABPersonKindOrganization integerValue]) {
    ret = [self valueForProperty: kABPersonOrganizationProperty];
  }
  return ret;
}

-(NSString *)displayDetails {
  
  NSString *ret = nil;
  NSInteger kind = [(NSNumber *)[self valueForProperty: kABPersonKindProperty] integerValue];
  
  if (kind == [(NSNumber *)kABPersonKindOrganization integerValue]) {
    
    ret = [self valueForProperty: kABPersonDepartmentProperty];

  } else if (kind == [(NSNumber *)kABPersonKindPerson integerValue]) {

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

-(NSString *)dictionaryKey {
  return [self dictionaryKeyBySortOrdering: ABPersonGetSortOrdering()];
}

-(NSString *)dictionaryKeyBySortOrdering: (ABPersonSortOrdering)ordering {

  NSString *ret = @"#";
  if ([[self displayNameByOrdering: ordering] length] > 0) {

    NSString *key = [[[[[self displayNameByOrdering: ordering] substringToIndex: 1]
                                 decomposedStringWithCanonicalMapping] substringToIndex: 1] uppercaseString];
    if (isalpha([key characterAtIndex: 0]))
      ret = key;
  }
  return ret;
}

-(NSData*)pictureData{
  
  NSData *ret = nil;
  if (ABPersonHasImageData(super.record)) {
    ret = (NSData *)CFBridgingRelease(ABPersonCopyImageDataWithFormat(super.record, kABPersonImageFormatThumbnail));
  }
  return ret;
}

-(UIImage *)picture {
  
  UIImage *ret = nil;
  NSData *data = [self pictureData];
  if (data) {
    ret = [UIImage imageWithData: [self pictureData]];
  } else {
    NSInteger kind = [(NSNumber *)[self valueForProperty: kABPersonKindProperty] integerValue];
    ret = [UIImage imageNamed: (kind == [(NSNumber *)kABPersonKindOrganization integerValue]) ? @"Company.png" : @"Contact"];
  }
  return ret;
}

-(NSComparisonResult)compareByName:(AKContact *)otherContact {
  return [self.displayName localizedCaseInsensitiveCompare: otherContact.displayName];
}

@end
