//
//  NSString+Additions.m
//  AKContacts
//
//  Created by Adam Kornafeld on 3/10/14.
//  Copyright (c) 2014 Adam Kornafeld. All rights reserved.
//

#import "NSString+Additions.h"

@implementation NSString (Additions)

- (BOOL)isMemberOfCharacterSet:(NSCharacterSet *)characterset
{
    BOOL ret = YES;
    for (NSUInteger index = 0; index < self.length; ++index)
    {
        if (![characterset characterIsMember: [self characterAtIndex: index]])
        {
            ret = NO;
            break;
        }
    }
    return ret;
}

- (NSString *)stringByTrimmingLeadingCharactersInSet:(NSCharacterSet *)characterSet
{
    NSUInteger location = [self rangeOfCharacterFromSet: [characterSet invertedSet]].location;
    return (location != NSNotFound) ? [self substringFromIndex: location] : @"";
}

- (NSString *)stringWithNonDigitsRemoved
{
    NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return [[self componentsSeparatedByCharactersInSet: nonDigits] componentsJoinedByString: @""];
}

- (NSString *)stringWithDiacriticsRemoved
{
    return [self stringByFoldingWithOptions: NSDiacriticInsensitiveSearch locale: [NSLocale currentLocale]];
}

- (NSString *)stringWithNormalizedPhoneNumber
{
    NSString *normalizedPhoneNumber = self;
    if ([normalizedPhoneNumber hasPrefix: @"+"]) {
        normalizedPhoneNumber = [NSString stringWithFormat: @"+%@", normalizedPhoneNumber.stringWithNonDigitsRemoved];
    }
    else {
        normalizedPhoneNumber = normalizedPhoneNumber.stringWithNonDigitsRemoved;
    }
    return normalizedPhoneNumber;
}

- (NSString *)stringWithWhiteSpaceTrimmed
{
    return [self stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
}

@end
