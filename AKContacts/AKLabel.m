//
//  AKLabel.m
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

#import "AKLabel.h"

const int createLabelTag = -128;

NSString *const defaultsLabelKey = @"Label_%d";

@interface AKLabel ()

@property (nonatomic, assign) BOOL standard;

@end

@implementation AKLabel

#pragma mark - Class methods

+ (NSString *)defaultLabelForABPropertyID: (ABPropertyID)property
{
  if (property == kABPersonPhoneProperty)
  {
    return (__bridge NSString *)(kABPersonPhoneMobileLabel);
  }
  else if (property == kABPersonEmailProperty)
  {
    return (__bridge NSString *)(kABWorkLabel);
  }
  else if (property == kABPersonAddressProperty)
  {
    return (__bridge NSString *)(kABHomeLabel);
  }
  else if (property == kABPersonURLProperty)
  {
    return (__bridge NSString *)(kABPersonHomePageLabel);
  }
  else if (property == kABPersonDateProperty)
  {
    return (__bridge NSString *)(kABPersonAnniversaryLabel);
  }
  else if (property == kABPersonRelatedNamesProperty)
  {
    return (__bridge NSString *)(kABPersonMotherLabel);
  }
  else if (property == kABPersonSocialProfileProperty)
  {
    return (__bridge NSString *)(kABPersonSocialProfileServiceFacebook);
  }
  else
  {
    return (__bridge NSString *)(kABOtherLabel);
  }
}

+ (NSString *)defaultLocalizedLabelForABPropertyID: (ABPropertyID)property
{
  NSString *defaultLabel = [AKLabel defaultLabelForABPropertyID: property];
  return CFBridgingRelease(ABAddressBookCopyLocalizedLabel((__bridge CFStringRef)(defaultLabel)));
}

+ (NSString *)localizedNameForLabel: (CFStringRef)label
{
  return (NSString *)CFBridgingRelease(ABAddressBookCopyLocalizedLabel(label));
}

#pragma mark - Instance methods

- (id)initWithLabel: (NSString *)label andIsStandard: (BOOL)standard
{
  self = [super init];
  if (self)
  {
    _label = [label copy];
    _standard = standard;
    _status = kLabelStatusNormal;
  }
  return  self;

}

- (NSString *)localizedLabel
{
  if (self.standard == YES)
  {
    return [AKLabel localizedNameForLabel: (__bridge CFStringRef)(self.label)];
  }
  else
  {
    return self.label;
  }
}

@end
