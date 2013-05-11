//
//  AKLabelViewController.h
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

#import "AKLabelViewController.h"
#import "AppDelegate.h"

@interface AKLabelViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation AKLabelViewController

-(id)initWithPropertyID: (ABPropertyID)property
{
  self = [self init];
  if (self)
  {
    NSString *home = CFBridgingRelease(ABAddressBookCopyLocalizedLabel(kABHomeLabel));
    NSString *work = CFBridgingRelease(ABAddressBookCopyLocalizedLabel(kABWorkLabel));
    NSString *other = CFBridgingRelease(ABAddressBookCopyLocalizedLabel(kABOtherLabel));

    self.dataSource = [[NSMutableArray alloc] init];
    
    if (property == kABPersonPhoneProperty)
    {
      [self.dataSource addObject: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(kABPersonPhoneMobileLabel))];
      [self.dataSource addObject: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(kABPersonPhoneIPhoneLabel))];
      [self.dataSource addObject: home];
      [self.dataSource addObject: work];
      [self.dataSource addObject: other];
      [self.dataSource addObject: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(kABPersonPhoneMainLabel))];
      [self.dataSource addObject: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(kABPersonPhoneHomeFAXLabel))];
      [self.dataSource addObject: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(kABPersonPhoneWorkFAXLabel))];
      if ((SYSTEM_VERSION_GREATER_THAN(@"5.0")))
      {
        [self.dataSource addObject: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(kABPersonPhoneOtherFAXLabel))];
      }
      [self.dataSource addObject: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(kABPersonPhonePagerLabel))];
    }
    else if (property == kABPersonURLProperty)
    {
      [self.dataSource addObject: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(kABPersonHomePageLabel))];
      [self.dataSource addObject: home];
      [self.dataSource addObject: work];
      [self.dataSource addObject: other];
    }
    else if (property == kABPersonDateProperty)
    {
      [self.dataSource addObject: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(kABPersonAnniversaryLabel))];
      [self.dataSource addObject: other];
    }
    else if (property == kABPersonRelatedNamesProperty)
    {
      [self.dataSource addObject: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(kABPersonMotherLabel))];
      [self.dataSource addObject: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(kABPersonFatherLabel))];
      [self.dataSource addObject: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(kABPersonParentLabel))];
      [self.dataSource addObject: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(kABPersonBrotherLabel))];
      [self.dataSource addObject: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(kABPersonSisterLabel))];
      [self.dataSource addObject: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(kABPersonChildLabel))];
      [self.dataSource addObject: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(kABPersonFriendLabel))];
      [self.dataSource addObject: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(kABPersonSpouseLabel))];
      [self.dataSource addObject: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(kABPersonPartnerLabel))];
      [self.dataSource addObject: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(kABPersonAssistantLabel))];
      [self.dataSource addObject: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(kABPersonManagerLabel))];
      [self.dataSource addObject: other];
    }
    else
    {
      [self.dataSource addObject: home];
      [self.dataSource addObject: work];
      [self.dataSource addObject: other];
    }
  }
  return self;
 
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  [self.navigationItem setRightBarButtonItem: self.editButtonItem];

  CGFloat height = ([UIScreen mainScreen].bounds.size.height == 568.0) ? 568.0 : 480.0;
  height -= (self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height);
  [self setTableView: [[UITableView alloc] initWithFrame: CGRectMake(0.f, 0.f, 320.f, height)
                                                   style: UITableViewStyleGrouped]];
  [self.tableView setDataSource: self];
  [self.tableView setDelegate: self];
  [self setView: self.tableView];

  UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonTouchUp:)];
  [self.navigationItem setLeftBarButtonItem: barButtonItem];  
}

#pragma mark - Button Delegate Methods

- (void)setEditing:(BOOL)editing animated:(BOOL)animate
{
  [super setEditing: editing animated: animate]; // Toggles Done button
  [self.tableView setEditing: editing animated: animate];
}

- (void)cancelButtonTouchUp: (id)sender
{
  if ([self.navigationController respondsToSelector: @selector(dismissViewControllerAnimated:completion:)])
    [self.navigationController dismissViewControllerAnimated: YES completion: nil];
  else
    [self.navigationController dismissModalViewControllerAnimated: YES];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  NSInteger ret = 1;
  
  return ret;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [self.dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }

  [cell.textLabel setText: [self.dataSource objectAtIndex: indexPath.row]];

  return (UITableViewCell *)cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  switch (indexPath.section)
  {
    default: return YES;
  }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete)
  {
  }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (self.editing == YES)
  {
    
  }
  else
  {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath: indexPath];
    [cell setAccessoryType: UITableViewCellAccessoryCheckmark];
    double delayInSeconds = 0.3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
      [self cancelButtonTouchUp: nil];
    });
  }
  
  [tableView deselectRowAtIndexPath: indexPath animated: YES];
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
