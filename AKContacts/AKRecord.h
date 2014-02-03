//
//  AKRecord.h
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

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@interface AKRecord : NSObject

@property (assign, nonatomic) ABRecordType recordType;
@property (assign, nonatomic) ABRecordID recordID;
@property (strong, nonatomic) NSDate *age;

- (instancetype)initWithABRecordID: (ABRecordID) recordID andRecordType: (ABRecordType)recordType;
- (ABRecordRef)recordRef;
- (NSString *)description;
/**
 * Return a value corresponding to an ABPropertyID.
 * Return type can be NSString, NSDate
 **/
- (id)valueForProperty: (ABPropertyID)property;
/**
 * Set a value corresponding to an ABPropertyID.
 **/
- (void)setValue: (id)value forProperty: (ABPropertyID)property;

/**
 * Return the number of elements in an ABMultiValue type
 **/
- (NSInteger)countForProperty: (ABPropertyID) property;

/**
 * Return the list of identifiers for an ABMultiValue type
 **/
- (NSArray *)identifiersForProperty: (ABPropertyID) property;

/**
 * Return a value of an idenfifier for an ABMultiValue type
 * Return type can be NSString, NSDate, NSDictionary
 **/
- (id)valueForMultiValueProperty: (ABPropertyID)property andIdentifier: (NSInteger)identifier;
/**
 * Return a label of an identifier for an ABMultiValue type
 **/
- (NSString *)labelForMultiValueProperty: (ABPropertyID)property andIdentifier: (NSInteger)identifier;
- (NSString *)localizedLabelForMultiValueProperty: (ABPropertyID)property andIdentifier: (NSInteger)identifier;

- (void)setValue: (id)value andLabel: (NSString *)label forMultiValueProperty: (ABPropertyID)property andIdentifier: (NSInteger *)identifier;

@end
