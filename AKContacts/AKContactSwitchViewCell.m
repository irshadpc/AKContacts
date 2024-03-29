//
//  AKContactSwitchViewCell.m
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

#import "AKContactSwitchViewCell.h"
#import "AKContact.h"
#import "AKContactViewController.h"

@interface AKContactSwitchViewCell ()

@property (unsafe_unretained, nonatomic) AKContactViewController *controller;
@property (assign, nonatomic) NSInteger identifier;

- (void)configureCellAtRow:(NSInteger)row;

@end

@implementation AKContactSwitchViewCell

+ (UITableViewCell *)cellWithController: (AKContactViewController *)controller atRow: (NSInteger)row
{
    static NSString *CellIdentifier = @"AKContactSwitchViewCell";
    
    AKContactSwitchViewCell *cell = [controller.tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    if (cell == nil)
    {
        cell = [[AKContactSwitchViewCell alloc] initWithStyle: UITableViewCellStyleValue2 reuseIdentifier: CellIdentifier];
    }
    
    [cell setController: controller];
    
    [cell configureCellAtRow: row];
    
    return (UITableViewCell *)cell;
}

- (void)configureCellAtRow: (NSInteger)row {
    
    [self setIdentifier: NSNotFound];
    [self.textLabel setText: nil];
    [self.detailTextLabel setText: nil];
    [self setSelectionStyle: UITableViewCellSelectionStyleNone];
    
    [self.detailTextLabel setText: NSLocalizedString(@"Switch", @"")];
    
    UISwitch *sw = [[UISwitch alloc] initWithFrame: CGRectZero];
    [sw addTarget: self action:@selector(uiSwitchDidChangeValue:) forControlEvents: UIControlEventValueChanged];
    [self setAccessoryView: sw];
}

#pragma mark - UISwitch

- (void)uiSwitchDidChangeValue: (id)sender {
    
}

@end
