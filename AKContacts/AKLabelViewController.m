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
@property (nonatomic, strong) NSMutableArray *labels;
@property (nonatomic, assign) ABPropertyID property;
@property (nonatomic, assign) NSInteger identifier;
@property (nonatomic, copy) AKLabelViewCompletionHandler handler;
@property (nonatomic, copy) NSString *selectedLabel;

@end

@implementation AKLabelViewController

- (id)initWithPropertyID: (ABPropertyID)property andIdentifier: (NSInteger)identifier andSelectedLabel: (NSString *)selectedLabel andCompletionHandler: (AKLabelViewCompletionHandler)handler
{
  self = [self init];
  if (self)
  {
    self.property = property;
    self.identifier = identifier;
    self.handler = handler;
    self.selectedLabel = selectedLabel;
    
    self.labels = [[NSMutableArray alloc] init];
    NSMutableArray *standardLabels = [[NSMutableArray alloc] init];
    [self.labels addObject: standardLabels];

    NSArray *label = nil;
    CFStringRef abLabel = NULL;
    if (property == kABPersonPhoneProperty)
    {
      abLabel = kABPersonPhoneMobileLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABPersonPhoneIPhoneLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABHomeLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABWorkLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABOtherLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABPersonPhoneMainLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABPersonPhoneHomeFAXLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABPersonPhoneWorkFAXLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      if ((SYSTEM_VERSION_GREATER_THAN(@"5.0")))
      {
        abLabel = kABPersonPhoneOtherFAXLabel;
        label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
        [standardLabels addObject: label];
      }
      abLabel = kABPersonPhonePagerLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
    }
    else if (property == kABPersonURLProperty)
    {
      abLabel = kABPersonHomePageLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABHomeLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABWorkLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABOtherLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
    }
    else if (property == kABPersonDateProperty)
    {
      abLabel = kABPersonAnniversaryLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABOtherLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
    }
    else if (property == kABPersonSocialProfileProperty)
    {
      abLabel = kABPersonSocialProfileServiceFacebook;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABPersonSocialProfileServiceTwitter;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABPersonSocialProfileServiceFlickr;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABPersonSocialProfileServiceLinkedIn;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABPersonSocialProfileServiceMyspace;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABPersonSocialProfileServiceSinaWeibo;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
    }
    else if (property == kABPersonRelatedNamesProperty)
    {
      abLabel = kABPersonMotherLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABPersonFatherLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABPersonParentLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABPersonBrotherLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABPersonSisterLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABPersonChildLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABPersonFriendLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABPersonSpouseLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABPersonAssistantLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABPersonManagerLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABOtherLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
    }
    else
    {
      abLabel = kABHomeLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABWorkLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
      abLabel = kABOtherLabel;
      label = [[NSArray alloc] initWithObjects: CFBridgingRelease(ABAddressBookCopyLocalizedLabel(abLabel)), abLabel, nil];
      [standardLabels addObject: label];
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
  return [self.labels count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [[self.labels objectAtIndex: section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }

  NSString *label = [[[self.labels objectAtIndex: indexPath.section] objectAtIndex: indexPath.row] objectAtIndex: 0];
  [cell.textLabel setText: label];

  NSString *abLabel = (NSString *)([[[self.labels objectAtIndex: indexPath.section] objectAtIndex: indexPath.row] objectAtIndex: 1]);
  if ([abLabel compare: self.selectedLabel] == NSOrderedSame)
  {
    [cell setAccessoryType: UITableViewCellAccessoryCheckmark];
  }
  else
  {
    [cell setAccessoryType: UITableViewCellAccessoryNone];
  }

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
    NSString *abLabel = (NSString *)([[[self.labels objectAtIndex: indexPath.section] objectAtIndex: indexPath.row] objectAtIndex: 1]);
    [self setSelectedLabel: abLabel];
    
    [self.tableView reloadData];

    if (self.handler) self.handler(self.property, self.identifier, abLabel);

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
