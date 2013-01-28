//
//  AKRecord.h
//
//  Copyright (c) 2013 Adam Kornafeld All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@interface AKRecord : NSObject {

}

@property (assign) ABRecordRef record;
@property (assign) ABRecordID recordID;

-(id)initWithABRecordRef: (ABRecordRef) aRecord;

/**
 * Return a value corresponding to an ABPropertyID.
 * Return type can be NSString, NSDate
**/
-(id)valueForProperty: (ABPropertyID)property;

/**
 * Return the number of elements in an ABMultiValue type
 **/
-(NSInteger)countForProperty: (ABPropertyID) property;

/**
 * Return the list of identifiers for an ABMultiValue type
 **/
-(NSArray *)identifiersForProperty: (ABPropertyID) property;

/**
 * Return a value for an idenfifier from an ABMultiValue type
 * Return type can be NSString, NSDate, NSDictionary
 **/
-(id)valueForMultiValueProperty: (ABPropertyID)property forIdentifier: (NSInteger)identifier;

/**
 * Return the values for a key and an identifier for the following properties:
 * kABPersonAddressProperty, kABPersonInstantMessageProperty
 **/
-(NSString *)valueForMultiDictKey: (NSString *)key forIdentifier: (NSInteger)identifier;

/**
 * Return a label for an identifier from an ABMultiValue type
 **/
-(NSString*)labelForMultiValueProperty: (ABPropertyID)property forIdentifier: (NSInteger)identifier;

-(void)createValue: (id)value forProperty: (ABPropertyID)property;
-(void)createValue: (id)value forMultiValueProperty: (ABPropertyID)property forIdentifier: (NSInteger)identifier;
-(void)createLabel:(NSString *)label forMultiValueProperty: (ABPropertyID)property forIdentifier: (NSInteger)identifier;
-(void)createValue:(id)value forMultiDictKey: (NSString *)key forIdentifier: (NSInteger)identifier;

-(void)updateValue: (id)value forProperty: (ABPropertyID)property;
-(void)updateValue: (id)value forMultiValueProperty: (ABPropertyID)property forIdentifier: (NSInteger)identifier;
-(void)updateLabel: (NSString *)label forMultiValueProperty: (ABPropertyID)property forIdentifier: (NSInteger)identifier;
-(void)updateValue:(id)value forMultiDictKey: (NSString *)key forIdentifier: (NSInteger)identifier;

-(void)deleteValueForProperty: (ABPropertyID)property;
-(void)deleteValueForMultiValueProperty: (ABPropertyID)property forIdentifier: (NSInteger)identifier;

-(void)commitWithAddressBook: (ABAddressBookRef)addressBook;
-(void)revertWithAddressBook: (ABAddressBookRef)addressBook;

@end
