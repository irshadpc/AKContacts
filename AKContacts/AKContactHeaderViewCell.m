//
//  AKContactHeaderViewCell.m
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

#import "AKContactHeaderViewCell.h"
#import "AKContact.h"
#import "AKContactViewController.h"
#import "AKAddressBook.h"

#import <QuartzCore/QuartzCore.h> // Image Layer

static const int editModeItem = 8;

@interface AKContactHeaderViewCell ()

@property (nonatomic, unsafe_unretained) AKContactViewController *delegate;
@property (assign, nonatomic) ABPropertyID abPropertyID;
@property (strong, nonatomic) UITextField *textField;

- (void)configureCellAtRow: (NSInteger)row;

@end

@implementation AKContactHeaderViewCell

+ (UITableViewCell *)cellWithDelegate: (AKContactViewController *)delegate atRow: (NSInteger)row
{
  static NSString *CellIdentifier = @"AKContactHeaderCellView";
  
  AKContactHeaderViewCell *cell = [delegate.tableView dequeueReusableCellWithIdentifier: CellIdentifier];
  if (cell == nil)
  {
    cell = [[AKContactHeaderViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }
  
  [cell setDelegate: delegate];
  
  [cell configureCellAtRow: row];
  
  return (UITableViewCell *)cell;
}

- (void)setFrame:(CGRect)frame {
  if ([self.delegate isEditing]) {
    frame.origin.x += 80.f;
    frame.size.width -= 80.f;
  }
  [super setFrame:frame];
}

- (void)configureCellAtRow:(NSInteger)row
{
  [self setSelectionStyle: UITableViewCellSelectionStyleNone];

  // Clear content view
  for (UIView *subView in [self.contentView subviews])
  {
    [subView removeFromSuperview];
  }

  AKContact *contact = self.delegate.contact;

  if (row == 0)
  {
    CGFloat posX = (self.delegate.editing == YES) ? -80.f : 0.f;
    UIButton *button = [[UIButton alloc] initWithFrame: CGRectMake(posX, 0.f, 64.f, 64.f)];
    [button setUserInteractionEnabled: (self.delegate.editing == YES)];
    [self.contentView addSubview: button];
    if (contact.pictureData == nil && self.delegate.editing == YES)
    {
      [button.layer setMasksToBounds: YES];
      [button.layer setCornerRadius: 5.f];
      [button.layer setBorderColor: [UIColor colorWithRed: 130.f/255.f green: 138.f/255.f blue: 154.f/255.f alpha: 1.f].CGColor];
      [button.layer setBorderWidth: 1.5f];
      [button setTitle: NSLocalizedString(@"add\nphoto", @"") forState: UIControlStateNormal];
      [button.titleLabel setLineBreakMode: NSLineBreakByWordWrapping];
      [button.titleLabel setFont: [UIFont boldSystemFontOfSize: 12.f]];
      [button.titleLabel setNumberOfLines: 2];
      [button.titleLabel setTextAlignment: NSTextAlignmentCenter];
      [button setTitleColor: [UIColor colorWithRed:81.f/255.f green:102.f/255.f blue:145.f/255.f alpha: 1.f] forState: UIControlStateNormal];
    }
    else
    {
      [button setImage: [contact picture] forState: UIControlStateNormal];
      [button setContentMode: UIViewContentModeScaleAspectFit];
      [button.layer setBorderColor: [[UIColor whiteColor] CGColor]];
      [button.layer setBorderWidth: 4.f];
      [button.layer setShadowColor: [UIColor grayColor].CGColor];
      [button.layer setShadowOffset: CGSizeMake(0, 1)];
      [button.layer setShadowOpacity: 1];
      [button.layer setShadowRadius: 1.0];
    }
  }
  
  if ([self.delegate isEditing])
  {
    UITextField *textField = [[UITextField alloc] initWithFrame: CGRectZero];
    [textField setClearButtonMode: UITextFieldViewModeWhileEditing];
    [textField setContentVerticalAlignment: UIControlContentVerticalAlignmentCenter];
    [textField setFont: [UIFont boldSystemFontOfSize: 15.f]];
    [textField setDelegate: self];
    [textField setTag: editModeItem];
    [textField setText: self.detailTextLabel.text];

    [self setTextField: textField];
    [self.contentView addSubview: textField];

    if (row == 0)
    {
      [self setAbPropertyID: kABPersonLastNameProperty];
    }
    else if (row == 1)
    {
      [self setAbPropertyID: kABPersonFirstNameProperty];
    }
    else if (row == 2)
    {
      [self setAbPropertyID: kABPersonOrganizationProperty];
    }
    else if (row == 3)
    {
      [self setAbPropertyID: kABPersonJobTitleProperty];
    }
    NSString *placeholder = [AKContact localizedNameForProperty: self.abPropertyID];
    [textField setPlaceholder: placeholder];
    [textField setText: [contact valueForProperty: self.abPropertyID]];
  }
  else
  {
    [self.backgroundView setHidden: YES]; // Hide background in default mode
    [self.delegate.tableView setSeparatorStyle: UITableViewCellSeparatorStyleNone];

    UILabel *contactNameLabel = [[UILabel alloc] initWithFrame: CGRectMake(80.f, 0.f, 210.f, 23.f)];
    [self.contentView addSubview: contactNameLabel];
    [contactNameLabel setBackgroundColor: [UIColor clearColor]];
    [contactNameLabel setText: [contact name]];
    [contactNameLabel setFont: [UIFont boldSystemFontOfSize: 18.f]];
    
    CGSize constraintSize = CGSizeMake(contactNameLabel.frame.size.width, MAXFLOAT);
    CGSize contactNameSize = [contactNameLabel.text sizeWithFont: contactNameLabel.font constrainedToSize: constraintSize lineBreakMode: NSLineBreakByWordWrapping];
    if (contactNameLabel.frame.size.height < contactNameSize.height + 5.f)
    {
      contactNameLabel.frame = CGRectMake(contactNameLabel.frame.origin.x,
                                          contactNameLabel.frame.origin.y,
                                          contactNameLabel.frame.size.width + 5.f,
                                          contactNameLabel.frame.size.height);
      
    }
    else
    {
      contactNameLabel.frame = CGRectMake(contactNameLabel.frame.origin.x,
                                          contactNameLabel.frame.origin.y + 10.f,
                                          contactNameLabel.frame.size.width,
                                          contactNameLabel.frame.size.height);
    }
    NSString *contactDetails = [contact displayDetails];
    if (contactDetails != nil)
    {
      UILabel *contactDetailsLabel = [[UILabel alloc] initWithFrame: CGRectMake(80.f, 36.f, 210.f, 21.f)];
      [contactDetailsLabel setText: contactDetails];
      [contactDetailsLabel setBackgroundColor: [UIColor clearColor]];
      
      UIFont *cellFont = [UIFont systemFontOfSize: 14.f];
      CGSize constraintSize = CGSizeMake(contactDetailsLabel.frame.size.width, MAXFLOAT);
      CGSize contactDetailsSize = [contactDetails sizeWithFont: cellFont constrainedToSize: constraintSize lineBreakMode: NSLineBreakByWordWrapping];
      
      contactDetailsLabel.frame = CGRectMake(contactDetailsLabel.frame.origin.x,
                                             contactNameLabel.frame.origin.y + contactNameLabel.frame.size.height,
                                             contactDetailsSize.width + 5.f,
                                             contactDetailsSize.height);
    }
  }
}

- (void)layoutSubviews
{
  [super layoutSubviews];

  if (self.delegate.isEditing)
  {
    CGRect frame = CGRectMake(self.contentView.bounds.origin.x + 10.f,
                              self.contentView.bounds.origin.y,
                              self.contentView.bounds.size.width - 20.f,
                              self.contentView.bounds.size.height);
    [self.textField setFrame: frame];

    [self.backgroundView setHidden: NO]; // Show background in edit mode
    [self.delegate.tableView setSeparatorStyle: UITableViewCellSeparatorStyleSingleLine];
  }
  else
  {
    [self.backgroundView setHidden: YES]; // Hide background in default mode
    [self.delegate.tableView setSeparatorStyle: UITableViewCellSeparatorStyleNone];
  }
}

#pragma masrk - UITextField delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
  [self.delegate setFirstResponder: textField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
  if ([textField isFirstResponder])
    [textField resignFirstResponder];
  
  [self.delegate setFirstResponder: nil];
  
  AKContact *contact = self.delegate.contact;
  if (self.abPropertyID == kABPersonLastNameProperty)
  {
    [contact setValue: textField.text forProperty: kABPersonLastNameProperty];
  }
  else if (self.abPropertyID == kABPersonFirstNameProperty)
  {
    [contact setValue: textField.text forProperty: kABPersonFirstNameProperty];
  }
  else if (self.abPropertyID == kABPersonOrganizationProperty)
  {
    [contact setValue: textField.text forProperty: kABPersonOrganizationProperty];
  }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  if ([textField isFirstResponder])
    [textField resignFirstResponder];
  return YES;
}

@end
