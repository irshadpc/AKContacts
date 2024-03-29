//
//  AKContactButtonsViewCell.m
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

#import "AKContactButtonsViewCell.h"
#import "AKAddressBook.h"
#import "AKContactViewController.h"
#import "AKContact.h"
#import "AKMessenger.h"
#import "AKGroupPickerViewController.h"

typedef NS_ENUM(NSInteger, ButtonTags) {
    kButtonText = 1,
    kButtonGroup,
};

@interface AKContactButtonsViewCell ()

@property (unsafe_unretained, nonatomic) AKContactViewController *controller;
@property (strong, nonatomic) UIButton *textButton;
@property (strong, nonatomic) UIButton *groupButton;

-(void)configureCellAtRow: (NSInteger)row;

@end

@implementation AKContactButtonsViewCell

+ (UITableViewCell *)cellWithController:(AKContactViewController *)controller atRow:(NSInteger)row
{
    static NSString *CellIdentifier = @"AKContactButtonsViewCell";
    
    AKContactButtonsViewCell *cell = [controller.tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    if (cell == nil)
    {
        cell = [[AKContactButtonsViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: CellIdentifier];
    }
    
    [cell setController: controller];
    
    [cell configureCellAtRow: row];
    
    return (UITableViewCell *)cell;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        UIColor *blue = [UIColor colorWithRed: .196f green: .3098f blue: .52f alpha: 1.f];
        BOOL iOS7 = SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0");
        if (iOS7)
        {
            blue = [UIColor colorWithRed: 0.f green: 0.478431 blue: 1.f alpha: 1.f];
        }
        
        UIButton *button = [UIButton buttonWithType: UIButtonTypeRoundedRect];
        [button setTag: kButtonText];
        [button setTitleColor: blue forState: UIControlStateNormal];
        [button.titleLabel setFont: [UIFont boldSystemFontOfSize: [UIFont systemFontSize]]];
        [button setTitle: NSLocalizedString(@"Send Message", @"") forState: UIControlStateNormal];
        [button addTarget: self action:@selector(buttonTouchUpInside:) forControlEvents: UIControlEventTouchUpInside];
        [self setTextButton: button];
        [self.contentView addSubview: self.textButton];
        
        button = [UIButton buttonWithType: UIButtonTypeRoundedRect];
        [button setTag: kButtonGroup];
        [button setTitleColor: blue forState: UIControlStateNormal];
        [button.titleLabel setFont: [UIFont boldSystemFontOfSize: [UIFont systemFontSize]]];
        [button setTitle: NSLocalizedString(@"Add to Group", @"") forState: UIControlStateNormal];
        [button addTarget: self action: @selector(buttonTouchUpInside:) forControlEvents: UIControlEventTouchUpInside];
        [self setGroupButton: button];
        [self.contentView addSubview: self.groupButton];
    }
    return self;
}

-(void)configureCellAtRow: (NSInteger)row
{
    [self.textLabel setText: nil];
    [self.detailTextLabel setText: nil];
    [self setSelectionStyle: UITableViewCellSelectionStyleNone];
    [self setBackgroundView: [[UIView alloc] initWithFrame:CGRectZero]];
}

- (void)layoutSubviews
{
    CGFloat posX = 10.f;
    CGFloat width = (self.contentView.bounds.size.width - 3.f * posX) / 2.f;
    CGRect frame = CGRectMake(posX, 0.f, width, self.frame.size.height);
    [self.textButton setFrame: frame];
    
    posX = width + 2.f * posX;
    frame = CGRectMake(posX, 0.f, width, self.frame.size.height);
    [self.groupButton setFrame: frame];
}

#pragma mark - UIButton

- (void)buttonTouchUpInside: (id)sender
{
    UIButton *button = (UIButton *)sender;
    if (button.tag == kButtonText)
    {
        AKContact *contact = self.controller.contact;
        NSInteger phoneCount = [contact countForMultiValueProperty: kABPersonPhoneProperty];
        NSInteger emailCount = [contact countForMultiValueProperty: kABPersonEmailProperty];
        
        AKMessenger *messanger = [AKMessenger sharedInstance];
        
        if (phoneCount == 1 && emailCount == 0)
        {
            ABMultiValueIdentifier identifier = [[[contact identifiersForMultiValueProperty: kABPersonPhoneProperty] objectAtIndex: 0] intValue];
            NSString *phoneNumber = [contact valueForMultiValueProperty: kABPersonPhoneProperty andIdentifier: identifier];
            [messanger sendTextWithRecipient: phoneNumber];
        }
        else if (phoneCount == 0 && emailCount == 1)
        {
            ABMultiValueIdentifier identifier = [[[contact identifiersForMultiValueProperty: kABPersonEmailProperty] objectAtIndex: 0] intValue];
            NSString *email = [contact valueForMultiValueProperty: kABPersonEmailProperty andIdentifier: identifier];
            [messanger sendEmailWithRecipients: [[NSArray alloc] initWithObjects: email, nil]];
        }
        else
        {
            [messanger showTextActionSheetWithContactID: self.controller.contact.recordID];
        }
    }
    else
    {
        AKGroupPickerViewController *groupSelectView = [[AKGroupPickerViewController alloc] initWithContactID: self.controller.contact.recordID];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController: groupSelectView];
        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
        [self.controller.navigationController presentViewController: navigationController animated: YES completion: nil];
#else
        [self.controller.navigationController presentModalViewController: navigationController animated: YES];
#endif
    }
}

@end
