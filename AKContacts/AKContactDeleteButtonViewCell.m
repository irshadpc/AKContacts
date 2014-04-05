//
//  AKContactDeleteButtonViewCell.m
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

#import "AKContactDeleteButtonViewCell.h"
#import "AKAddressBook.h"
#import "AKContact.h"
#import "AKContactViewController.h"

@interface AKContactDeleteButtonViewCell () <UIActionSheetDelegate>

@property (unsafe_unretained, nonatomic) AKContactViewController *controller;

-(void)configureCell;

@end

@implementation AKContactDeleteButtonViewCell

+ (UITableViewCell *)cellWithController:(AKContactViewController *)controller atRow:(NSInteger)row
{
    static NSString *CellIdentifier = @"AKContactDeleteButtonViewCell";
    
    AKContactDeleteButtonViewCell *cell = [controller.tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    if (cell == nil)
    {
        cell = [[AKContactDeleteButtonViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: CellIdentifier];
    }
    
    [cell setController: controller];
    
    [cell configureCell];
    
    return (UITableViewCell *)cell;
}

- (void)configureCell
{
    [self setSelectionStyle: UITableViewCellSelectionStyleNone];
    [self setBackgroundColor: [UIColor clearColor]];
    [self setBackgroundView: [[UIView alloc] initWithFrame: CGRectZero]];
    
    for (UIView *subView in [self.contentView subviews])
    {
        [subView removeFromSuperview];
    }
    
    CGRect frame = self.frame;
    frame.origin.x = 10.f;
    frame.size.width = frame.size.width - 20.f;
    
    UIButton *button = nil;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        button = [UIButton buttonWithType: UIButtonTypeSystem];
        [button setTintColor: [UIColor redColor]];
    }
    else
    {
        button = [UIButton buttonWithType: UIButtonTypeCustom];
        [button setBackgroundColor: [UIColor clearColor]];
        [button setAutoresizingMask: UIViewAutoresizingFlexibleWidth];
        UIImage *image = [[UIImage imageNamed: @"ButtonDelete.png"] stretchableImageWithLeftCapWidth: 4 topCapHeight: 0];
        [button setBackgroundImage: image forState: UIControlStateNormal];
        [button addTarget: self action: @selector(deleteButtonTouchUpInside:) forControlEvents: UIControlEventTouchUpInside];
        
        [button.titleLabel setFont: [UIFont boldSystemFontOfSize: 22.f]];
        [button.titleLabel setShadowOffset: CGSizeMake(0.f, -1.f)];
        [button.titleLabel setShadowColor: [UIColor grayColor]];
    }
    [button setFrame: frame];
    [button addTarget: self action: @selector(deleteButtonTouchUpInside:) forControlEvents: UIControlEventTouchUpInside];
    [button setTitle: NSLocalizedString(@"Delete Contact", @"") forState: UIControlStateNormal];
    
    [self addSubview: button];
}

- (void)deleteButtonTouchUpInside: (id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle: nil
                                                             delegate: self
                                                    cancelButtonTitle: NSLocalizedString(@"Cancel", @"")
                                               destructiveButtonTitle: NSLocalizedString(@"Delete Contact", @"")
                                                    otherButtonTitles: nil];
    [actionSheet showInView: self.controller.view];
}

#pragma mark - UIActionSheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.destructiveButtonIndex)
    {
        [[AKAddressBook sharedInstance] deleteRecordID: self.controller.contact.recordID];
        if ([self.controller.delegate respondsToSelector: @selector(recordDidRemoveWithContactID:)])
        {
            [self.controller.delegate recordDidRemoveWithContactID: self.controller.contact.recordID];
        }
        [self.controller.navigationController popViewControllerAnimated: YES];
    }
}

@end
