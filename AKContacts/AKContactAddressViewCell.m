//
//  AKContactAddressViewCell.m
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

#import "AKContactAddressViewCell.h"
#import "AKContact.h"
#import "AKContactViewController.h"
#import "AKAddressBook.h"

typedef NS_ENUM(NSInteger, AddressTag) {
  kAddressStreet = 1<<8,
  kAddressCity,
  kAddressState,
  kAddressZIP,
  kAddressCountry
};

typedef NS_ENUM(NSInteger, SeparatorTag) {
  kVertical1 = 1<<9,
  kVertical2,
  kHorizontal1,
  kHorizontal2,
};

@interface AKContactAddressViewCell ()

@property (nonatomic, assign) NSInteger identifier;

@end

@implementation AKContactAddressViewCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self)
  {

  }
  return self;
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated
{
  [super setSelected:selected animated:animated];

  // Configure the view for the selected state
}

-(void)configureCellAtRow:(NSInteger)row
{
  [self setIdentifier: NSNotFound];
  [self.textLabel setText: nil];
  [self.detailTextLabel setText: nil];
  [self setSelectionStyle: UITableViewCellSelectionStyleBlue];

  for (UIView *subView in self.contentView.subviews)
  { // Remove edit mode items that might be hanging around on reused cells
    if (subView.tag >= kAddressStreet)
    {
      [subView removeFromSuperview];
    }
  }

  AKContact *contact = self.parent.contact;
  
  if (row < [contact countForProperty: kABPersonAddressProperty])
  {
    NSArray *addressIdentifiers = [contact identifiersForProperty: kABPersonAddressProperty];
    [self setIdentifier: [[addressIdentifiers objectAtIndex: row] integerValue]];

    NSInteger numRows = 0;
    NSString *address = [contact addressForIdentifier: self.identifier andNumRows: &numRows];

    [self.detailTextLabel setText: address];
    [self.detailTextLabel setLineBreakMode: NSLineBreakByWordWrapping];
    [self.detailTextLabel setNumberOfLines: numRows];

    [self.detailTextLabel setFont: [UIFont boldSystemFontOfSize: [UIFont systemFontSize]]];

    [self.textLabel setText: [contact localizedLabelForMultiValueProperty: kABPersonAddressProperty andIdentifier: self.identifier]];
  }
  else
  {
    [self.textLabel setText: (self.parent.willAddAddress == YES) ?
     [[AKRecord defaultLocalizedLabelForABPropertyID: kABPersonAddressProperty] lowercaseString] : NSLocalizedString(@"add new address", @"")];
  }

  if ((self.parent.editing == YES && self.identifier != NSNotFound) ||
      (self.parent.editing == YES && self.parent.willAddAddress == YES))
  {
    [self.contentView addSubview: [AKContactAddressViewCell separatorWithTag: kHorizontal1]];
    [self.contentView addSubview: [AKContactAddressViewCell separatorWithTag: kHorizontal2]];
    [self.contentView addSubview: [AKContactAddressViewCell separatorWithTag: kVertical1]];
    [self.contentView addSubview: [AKContactAddressViewCell separatorWithTag: kVertical2]];

    [self.contentView addSubview: [self getTextFieldWithTag: kAddressStreet]];
    [self.contentView addSubview: [self getTextFieldWithTag: kAddressCity]];
    [self.contentView addSubview: [self getTextFieldWithTag: kAddressState]];
    [self.contentView addSubview: [self getTextFieldWithTag: kAddressZIP]];
    [self.contentView addSubview: [self getTextFieldWithTag: kAddressCountry]];

    [self.detailTextLabel setText: nil];
  }
}

-(void)layoutSubviews
{
  [super layoutSubviews];

  [self.textLabel setFrame: CGRectMake(self.textLabel.frame.origin.x, 13.f,
                                       self.textLabel.frame.size.width,
                                       self.textLabel.frame.size.height)];
  
  if (self.parent.editing)
  {
    UIView *view = [self.contentView viewWithTag: kAddressStreet];
    [view setFrame: CGRectMake(81.f, 0.f, 187.f, 40.f)];
  
    view = [self.contentView viewWithTag: kAddressCity];
    [view setFrame: CGRectMake(81.f, 41.f, 93.f, 39.f)];
    
    view = [self.contentView viewWithTag: kAddressState];
    [view setFrame: CGRectMake(176.f, 41.f, 92.f, 39.f)];

    view = [self.contentView viewWithTag: kAddressZIP];
    [view setFrame: CGRectMake(81.f, 81.f, 93.f, 37.f)];

    view = [self.contentView viewWithTag: kAddressCountry];
    [view setFrame: CGRectMake(176.f, 81.f, 92.f, 37.f)];
    
    view = [self.contentView viewWithTag: kVertical1];
    [view setFrame: CGRectMake(80.f, 0.f, 1.f, self.contentView.bounds.size.height)];
    
    view = [self.contentView viewWithTag: kVertical2];
    [view setFrame: CGRectMake(175.f, 40.f, 1.f, 80.f)];
    
    view = [self.contentView viewWithTag: kHorizontal1];
    [view setFrame: CGRectMake(80.f, 80.f, self.contentView.bounds.size.width - 80.f, 1.f)];

    view = [self.contentView viewWithTag: kHorizontal2];
    [view setFrame: CGRectMake(80.f, 40.f, self.contentView.bounds.size.width - 80.f, 1.f)];
    
    if (self.parent.willAddAddress == NO && self.identifier == NSNotFound)
    { // Add new address frame
      CGFloat width = [self.textLabel.text sizeWithFont: self.textLabel.font].width;
      CGRect frame = self.textLabel.frame;
      frame.size.width = width;
      [self.textLabel setFrame: frame];
    }
  }
}

- (void)dealloc
{
}

#pragma mark - Custom methods

- (UITextField *)getTextFieldWithTag: (NSInteger)tag
{
  AKContact *contact = self.parent.contact;
  NSDictionary *address = [contact valueForMultiValueProperty: kABPersonAddressProperty andIdentifier: self.identifier];

  NSString *key = [AKContactAddressViewCell descriptionForAddressTag: tag];
  NSString *text = [address objectForKey: key];
  
  UITextField *textField = [[UITextField alloc] initWithFrame: CGRectZero];
  [textField setClearButtonMode: UITextFieldViewModeWhileEditing];
  [textField setKeyboardType: UIKeyboardTypeAlphabet];
  [textField setFont: [UIFont boldSystemFontOfSize: 15.]];
  [textField setContentVerticalAlignment: UIControlContentVerticalAlignmentCenter];
  [textField setDelegate: self];
  [textField setTag: tag];

  [textField setPlaceholder: (text) ? text : [AKContact localizedNameForLabel: (__bridge CFStringRef)(key)]];
  [textField setText: text];

  UIView *inset = [[UIView alloc] initWithFrame:CGRectMake(.0f, 0.f, 5.f, 10.f)];
  [inset setUserInteractionEnabled: NO];
  [textField setLeftView: inset];
  [textField setLeftViewMode: UITextFieldViewModeAlways];

  return textField;
}

#pragma mark - Class methods

+ (UIView *)separatorWithTag: (SeparatorTag)tag
{
  UIView *separator = [[UIView alloc] initWithFrame: CGRectZero];
  [separator setBackgroundColor: [UIColor lightGrayColor]];
  [separator setTag: tag];
  [separator setAutoresizingMask: UIViewAutoresizingNone];
  
  return separator;
}

+ (NSString *)descriptionForAddressTag: (AddressTag)tag
{
  switch (tag) {
    case kAddressStreet: return (NSString *)kABPersonAddressStreetKey;
    case kAddressCity: return (NSString *)kABPersonAddressCityKey;
    case kAddressState: return (NSString *)kABPersonAddressStateKey;
    case kAddressZIP: return (NSString *)kABPersonAddressZIPKey;
    case kAddressCountry: return (NSString *)kABPersonAddressCountryKey;
    default: return @"";
  }
}

#pragma mark - UITextField delegate

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
  [self.parent setFirstResponder: textField];
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
  if ([textField isFirstResponder])
    [textField resignFirstResponder];

  [self.parent setFirstResponder: nil];
  
  if ([textField.text length] == 0) return;

  AKContact *contact = self.parent.contact;

  NSString *key = [AKContactAddressViewCell descriptionForAddressTag: textField.tag];

  NSDictionary *address = [contact valueForMultiValueProperty: kABPersonAddressProperty andIdentifier: self.identifier];
  if (address == nil)
  {
    NSDictionary *newAddress = [[NSDictionary alloc] initWithObjectsAndKeys: textField.text, key, nil];
    NSInteger identifier = self.identifier;
    NSString *label = [AKContact defaultLabelForABPropertyID: kABPersonAddressProperty];
    [contact setValue: newAddress andLabel: label forMultiValueProperty: kABPersonAddressProperty andIdentifier: &identifier];
    [self setIdentifier: identifier];
    address = [contact valueForMultiValueProperty: kABPersonAddressProperty andIdentifier: self.identifier];
  }
  else
  {
    NSMutableDictionary *mutableAddress = [address mutableCopy];
    [mutableAddress setObject: textField.text forKey: key];
    address = [mutableAddress copy];
    NSInteger identifier = self.identifier;
    NSString *label = [contact labelForMultiValueProperty: kABPersonAddressProperty andIdentifier: identifier];
    [contact setValue: address andLabel: label forMultiValueProperty: kABPersonAddressProperty andIdentifier: &identifier];
  }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
  if ([textField isFirstResponder])
    [textField resignFirstResponder];
  return YES;
}

@end
