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

@implementation AKRecord

#pragma mark - Instance methods

- (instancetype)initWithABRecordID: (ABRecordID) recordID recordType: (ABRecordType)recordType andAddressBookRef: (ABAddressBookRef)addressBookRef
{
    self = [super init];
    if (self)
    {
        _recordID = recordID;
        _recordType = recordType;
        _addressBookRef = addressBookRef;
    }
    return  self;
}

- (ABRecordRef)recordRef
{
    ABRecordRef ret = NULL;
    
    if (self.recordID >= 0)
    {
        switch (self.recordType) {
            case kABPersonType:
                ret = ABAddressBookGetPersonWithRecordID(self.addressBookRef, self.recordID);
                break;
            case kABGroupType:
                ret = ABAddressBookGetGroupWithRecordID(self.addressBookRef, self.recordID);
                break;
            case kABSourceType:
                ret = ABAddressBookGetSourceWithRecordID(self.addressBookRef, self.recordID);
                break;
        }
    }
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
    
    return (id)CFBridgingRelease(ABRecordCopyValue(self.recordRef, property));
}

- (void)setValue: (id)value forProperty: (ABPropertyID)property
{
    if (self.recordID < 0) return;
    
    CFErrorRef error = NULL;
    if (value == nil)
    {
        ABRecordRemoveValue(self.recordRef, property, &error);
    }
    else
    {
        ABRecordSetValue(self.recordRef, property, (__bridge CFTypeRef)(value), &error);
    }
    if (error) { CFStringRef desc = CFErrorCopyDescription(error); NSLog(@"ABAddressBookRemoveRecord/ABRecordSetValue (%ld): %@", CFErrorGetCode(error), desc); CFRelease(desc); error = NULL; }
}

- (NSInteger)countForMultiValueProperty: (ABPropertyID) property
{
    if (self.recordID < 0) return 0;
    
    NSInteger count = 0;
    if ([AKRecord isMultiValueProperty: property])
    {
        ABMultiValueRef multiValueRecord = (ABMultiValueRef)ABRecordCopyValue(self.recordRef, property);
        if (multiValueRecord) {
            count = ABMultiValueGetCount(multiValueRecord);
            CFRelease(multiValueRecord);
        }
    }
    return count;
}

- (NSArray *)identifiersForMultiValueProperty: (ABPropertyID)property
{
    if (self.recordID < 0) return nil;
    
    NSArray *ret;
    
    if ([AKRecord isMultiValueProperty: property])
    {
        ABMultiValueRef multiValueRecord = (ABMultiValueRef)ABRecordCopyValue(self.recordRef, property);
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
    }
    return ret;
}

- (NSInteger)countForLinkedMultiValueProperty: (ABPropertyID) property
{
    NSInteger count = 0;
    if ([AKRecord isMultiValueProperty: property])
    {
        NSArray *linkedRecords = (NSArray *)CFBridgingRelease(ABPersonCopyArrayOfAllLinkedPeople([self recordRef]));
        for (id obj in linkedRecords)
        {
            ABRecordRef recordRef = (__bridge ABRecordRef)obj;
            ABMultiValueRef multiValueRecord = (ABMultiValueRef)ABRecordCopyValue(recordRef, property);
            if (multiValueRecord) {
                count += ABMultiValueGetCount(multiValueRecord);
                CFRelease(multiValueRecord);
            }
        }
    }
    return count;
}

- (NSArray *)valuesForLinkedMultiValueProperty: (ABPropertyID)property
{
    NSMutableArray *values = [[NSMutableArray alloc] init];
    
    if ([AKRecord isMultiValueProperty: property])
    {
        NSArray *linkedRecords = (NSArray *)CFBridgingRelease(ABPersonCopyArrayOfAllLinkedPeople([self recordRef]));
        for (id obj in linkedRecords)
        {
            ABRecordRef recordRef = (__bridge ABRecordRef)obj;
            ABMultiValueRef multiValueRecord = (ABMultiValueRef)ABRecordCopyValue(recordRef, property);
            if (multiValueRecord) {
                NSInteger count = ABMultiValueGetCount(multiValueRecord);
                for (NSInteger i = 0; i < count; ++i) {
                    ABMultiValueIdentifier identifier = (ABMultiValueIdentifier)ABMultiValueGetIdentifierAtIndex(multiValueRecord, i);
                    CFIndex index = ABMultiValueGetIndexForIdentifier(multiValueRecord, identifier);
                    if (index != -1)
                    {
                        id value = (id)CFBridgingRelease(ABMultiValueCopyValueAtIndex(multiValueRecord, index));
                        [values addObject: value];
                    }
                }
                CFRelease(multiValueRecord);
            }
        }
    }
    return [values copy];
}

- (NSArray *)labelsForLinkedMultiValueProperty: (ABPropertyID)property
{
    NSMutableArray *labels = [[NSMutableArray alloc] init];
    
    if ([AKRecord isMultiValueProperty: property])
    {
        NSArray *linkedRecords = (NSArray *)CFBridgingRelease(ABPersonCopyArrayOfAllLinkedPeople([self recordRef]));
        for (id obj in linkedRecords)
        {
            ABRecordRef recordRef = (__bridge ABRecordRef)obj;
            ABMultiValueRef multiValueRecord = (ABMultiValueRef)ABRecordCopyValue(recordRef, property);
            if (multiValueRecord) {
                NSInteger count = ABMultiValueGetCount(multiValueRecord);
                for (NSInteger i = 0; i < count; ++i) {
                    ABMultiValueIdentifier identifier = (ABMultiValueIdentifier)ABMultiValueGetIdentifierAtIndex(multiValueRecord, i);
                    CFIndex index = ABMultiValueGetIndexForIdentifier(multiValueRecord, identifier);
                    NSString *label;
                    if (index != -1)
                    {
                        label = (NSString *)CFBridgingRelease(ABMultiValueCopyLabelAtIndex(multiValueRecord, index));
                    }
                    else
                    {
                        label = [AKLabel defaultLabelForABPropertyID: property];
                    }
                    [labels addObject: label];
                }
                CFRelease(multiValueRecord);
            }
        }
    }
    return [labels copy];
}

- (NSArray *)localizedLabelsForLinkedMultiValueProperty: (ABPropertyID)property
{
    NSMutableArray *labels = [[NSMutableArray alloc] init];
    
    for (NSString *label in [self labelsForLinkedMultiValueProperty: property]) {
        [labels addObject: [AKLabel localizedNameForLabel: (__bridge CFStringRef)(label)]];
    }
    return [labels copy];
}

- (id)valueForMultiValueProperty: (ABPropertyID)property andIdentifier: (ABMultiValueIdentifier)identifier
{
    if (self.recordID < 0) return nil;
    
    id value;
    
    if ([AKRecord isMultiValueProperty: property])
    {
        ABMultiValueRef multiValueRecord = (ABMultiValueRef)ABRecordCopyValue(self.recordRef, property);
        if (multiValueRecord)
        {
            CFIndex index = ABMultiValueGetIndexForIdentifier(multiValueRecord, identifier);
            if (index != -1)
            {
                value = (id)CFBridgingRelease(ABMultiValueCopyValueAtIndex(multiValueRecord, index));
            }
            CFRelease(multiValueRecord);
        }
    }
    return value;
}

- (NSString *)labelForMultiValueProperty: (ABPropertyID)property andIdentifier: (ABMultiValueIdentifier)identifier
{
    if (self.recordID < 0) return nil;
    
    NSString *ret = nil;
    
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
    return ret;
}

- (NSString *)localizedLabelForMultiValueProperty: (ABPropertyID)property andIdentifier: (ABMultiValueIdentifier)identifier
{
    NSString *ret = [self labelForMultiValueProperty: property andIdentifier: identifier];
    if (ret == nil)
    {
        ret = [AKLabel defaultLocalizedLabelForABPropertyID: property];
    }
    else
    {
        ret = [AKLabel localizedNameForLabel: (__bridge CFStringRef)(ret)];
    }
    return ret;
}

- (void)setValue: (id)value andLabel: (NSString *)label forMultiValueProperty: (ABPropertyID)property andIdentifier: (ABRecordID *)identifier
{
    if (self.recordID < 0) return;
    
    ABMultiValueRef record = (ABMultiValueRef)ABRecordCopyValue(self.recordRef, property);
    ABMutableMultiValueRef mutableRecord = NULL;
    if (record)
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
            if (error) { CFStringRef desc = CFErrorCopyDescription(error); NSLog(@"ABRecordSetValue (%ld): %@", CFErrorGetCode(error), desc); CFRelease(desc); error = NULL; }
        }
        CFRelease(mutableRecord);
    }
}

#pragma mark - Class methods

+ (NSString *)localizedNameForProperty: (ABPropertyID)property
{
    return (NSString *)CFBridgingRelease(ABPersonCopyLocalizedPropertyName(property));
}

+ (BOOL)isMultiValueProperty: (ABPropertyID)property
{
    ABPropertyType type = ABPersonGetTypeOfProperty(property);
    return ((type & kABMultiValueMask) == kABMultiValueMask);
}

+ (ABPropertyType)primitiveTypeOfProperty: (ABPropertyID)property
{
    ABPropertyType type = ABPersonGetTypeOfProperty(property);
    return (type &= ~kABMultiValueMask);
}

@end
