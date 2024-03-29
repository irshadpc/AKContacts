//
//  AKContactInstantMessageViewCell.m
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

#import "AKContactInstantMessageViewCell.h"
#import "AKContact.h"
#import "AKContactViewController.h"
#import "AKLabelViewController.h"
#import "AKLabel.h"
#import "AKAddressBook.h"

typedef NS_ENUM(NSInteger, InstantMessageTag) {
    kIMUsername = 1<<8,
    kIMService,
};

typedef NS_ENUM(NSInteger, SeparatorTag) {
    kVertical1 = 1<<9,
    kHorizontal1,
};

@interface AKContactInstantMessageViewCell () <UITextFieldDelegate>

@property (unsafe_unretained, nonatomic) AKContactViewController *controller;

- (void)configureCellAtRow: (NSInteger)row;

@end

@implementation AKContactInstantMessageViewCell

- (void)configureCellAtRow: (NSInteger)row
{
    [self setTag: NSNotFound];
    [self.textLabel setText: nil];
    [self.detailTextLabel setText: nil];
    [self setSelectionStyle: UITableViewCellSelectionStyleBlue];
    
    for (UIView *subView in self.contentView.subviews)
    { // Remove edit mode items that might be hanging around on reused cells
        if (subView.tag >= kIMUsername)
        {
            [subView removeFromSuperview];
        }
    }
    
    AKContact *contact = self.controller.contact;
    
    if (row < [contact countForMultiValueProperty: kABPersonInstantMessageProperty])
    {
        NSArray *imIdentifiers = [contact identifiersForMultiValueProperty: kABPersonInstantMessageProperty];
        [self setTag: [[imIdentifiers objectAtIndex: row] integerValue]];
        
        NSString *instantMessage = [contact instantMessageDescriptionForIdentifier: (ABMultiValueIdentifier)self.tag];
        
        [self.detailTextLabel setText: instantMessage];
        
        [self.detailTextLabel setFont: [UIFont boldSystemFontOfSize: [UIFont systemFontSize]]];
        
        [self.textLabel setText: [contact localizedLabelForMultiValueProperty: kABPersonInstantMessageProperty andIdentifier: (ABMultiValueIdentifier)self.tag]];
    }
    else
    {
        [self.textLabel setText: [[AKLabel defaultLocalizedLabelForABPropertyID: kABPersonInstantMessageProperty] lowercaseString]];
    }
    
    if (self.controller.editing == YES)
    {
        [self.contentView addSubview: [AKContactInstantMessageViewCell separatorWithTag: kHorizontal1]];
        [self.contentView addSubview: [AKContactInstantMessageViewCell separatorWithTag: kVertical1]];
        
        [self.contentView addSubview: [self getTextFieldWithTag: kIMUsername]];
        [self.contentView addSubview: [self getTextFieldWithTag: kIMService]];
        
        [self.detailTextLabel setText: nil];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.textLabel setFrame: CGRectMake(self.textLabel.frame.origin.x, 13.f,
                                         self.textLabel.frame.size.width,
                                         self.textLabel.frame.size.height)];
    
    if (self.controller.editing)
    {
        UIView *view = [self.contentView viewWithTag: kIMUsername];
        [view setFrame: CGRectMake(81.f, 0.f, 187.f, 40.f)];
        
        view = [self.contentView viewWithTag: kIMService];
        [view setFrame: CGRectMake(81.f, 41.f, 187.f, 39.f)];
        
        view = [self.contentView viewWithTag: kVertical1];
        [view setFrame: CGRectMake(80.f, 0.f, 1.f, self.contentView.bounds.size.height)];
        
        view = [self.contentView viewWithTag: kHorizontal1];
        [view setFrame: CGRectMake(80.f, 40.f, self.contentView.bounds.size.width - 80.f, 1.f)];
        
        BOOL iOS7 = SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0");
        if (iOS7 == YES && self.controller.editing == YES)
        {
            CGRect frame = CGRectMake(-20.f, self.textLabel.frame.origin.y,
                                      self.textLabel.frame.size.width,
                                      self.textLabel.frame.size.height);
            [self.textLabel setFrame: frame];
        }
    }
}

#pragma mark - Custom methods

- (UITextField *)getTextFieldWithTag: (NSInteger)tag
{
    AKContact *contact = self.controller.contact;
    NSDictionary *service = [contact valueForMultiValueProperty: kABPersonInstantMessageProperty andIdentifier: (ABMultiValueIdentifier)self.tag];
    
    NSString *key = [AKContactInstantMessageViewCell descriptionForInstantMessageTag: tag];
    NSString *text = [service objectForKey: key];
    if (text == nil && tag == kIMService)
    {
        text = (NSString *)kABPersonInstantMessageServiceSkype;
    }
    
    UITextField *textField = [[UITextField alloc] initWithFrame: CGRectZero];
    [textField setClearButtonMode: UITextFieldViewModeWhileEditing];
    [textField setKeyboardType: UIKeyboardTypeAlphabet];
    [textField setFont: [UIFont boldSystemFontOfSize: 15.]];
    [textField setContentVerticalAlignment: UIControlContentVerticalAlignmentCenter];
    [textField setDelegate: self];
    [textField setTag: tag];
    
    [textField setPlaceholder: (text) ? text : [AKLabel localizedNameForLabel: (__bridge CFStringRef)(key)]];
    [textField setText: text];
    
    UIView *inset = [[UIView alloc] initWithFrame:CGRectMake(.0f, 0.f, 5.f, 10.f)];
    [inset setUserInteractionEnabled: NO];
    [textField setLeftView: inset];
    [textField setLeftViewMode: UITextFieldViewModeAlways];
    
    return textField;
}

- (void)showServicePickerModalViewForTextField: (UITextField *)textField
{
    AKLabelViewCompletionHandler handler = ^(ABPropertyID property, ABMultiValueIdentifier identifier, NSString *service){
        
        NSDictionary *serviceDict = [self.controller.contact valueForMultiValueProperty: kABPersonInstantMessageProperty andIdentifier: identifier];
        if (serviceDict == nil)
        {
            serviceDict = [[NSDictionary alloc] init];
        }
        NSMutableDictionary *mutableServiceDict = [serviceDict mutableCopy];
        [mutableServiceDict setObject: service forKey: (NSString *)kABPersonInstantMessageServiceKey];
        serviceDict = [mutableServiceDict copy];
        NSString *label = [self.controller.contact labelForMultiValueProperty: kABPersonInstantMessageProperty andIdentifier: identifier];
        [self.controller.contact setValue: serviceDict andLabel: label forMultiValueProperty: kABPersonInstantMessageProperty andIdentifier: &identifier];
        
        [textField setText: service];
    };
    
    NSDictionary *serviceDict = [self.controller.contact valueForMultiValueProperty: kABPersonInstantMessageProperty andIdentifier: (ABMultiValueIdentifier)self.tag];
    
    NSString *service = (self.tag != NSNotFound) ? [serviceDict objectForKey: (NSString *)kABPersonInstantMessageServiceKey] : (NSString *)kABPersonInstantMessageServiceSkype;
    
    AKLabelViewController *labelView = [[AKLabelViewController alloc] initForInstantMessageServiceWithSelectedService: service andCompletionHandler: handler];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController: labelView];
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    [self.controller.navigationController presentViewController: navigationController animated: YES completion: nil];
#else
    [self.controller.navigationController presentModalViewController: navigationController animated: YES];
#endif
}

#pragma mark - Class methods

+ (UITableViewCell *)cellWithController: (AKContactViewController *)controller atRow: (NSInteger)row
{
    static NSString *CellIdentifier = @"AKContactInstantMessageViewCell";
    
    AKContactInstantMessageViewCell *cell = [controller.tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    if (cell == nil)
    {
        cell = [[AKContactInstantMessageViewCell alloc] initWithStyle: UITableViewCellStyleValue2 reuseIdentifier: CellIdentifier];
    }
    
    [cell setController: controller];
    
    [cell configureCellAtRow: row];
    
    return (UITableViewCell *)cell;
}

+ (UIView *)separatorWithTag: (SeparatorTag)tag
{
    UIView *separator = [[UIView alloc] initWithFrame: CGRectZero];
    [separator setBackgroundColor: [UIColor lightGrayColor]];
    [separator setTag: tag];
    [separator setAutoresizingMask: UIViewAutoresizingNone];
    
    return separator;
}

+ (NSString *)descriptionForInstantMessageTag: (InstantMessageTag)tag
{
    switch (tag) {
        case kIMUsername: return (NSString *)kABPersonInstantMessageUsernameKey;
        case kIMService: return (NSString *)kABPersonInstantMessageServiceKey;
        default: return @"";
    }
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField.tag == kIMService)
    {
        [self showServicePickerModalViewForTextField: textField];
        return NO;
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self.controller setFirstResponder: textField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if ([textField isFirstResponder])
        [textField resignFirstResponder];
    
    [self.controller setFirstResponder: nil];
    
    if ([textField.text length] == 0) return;
    
    AKContact *contact = self.controller.contact;
    
    NSString *key = [AKContactInstantMessageViewCell descriptionForInstantMessageTag: textField.tag];
    
    NSDictionary *service = [contact valueForMultiValueProperty: kABPersonInstantMessageProperty andIdentifier: (ABMultiValueIdentifier)self.tag];
    if (service == nil)
    {
        NSDictionary *newService = [[NSDictionary alloc] initWithObjectsAndKeys: textField.text, key, nil];
        ABMultiValueIdentifier identifier = (ABMultiValueIdentifier)self.tag;
        NSString *label = [AKLabel defaultLabelForABPropertyID: kABPersonInstantMessageProperty];
        [contact setValue: newService andLabel: label forMultiValueProperty: kABPersonInstantMessageProperty andIdentifier: &identifier];
        [self setTag: identifier];
        // service = [contact valueForMultiValueProperty: kABPersonInstantMessageProperty andIdentifier: self.tag];
    }
    else
    {
        NSMutableDictionary *mutableService = [service mutableCopy];
        [mutableService setObject: textField.text forKey: key];
        service = [mutableService copy];
        ABMultiValueIdentifier identifier = (ABMultiValueIdentifier)self.tag;
        NSString *label = [contact labelForMultiValueProperty: kABPersonInstantMessageProperty andIdentifier: identifier];
        [contact setValue: service andLabel: label forMultiValueProperty: kABPersonInstantMessageProperty andIdentifier: &identifier];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([textField isFirstResponder])
        [textField resignFirstResponder];
    return YES;
}

@end
