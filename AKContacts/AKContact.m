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
#import "AKAddressBook+Loader.h"
#import "AKGroup.h"
#import "AKSource.h"

const int newContactID = -1<<9;

@interface AKContact ()

@end

@implementation AKContact

- (instancetype)initWithABRecordID: (ABRecordID) recordID sortOrdering: (ABPersonSortOrdering)sortOrdering andAddressBookRef: (ABAddressBookRef)addressBookRef
{
    self = [super initWithABRecordID: recordID recordType: kABPersonType andAddressBookRef: addressBookRef];
    if (self)
    {
      _sortOrdering = sortOrdering;
    }
    return  self;
}

- (ABRecordRef)recordRef
{
  ABRecordRef ret;

  AKAddressBook *addressBook = [AKAddressBook sharedInstance];
  ABRecordID recordID = super.recordID;
  if (recordID == newContactID)
  {
    AKSource *source = [addressBook sourceForSourceId: addressBook.sourceID];

    [[AKAddressBook sharedInstance] setNeedReload: NO];

    ABRecordRef recordRef = ABPersonCreateInSource((source.recordID >= 0) ? source.recordRef : NULL);

    CFErrorRef error = NULL;
    ABAddressBookAddRecord(super.addressBookRef, recordRef, &error);
    if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }

    ABAddressBookSave(super.addressBookRef, &error);
    if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }

    // Do not set super.recordID here!
    recordID = ABRecordGetRecordID(recordRef);
    CFRelease(recordRef); // Do not leak
  }
  ret = ABAddressBookGetPersonWithRecordID(super.addressBookRef, recordID);
  super.age = [NSDate date];

  return ret;
}

- (NSString *)searchName
{
  return self.sortName.stringWithDiacriticsRemoved;
}

- (NSString *)sortName
{
    NSString *ret = nil;

    if ([self.kind isEqualToNumber: (NSNumber *)kABPersonKindPerson])
    {
        NSString *first = [self valueForProperty: kABPersonFirstNameProperty];
        NSString *last = [self valueForProperty: kABPersonLastNameProperty];

        if (kABPersonSortByFirstName == self.sortOrdering)
        {
            ret = [NSString stringWithFormat: @"%@%@%@", first, self.nameDelimiter, last];
        }
        else
        {
            ret = [NSString stringWithFormat: @"%@%@%@", last, self.nameDelimiter, first];
        }
    }
    else if ([self.kind isEqualToNumber: (NSNumber *)kABPersonKindOrganization])
    {
        ret = [self valueForProperty: kABPersonOrganizationProperty];
    }
    return ret;
}

- (NSString *)compositeName
{
  NSString *ret = nil;

  if ([self.kind isEqualToNumber: (NSNumber *)kABPersonKindPerson])
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

    if (array.count)
    {
        ret = [array componentsJoinedByString: self.nameDelimiter];
    }
  }
  else if ([self.kind isEqualToNumber: (NSNumber *)kABPersonKindOrganization])
  {
    ret = [self valueForProperty: kABPersonOrganizationProperty];
  }
  return ret;
}

- (NSString *)phoneticName
{
  NSString *ret = nil;

  if ([self.kind isEqualToNumber: (NSNumber *)kABPersonKindPerson])
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
  else if ([self.kind isEqualToNumber: (NSNumber *)kABPersonKindOrganization])
  {
    ret = [self valueForProperty: kABPersonOrganizationProperty];
  }
  return ret;
}

- (NSString *)nameDelimiter
{
    return (NSString *)CFBridgingRelease(ABPersonCopyCompositeNameDelimiterForRecord(self.recordRef));
}

- (NSString *)displayDetails
{
  NSString *ret = nil;
  
  if ([self.kind isEqualToNumber: (NSNumber *)kABPersonKindOrganization])
  {
    ret = [self valueForProperty: kABPersonDepartmentProperty];
  }
  else if ([self.kind isEqualToNumber: (NSNumber *)kABPersonKindPerson])
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

- (NSNumber *)kind
{
  return (NSNumber *)[self valueForProperty: kABPersonKindProperty];
}

- (NSArray *)linkedContactIDs
{
  NSMutableArray *ret = [[NSMutableArray alloc] init];

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
  return [ret copy];
}

- (NSData *)imageData
{
  NSData *ret = nil;

  if (ABPersonHasImageData([self recordRef]))
  {
    ret = (NSData *)CFBridgingRelease(ABPersonCopyImageDataWithFormat(self.recordRef, kABPersonImageFormatThumbnail));
  }
  return ret;
}

- (void)setImageData: (NSData *)pictureData
{
  CFErrorRef error = NULL; // Remove first to update full and thumbnail image
  ABPersonRemoveImageData([self recordRef], &error);
  if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }
  if (pictureData)
  {
    ABPersonSetImageData([self recordRef], (__bridge CFDataRef)pictureData, &error);
    if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }
  }
}

- (UIImage *)image
{
  UIImage *ret = nil;
  NSData *data = [self imageData];
  if (data)
  {
    ret = [UIImage imageWithData: data];
  }
  else
  {
    NSString *imageName = ([self.kind isEqualToNumber: (NSNumber *)kABPersonKindOrganization]) ? @"Company.png" : @"Contact.png";
    ret = [UIImage imageNamed: imageName];
  }
  return ret;
}

- (NSString *)addressForIdentifier: (ABMultiValueIdentifier)identifier andNumRows: (NSInteger *)numRows
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

- (NSString *)instantMessageDescriptionForIdentifier: (ABMultiValueIdentifier)identifier
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
  if (ABAddressBookHasUnsavedChanges(super.addressBookRef))
  {
    [[AKAddressBook sharedInstance] setNeedReload: NO];

    CFErrorRef error = NULL;
    ABAddressBookSave(super.addressBookRef, &error);
    if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }
  }

  if (self.recordID == newContactID)
  {
    super.recordID = ABRecordGetRecordID(self.recordRef);

    AKAddressBook *addressBook = [AKAddressBook sharedInstance];

    [addressBook insertRecordIDinContactIdentifiersForContact: self];

    if (addressBook.groupID >= 0)
    { // Add to group
      AKSource *source = [addressBook sourceForSourceId: addressBook.sourceID];
      AKGroup *group = [source groupForGroupId: addressBook.groupID];
      [group insertMemberWithID: self.recordID];
    }
  }
}

- (void)revert
{
  if (self.recordID == newContactID)
  {
    [[AKAddressBook sharedInstance] setNeedReload: NO];

    CFErrorRef error = NULL;
    ABAddressBookRemoveRecord(super.addressBookRef, self.recordRef, &error);
    if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }

    ABAddressBookSave(super.addressBookRef, &error);
    if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }
  }

  if (ABAddressBookHasUnsavedChanges(super.addressBookRef))
  {
    ABAddressBookRevert(super.addressBookRef);
  }
}

#pragma mark - Searching

- (NSInteger)numberOfMatchingTerms: (NSArray *)terms
{
    NSInteger termsMatched = 0;
    if (self.recordRef)
    {
        if ([self.kind isEqualToNumber: (NSNumber *)kABPersonKindPerson])
        {
            void(^setBit)(NSInteger *, NSInteger) = ^(NSInteger *byte, NSInteger bit) { *byte |= 1 << bit; };
            BOOL(^isBitSet)(NSInteger *, NSInteger) = ^(NSInteger *byte, NSInteger bit) { return (BOOL)(*byte & (1 << bit)); };

            NSArray *properties = @[@(kABPersonFirstNameProperty), @(kABPersonLastNameProperty), @(kABPersonMiddleNameProperty)];

            NSInteger termBitmask = 0, nameBitmask = 0;
            for (NSInteger i = 0; i < terms.count; ++i)
            {
                NSString *term = [[terms objectAtIndex: i] lowercaseString];
                for (NSInteger j = 0; j < properties.count; ++j)
                {
                    ABPropertyID property = [properties[j] intValue];
                    NSString *value = [self valueForProperty: property];
                    value = value.stringWithDiacriticsRemoved;
                    if ([value.lowercaseString hasPrefix: term] && !isBitSet(&termBitmask, i) && !isBitSet(&nameBitmask, j))
                    {
                        termsMatched += 1;
                        setBit(&termBitmask, i);
                        setBit(&nameBitmask, j);
                    }
                }
            }
        }
        else if ([self.kind isEqualToNumber: (NSNumber *)kABPersonKindOrganization])
        {
            NSString *name = [self valueForProperty: kABPersonOrganizationProperty];
            if ([name.stringWithDiacriticsRemoved.lowercaseString hasPrefix: [terms.lastObject lowercaseString]])
            {
                termsMatched += 1;
            }
        }
    }
    return termsMatched;
}

- (NSInteger)numberOfPhoneNumbersMatchingTerms: (NSArray *)terms
{
    NSArray *(^digitsTerms)(NSArray *) = ^(NSArray *terms) {
        NSMutableArray *digitTerms = [[NSMutableArray alloc] init];
        for (NSString *term in terms)
        {
            if (term.stringWithNonDigitsRemoved.length > 0)
            {
                [digitTerms addObject: term];
            }
        }
        return [digitTerms copy];
    };
    
    NSInteger termsMatched = 0;
    terms = digitsTerms(terms);
    if (terms.count > 0)
    {
        if (self.recordRef)
        {
            NSArray *identifiers = [self identifiersForProperty: kABPersonPhoneProperty];
            if (identifiers.count)
            {
                for (NSNumber *identifier in identifiers)
                {
                    NSString *value = [self valueForMultiValueProperty: kABPersonPhoneProperty andIdentifier: identifier.intValue];
                    NSString *digits = value.stringWithNonDigitsRemoved;
                    if (digits.length > 0)
                    {
                        for (NSString *term in terms)
                        {
                            if (term.stringWithNonDigitsRemoved.length == 0)
                            {
                                continue;
                            }
                            if ([digits hasPrefix: term] || [value hasPrefix: term])
                            {
                                termsMatched += 1;
                                break;
                            }
                            for (NSString *prefix in [AKAddressBook prefixesToDiscardOnSearch])
                            {
                                if ([digits hasPrefix: prefix])
                                {
                                    digits = [digits substringFromIndex: prefix.length];
                                    if (digits.length > 0 && [digits hasPrefix: term])
                                    {
                                        termsMatched += 1;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return (termsMatched > 0) ? 1 : 0;
}

#pragma mark - Class methods

- (NSString *)sectionKeyForName: (NSString *)name
{
  NSString *sectionKey = @"#";
  if (name.length)
  {
    NSString *key = [[[[name substringToIndex: 1] decomposedStringWithCanonicalMapping] substringToIndex: 1] uppercaseString];
    if (isalpha([key characterAtIndex: 0])) sectionKey = key;
  }
  return sectionKey;
}

- (NSString *)nameToDetermineSectionForSortOrdering: (ABPersonSortOrdering)sortOrdering
{
    NSString *name;
    if ([self.kind isEqualToNumber: (NSNumber *)kABPersonKindPerson])
    {
        ABPropertyID property = (sortOrdering == kABPersonSortByFirstName) ? kABPersonFirstNameProperty : kABPersonLastNameProperty;
        name = [self valueForProperty: property];
        if (!name.length)
        {
            property = (property == kABPersonFirstNameProperty) ? kABPersonLastNameProperty : kABPersonFirstNameProperty;
            name = [self valueForProperty: property];
        }
    }
    else if ([self.kind isEqualToNumber: (NSNumber *)kABPersonKindOrganization])
    {
        name = [self valueForProperty: kABPersonOrganizationProperty];
    }
    return name;
}

@end
