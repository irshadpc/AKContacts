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

#import <QuartzCore/QuartzCore.h> // Image Layer

static const int editModeItem = 8;

@interface AKContactHeaderViewCell ()

@property (nonatomic, assign) ABPropertyID abPropertyID;

@end

@implementation AKContactHeaderViewCell

@synthesize abPropertyID = _abPropertyID;

@synthesize parent = _parent;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    // Initialization code
  }
  return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

  [super setSelected:selected animated:animated];

  // Configure the view for the selected state
}

- (void)setFrame:(CGRect)frame {
  if ([self.parent isEditing]) {
    frame.origin.x += 80.f;
    frame.size.width -= 80.f;
  }
  [super setFrame:frame];
}

-(void)configureCellAtRow:(NSInteger)row {

  // Clear content view
  for (UIView *subView in [self.contentView subviews]) {
    [subView removeFromSuperview];
  }

  if ([self.parent isEditing]) {

    UITextField *textField = [[UITextField alloc] initWithFrame: CGRectMake(5.f, 12.f, 210.f, 19.f)];
    [textField setClearButtonMode: UITextFieldViewModeWhileEditing];
    [textField setFont: [UIFont boldSystemFontOfSize: 15.f]];
    [textField setDelegate: self];
    [textField setTag: editModeItem];
    
    [textField setText: self.detailTextLabel.text];
    [self.contentView addSubview: textField];

    if (row == 0) {

      [self setAbPropertyID: kABPersonLastNameProperty];
      CFStringRef placeholder = ABPersonCopyLocalizedPropertyName(kABPersonLastNameProperty);
      [textField setPlaceholder: (__bridge NSString *)placeholder];
      CFRelease(placeholder);
      [textField setText: [self.parent.contact valueForProperty: kABPersonLastNameProperty]];

      UIButton *button = [[UIButton alloc] initWithFrame: CGRectMake(-80.f, 0.f, 64.f, 64.f)];
      [self.contentView addSubview: button];
      [button.layer setMasksToBounds: YES];
      [button.layer setCornerRadius: 5.f];
      [button.layer setBorderColor: [[UIColor colorWithRed:130.f/255.f green:138.f/255.f blue:154.f/255.f alpha: 1.f] CGColor]];
      [button.layer setBorderWidth: 1.5f];
      [button setTitle: @"add\nphoto" forState: UIControlStateNormal];
      [button.titleLabel setLineBreakMode: NSLineBreakByWordWrapping];
      [button.titleLabel setFont: [UIFont boldSystemFontOfSize: 12.f]];
      [button.titleLabel setNumberOfLines: 2];
      [button.titleLabel setTextAlignment: NSTextAlignmentCenter];
      [button setTitleColor: [UIColor colorWithRed:81.f/255.f green:102.f/255.f blue:145.f/255.f alpha: 1.f] forState: UIControlStateNormal];

    } else if (row == 1) {
      
      [self setAbPropertyID: kABPersonFirstNameProperty];
      [textField setText: [self.parent.contact valueForProperty: kABPersonFirstNameProperty]];
      CFStringRef placeholder = ABPersonCopyLocalizedPropertyName(kABPersonFirstNameProperty);
      [textField setPlaceholder: (__bridge NSString *)placeholder];
      CFRelease(placeholder);

    } else if (row == 2) {

      [self setAbPropertyID: kABPersonOrganizationProperty];
      [textField setText: [self.parent.contact valueForProperty: kABPersonOrganizationProperty]];
      CFStringRef placeholder = ABPersonCopyLocalizedPropertyName(kABPersonOrganizationProperty);
      [textField setPlaceholder: (__bridge NSString *)placeholder];
      CFRelease(placeholder);

    } else if (row == 3) {
      
      [self setAbPropertyID: kABPersonJobTitleProperty];
      [textField setText: [self.parent.contact valueForProperty: kABPersonJobTitleProperty]];
      CFStringRef placeholder = ABPersonCopyLocalizedPropertyName(kABPersonJobTitleProperty);
      [textField setPlaceholder: (__bridge NSString *)placeholder];
      CFRelease(placeholder);

    }
    
  } else {
    
    [self.backgroundView setHidden: YES]; // Hide background in default mode
    [self.parent.tableView setSeparatorStyle: UITableViewCellSeparatorStyleNone];
    
    UIImageView *contactImageView = [[UIImageView alloc] initWithFrame: CGRectMake(0.f, 0.f, 64.f, 64.f)];
    [self.contentView addSubview: contactImageView];
    [contactImageView.layer setMasksToBounds: YES];
    [contactImageView.layer setCornerRadius: 5.f];
    [contactImageView.layer setBorderColor: [[UIColor grayColor] CGColor]];
    [contactImageView.layer setBorderWidth: 1.f];
    [contactImageView setImage: [self.parent.contact picture]];
    
    UILabel *contactNameLabel = [[UILabel alloc] initWithFrame: CGRectMake(80.f, 0.f, 210.f, 23.f)];
    [self.contentView addSubview: contactNameLabel];
    [contactNameLabel setBackgroundColor: [UIColor clearColor]];
    [contactNameLabel setText: [self.parent.contact displayName]];
    [contactNameLabel setFont: [UIFont boldSystemFontOfSize: 18.f]];
    [contactNameLabel setTextColor: [UIColor blackColor]];
    
    CGSize constraintSize = CGSizeMake(contactNameLabel.frame.size.width, MAXFLOAT);
    CGSize contactNameSize = [contactNameLabel.text sizeWithFont: contactNameLabel.font constrainedToSize: constraintSize lineBreakMode: NSLineBreakByWordWrapping];
    if (contactNameLabel.frame.size.height < contactNameSize.height + 5.f) {
      
      contactNameLabel.frame = CGRectMake(contactNameLabel.frame.origin.x,
                                          contactNameLabel.frame.origin.y,
                                          contactNameLabel.frame.size.width + 5.f,
                                          contactNameLabel.frame.size.height);
      
    } else {
      
      contactNameLabel.frame = CGRectMake(contactNameLabel.frame.origin.x,
                                          contactNameLabel.frame.origin.y + 10.f,
                                          contactNameLabel.frame.size.width,
                                          contactNameLabel.frame.size.height);
    }
    
    NSString *contactDetails = [self.parent.contact displayDetails];
    if (contactDetails != nil) {
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

-(void)layoutSubviews {
  [super layoutSubviews];

  if (self.parent.isEditing) {

    [self.backgroundView setHidden: NO]; // Show background in edit mode
    [self.parent.tableView setSeparatorStyle: UITableViewCellSeparatorStyleSingleLine];

  } else {

    [self.backgroundView setHidden: YES]; // Hide background in default mode
    [self.parent.tableView setSeparatorStyle: UITableViewCellSeparatorStyleNone];
    
  }
}

- (void)dealloc {
}

#pragma masrk - UITextField delegate

-(void)textFieldDidBeginEditing:(UITextField *)textField {
  
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
  if ([textField isFirstResponder])
    [textField resignFirstResponder];
  
  // Update ABContact here
  if (self.abPropertyID == kABPersonLastNameProperty) {
    
  } else if (self.abPropertyID == kABPersonFirstNameProperty) {
    
  } else if (self.abPropertyID == kABPersonOrganizationProperty) {
  
  }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
  if ([textField isFirstResponder])
    [textField resignFirstResponder];
  return YES;
}

@end