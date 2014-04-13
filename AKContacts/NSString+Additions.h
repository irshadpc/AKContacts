//
//  NSString+Additions.h
//  AKContacts
//
//  Created by Adam Kornafeld on 3/10/14.
//  Copyright (c) 2014 Adam Kornafeld. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Additions)

- (BOOL)isMemberOfCharacterSet:(NSCharacterSet *)characterset;
- (NSString *)stringByTrimmingLeadingCharactersInSet:(NSCharacterSet *)characterSet;

@property (readonly) NSString *stringWithNonDigitsRemoved;
@property (readonly) NSString *stringWithDiacriticsRemoved;
@property (readonly) NSString *stringWithNormalizedPhoneNumber;
@property (readonly) NSString *stringWithWhiteSpaceTrimmed;

@end
