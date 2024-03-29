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

static const int editModeItem = 8;

@interface AKContactHeaderViewCell ()

@property (nonatomic, unsafe_unretained) AKContactViewController *controller;
@property (assign, nonatomic) ABPropertyID abPropertyID;
@property (strong, nonatomic) UITextField *textField;

- (void)configureCellAtRow: (NSInteger)row;

@end

@implementation AKContactHeaderViewCell

+ (UITableViewCell *)cellWithController:(AKContactViewController *)controller atRow:(NSInteger)row
{
    static NSString *CellIdentifier = @"AKContactHeaderCellView";
    
    AKContactHeaderViewCell *cell = [controller.tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    if (cell == nil)
    {
        cell = [[AKContactHeaderViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    [cell setController: controller];
    
    [cell configureCellAtRow: row];
    
    return (UITableViewCell *)cell;
}

- (void)setFrame:(CGRect)frame
{
    BOOL iOS7 = SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0");
    if (iOS7)
    {
        frame.origin.y += 10.f;
        frame.size.height -= 10.f;
    }
    
    if ([self.controller isEditing])
    {
        frame.origin.x += 80.f;
        frame.size.width -= 80.f;
    }
    [super setFrame:frame];
}

- (void)configureCellAtRow:(NSInteger)row
{
    [self setSelectionStyle: UITableViewCellSelectionStyleNone];
    
    // Clear content view
    for (UIView *subView in [self.contentView subviews]) {
        [subView removeFromSuperview];
    }
    
    AKContact *contact = self.controller.contact;
    
    if ([self.controller isEditing]) {
        UITextField *textField = [[UITextField alloc] initWithFrame: CGRectZero];
        [textField setClearButtonMode: UITextFieldViewModeWhileEditing];
        [textField setContentVerticalAlignment: UIControlContentVerticalAlignmentCenter];
        [textField setFont: [UIFont boldSystemFontOfSize: 15.f]];
        [textField setDelegate: self];
        [textField setTag: editModeItem];
        [textField setText: self.detailTextLabel.text];
        
        [self setTextField: textField];
        [self.contentView addSubview: textField];
        
        if (row == 0) {
            [self setAbPropertyID: kABPersonLastNameProperty];
        }
        else if (row == 1) {
            [self setAbPropertyID: kABPersonFirstNameProperty];
        }
        else if (row == 2) {
            [self setAbPropertyID: kABPersonOrganizationProperty];
        }
        else if (row == 3) {
            [self setAbPropertyID: kABPersonJobTitleProperty];
        }
        NSString *placeholder = [AKContact localizedNameForProperty: self.abPropertyID];
        [textField setPlaceholder: placeholder];
        [textField setText: [contact valueForProperty: self.abPropertyID]];
    }
    else {
        [self.backgroundView setHidden: YES]; // Hide background in default mode
        [self.controller.tableView setSeparatorStyle: UITableViewCellSeparatorStyleNone];
        
        UILabel *contactNameLabel = [[UILabel alloc] initWithFrame: CGRectMake(80.f, 0.f, 210.f, 23.f)];
        [self.contentView addSubview: contactNameLabel];
        [contactNameLabel setBackgroundColor: [UIColor clearColor]];
        [contactNameLabel setText: contact.compositeName];
        [contactNameLabel setFont: [UIFont boldSystemFontOfSize: 18.f]];
        
        CGSize constraintSize = CGSizeMake(contactNameLabel.frame.size.width, MAXFLOAT);
        
        NSDictionary *attr = @{NSFontAttributeName: contactNameLabel.font};
        
        CGRect contactNameSize = [contactNameLabel.text boundingRectWithSize: constraintSize options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes: attr context:nil];
        
        if (contactNameLabel.frame.size.height < contactNameSize.size.height + 5.f)
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
        if (contactDetails) {
            UILabel *contactDetailsLabel = [[UILabel alloc] initWithFrame: CGRectMake(77.f, 36.f, 210.f, 21.f)];
            [self.contentView addSubview: contactDetailsLabel];
            [contactDetailsLabel setText: contactDetails];
            [contactDetailsLabel setBackgroundColor: [UIColor clearColor]];
            [contactDetailsLabel setFont: [UIFont systemFontOfSize: 13.f]];
            
            CGSize constraintSize = CGSizeMake(contactDetailsLabel.frame.size.width, MAXFLOAT);
            
            NSDictionary *attr = @{NSFontAttributeName: contactDetailsLabel.font};
            CGRect contactDetailsSize = [contactNameLabel.text boundingRectWithSize: constraintSize options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes: attr context:nil];
            
            contactDetailsLabel.frame = CGRectMake(contactDetailsLabel.frame.origin.x,
                                                   contactNameLabel.frame.origin.y + contactNameLabel.frame.size.height,
                                                   contactDetailsSize.size.width + 5.f,
                                                   contactDetailsSize.size.height);
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.controller.isEditing)
    {
        CGRect frame = CGRectMake(self.contentView.bounds.origin.x + 10.f,
                                  self.contentView.bounds.origin.y,
                                  self.contentView.bounds.size.width - 20.f,
                                  self.contentView.bounds.size.height);
        [self.textField setFrame: frame];
        
        [self.backgroundView setHidden: NO]; // Show background in edit mode
        [self.controller.tableView setSeparatorStyle: UITableViewCellSeparatorStyleSingleLine];
    }
    else
    {
        [self.backgroundView setHidden: YES]; // Hide background in default mode
        [self.controller.tableView setSeparatorStyle: UITableViewCellSeparatorStyleNone];
    }
}

#pragma mark - UITextField delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self.controller setFirstResponder: textField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if ([textField isFirstResponder])
        [textField resignFirstResponder];
    
    [self.controller setFirstResponder: nil];
    
    AKContact *contact = self.controller.contact;
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
