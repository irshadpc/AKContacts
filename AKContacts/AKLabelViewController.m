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
#import "AKLabelViewCell.h"
#import "AKLabel.h"
#import "AppDelegate.h"

@interface AKLabelViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, assign) NSInteger identifier;
@property (nonatomic, copy) AKLabelViewCompletionHandler handler;

/**
 * Keyboard notification handlers
 */
- (void)keyboardWillShow: (NSNotification *)notification;
- (void)keyboardWillHide: (NSNotification *)notification;
- (void)editButtonTouchUpInside: (id)sender;
- (void)cancelButtonTouchUpInside: (id)sender;
/**
 * Touch gesture recognizer handler attached to tableView in edit mode
 */
- (void)tableViewTouchUpInside: (id)sender;

@end

@implementation AKLabelViewController

- (id)initWithPropertyID: (ABPropertyID)property andIdentifier: (NSInteger)identifier andSelectedLabel: (NSString *)selectedLabel andCompletionHandler: (AKLabelViewCompletionHandler)handler
{
  self = [self init];
  if (self)
  {
    _property = property;
    _identifier = identifier;
    _handler = [handler copy];

    _labels = [[NSMutableArray alloc] init];
    NSMutableArray *standardLabels = [[NSMutableArray alloc] init];
    [_labels addObject: standardLabels];

    AKLabel *label = nil;
    CFStringRef abLabel = NULL;
    if (property == kABPersonPhoneProperty)
    {
      abLabel = kABPersonPhoneMobileLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABPersonPhoneIPhoneLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABHomeLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABWorkLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABOtherLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABPersonPhoneMainLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABPersonPhoneHomeFAXLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABPersonPhoneWorkFAXLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      if ((SYSTEM_VERSION_GREATER_THAN(@"5.0")))
      {
        abLabel = kABPersonPhoneOtherFAXLabel;
        label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
        [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
        [standardLabels addObject: label];
      }
      abLabel = kABPersonPhonePagerLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
    }
    else if (property == kABPersonURLProperty)
    {
      abLabel = kABPersonHomePageLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABHomeLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABWorkLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABOtherLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
    }
    else if (property == kABPersonDateProperty)
    {
      abLabel = kABPersonAnniversaryLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABOtherLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
    }
    else if (property == kABPersonSocialProfileProperty)
    {
      abLabel = kABPersonSocialProfileServiceFacebook;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABPersonSocialProfileServiceTwitter;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABPersonSocialProfileServiceFlickr;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABPersonSocialProfileServiceLinkedIn;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABPersonSocialProfileServiceMyspace;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABPersonSocialProfileServiceSinaWeibo;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
    }
    else if (property == kABPersonRelatedNamesProperty)
    {
      abLabel = kABPersonMotherLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABPersonFatherLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABPersonParentLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABPersonBrotherLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABPersonSisterLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABPersonChildLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABPersonFriendLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABPersonSpouseLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABPersonAssistantLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABPersonManagerLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABOtherLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
    }
    else
    {
      abLabel = kABHomeLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABWorkLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
      abLabel = kABOtherLabel;
      label = [[AKLabel alloc] initWithLabel: (__bridge NSString *)(abLabel) andIsStandard: YES];
      [label setSelected: ([selectedLabel compare: (__bridge NSString *)(abLabel)] == NSOrderedSame) ? YES : NO];
      [standardLabels addObject: label];
    }
    
    NSString *key = [NSString stringWithFormat: defaultsLabelKey, property];
    NSMutableArray *tmpLabels = [[[NSUserDefaults standardUserDefaults] arrayForKey: key] mutableCopy];
    NSMutableArray *customLabels = [[NSMutableArray alloc] init];
    for (NSString *tmpLabel in tmpLabels)
    {
      AKLabel *label = [[AKLabel alloc] initWithLabel: tmpLabel andIsStandard: NO];
      [label setSelected: ([selectedLabel compare: tmpLabel] == NSOrderedSame) ? YES : NO];
      [customLabels addObject: label];
    }
    [_labels addObject: customLabels];
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  [self.navigationItem setRightBarButtonItem: self.editButtonItem];

  CGFloat height = ([UIScreen mainScreen].bounds.size.height == 568.f) ? 568.f : 480.f;
  height -= (self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height);
  [self setTableView: [[UITableView alloc] initWithFrame: CGRectMake(0.f, 0.f, 320.f, height)
                                                   style: UITableViewStyleGrouped]];
  [self.tableView setDataSource: self];
  [self.tableView setDelegate: self];
  [self setView: self.tableView];

  UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemEdit
                                                                             target: self
                                                                             action: @selector(editButtonTouchUpInside:)];
  [self.navigationItem setRightBarButtonItem: addButton];

  UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
                                                                                 target: self
                                                                                 action: @selector(cancelButtonTouchUpInside:)];
  [self.navigationItem setLeftBarButtonItem: barButtonItem];  
}

#pragma mark - Button Delegate Methods

- (void)setEditing:(BOOL)editing animated:(BOOL)animate
{
  [super setEditing: editing animated: YES];
  [self.tableView setEditing: editing animated: animate];

  if (self.editing == YES)
  {
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(keyboardWillShow:)
                                                 name: UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(keyboardWillHide:)
                                                 name: UIKeyboardWillHideNotification object:nil];

    NSInteger rows = [[self.labels objectAtIndex: kCustomSection] count];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow: rows inSection: kCustomSection];
    [self.tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
                          withRowAnimation: UITableViewRowAnimationTop];
    
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                                   target: self
                                                                                   action: @selector(editButtonTouchUpInside:)];
    [self.navigationItem setRightBarButtonItem: barButtonItem];
  }
  else
  {
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemEdit
                                                                                   target: self
                                                                                   action: @selector(editButtonTouchUpInside:)];
    [self.navigationItem setRightBarButtonItem: barButtonItem];

    [[NSNotificationCenter defaultCenter] removeObserver: self name: UIKeyboardWillShowNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: UIKeyboardWillHideNotification object: nil];

    NSMutableArray *labels = [self.labels objectAtIndex: kCustomSection];

    NSInteger row = 0;
    for (AKLabel *label in labels)
    {
      if (label.status == kLabelStatusDeleting ||
          label.status == kLabelStatusCreating)
        continue;
      row += 1;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow: row inSection: kCustomSection];

    [self.tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
                          withRowAnimation: UITableViewRowAnimationTop];
  }
}

- (void)editButtonTouchUpInside: (id)sender
{
  [self.view endEditing: YES];

  [self.tableView beginUpdates];
  [self setEditing: !self.editing animated: YES];
  
  if (self.editing == NO)
  {
    [self.tableView insertRowsAtIndexPaths: [self indexPathsOfCreatedLabels]
                          withRowAnimation: UITableViewRowAnimationAutomatic];
    
    [self commitLabels];
    
    BOOL haveSelected = NO;
    for (NSArray *labels in self.labels)
    {
      for (AKLabel *label in labels)
      {
        if (label.selected == YES)
        {
          haveSelected = YES;
          break;
        }
      }
    }
    if (haveSelected == NO)
    {
      [self.navigationItem.leftBarButtonItem setEnabled: NO];
    }
  }
  [self.tableView endUpdates];
}

- (void)cancelButtonTouchUpInside: (id)sender
{
  if (self.editing == NO)
  {
    if ([self.navigationController respondsToSelector: @selector(dismissViewControllerAnimated:completion:)])
      [self.navigationController dismissViewControllerAnimated: YES completion: nil];
    else
      [self.navigationController dismissModalViewControllerAnimated: YES];
  }
  else
  {
    [self.tableView beginUpdates];
    [self setEditing: NO animated: YES];
    
    NSMutableArray *insertIndexes = [[NSMutableArray alloc] init];
    
    NSMutableArray *reloadIndexes = [[NSMutableArray alloc] init];
    
    for (AKLabel *akLabel in [self.labels objectAtIndex: kCustomSection])
    {
      [insertIndexes addObjectsFromArray: [self indexPathsOfDeletedLabels]];
      [reloadIndexes addObjectsFromArray: [self indexPathsOfLabelsOutOfPosition]];

      [self revertLabels];
    }

    [self.tableView reloadRowsAtIndexPaths: reloadIndexes withRowAnimation: UITableViewRowAnimationAutomatic];
    [self.tableView insertRowsAtIndexPaths: insertIndexes withRowAnimation: UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
  }
}

- (void)tableViewTouchUpInside: (id)sender
{
  [self.view endEditing: YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return [self.labels count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  NSInteger count = [[self.labels objectAtIndex: section] count];

  if (section == kCustomSection)
  {
    count = 0;

    for (AKLabel *label in [self.labels objectAtIndex: kCustomSection])
    {
      if (label.status == kLabelStatusCreating || label.status == kLabelStatusDeleting)
        continue;
      count += 1;
    }
    if (self.editing) count += 1;
  }

  return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";

  AKLabelViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[AKLabelViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }

  [cell setParent: self];

  [cell configureCellAtIndexPath: indexPath];

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
  if (indexPath.section == kCustomSection)
  {
    if (indexPath.row < [[self.labels objectAtIndex: kCustomSection] count])
    {
      return UITableViewCellEditingStyleDelete;
    }
    else
    {
      return UITableViewCellEditingStyleInsert;
    }
  }
  return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete)
  {
    NSInteger row = 0;
    for (AKLabel *akLabel in [self.labels objectAtIndex: kCustomSection])
    {
      NSInteger index = [[self.labels objectAtIndex: kCustomSection] indexOfObject: akLabel];
      if (akLabel.status == kLabelStatusDeleting)
      {
        continue;
      }
      else if (index == indexPath.row)
      {
        [akLabel setStatus: kLabelStatusDeleting];
        break;
      }
      row += 1;
    }
    
    indexPath = [NSIndexPath indexPathForRow: row inSection: indexPath.section];
    
    [tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject:indexPath] withRowAnimation: UITableViewRowAnimationFade];
  }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
  NSMutableArray *labels = [self.labels objectAtIndex: kCustomSection];

  [labels exchangeObjectAtIndex: fromIndexPath.row withObjectAtIndex: toIndexPath.row];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == kCustomSection)
  {
    if (indexPath.row < [[self.labels objectAtIndex: kCustomSection] count])
    {
      return YES;
    }
  }

  return NO;
}

#pragma mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
  NSInteger row = 1;
  if (sourceIndexPath.section != proposedDestinationIndexPath.section)
  {
    if (sourceIndexPath.section < proposedDestinationIndexPath.section)
    {
      row = [tableView numberOfRowsInSection: sourceIndexPath.section] - 2;
    }
  }
  else
  {
    if (proposedDestinationIndexPath.row == [tableView numberOfRowsInSection: sourceIndexPath.section] - 1)
    {
      row = [tableView numberOfRowsInSection: sourceIndexPath.section] - 2;
    }
    else
    {
      row = proposedDestinationIndexPath.row;
    }
  }
  return [NSIndexPath indexPathForRow: row inSection: sourceIndexPath.section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (self.editing == NO)
  {
    for (NSMutableArray *array in self.labels)
    {
      for (AKLabel *akLabel in array)
      {
        [akLabel setSelected: NO];
      }
    }

    AKLabel *akLabel = [[self.labels objectAtIndex: indexPath.section] objectAtIndex: indexPath.row];
    [akLabel setSelected: YES];

    [self.tableView reloadData];

    if (self.handler) self.handler(self.property, self.identifier, akLabel.label);

    double delayInSeconds = 0.3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
      [self cancelButtonTouchUpInside: nil];
    });
  }

  [tableView deselectRowAtIndexPath: indexPath animated: YES];
}

#pragma mark - Keyboard

- (void)keyboardWillShow: (NSNotification *)notification
{
  UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                               action: @selector(tableViewTouchUpInside:)];
  [recognizer setCancelsTouchesInView: NO];
  [self.tableView addGestureRecognizer: recognizer];
  [self setTapGestureRecognizer: recognizer];
  
  NSDictionary* info = [notification userInfo];
  CGSize kbSize = [[info objectForKey: UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
  
  UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.f, 0.f, kbSize.height, 0.f);
  [self.tableView setContentInset: contentInsets];
  [self.tableView setScrollIndicatorInsets: contentInsets];
  
  CGFloat offset = self.tableView.contentOffset.y;
  CGRect textFieldFrame = self.firstResponder.frame;
  CGFloat textFieldOrigin = self.firstResponder.superview.superview.frame.origin.y - offset;
  CGFloat textFieldBottom = textFieldOrigin + textFieldFrame.origin.y + textFieldFrame.size.height;
  CGRect visibleFrame = self.view.frame;
  visibleFrame.size.height -= kbSize.height;
  
  CGFloat keyboardTop = visibleFrame.size.height;
  CGPoint point = CGPointMake(textFieldFrame.origin.x, textFieldBottom);
  
  if (CGRectContainsPoint(visibleFrame, point) == NO)
  {
    CGFloat posY = fabs(textFieldBottom - keyboardTop) + 10.f + offset;
    CGPoint scrollPoint = CGPointMake(0.f, posY);
    [self.tableView setContentOffset: scrollPoint animated: YES];
  }
}

- (void)keyboardWillHide: (NSNotification *)notification
{
  [self.tableView removeGestureRecognizer: self.tapGestureRecognizer];
  
  UIEdgeInsets contentInsets = UIEdgeInsetsZero;
  [self.tableView setContentInset: contentInsets];
  [self.tableView setScrollIndicatorInsets: contentInsets];
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Data Source

- (void)commitLabels
{
  NSMutableArray *labels = [self.labels objectAtIndex: kCustomSection];
  
  NSMutableArray *labelsToRemove = [[NSMutableArray alloc] init];
  
  NSMutableArray *array = [[NSMutableArray alloc] init];
  for (AKLabel *akLabel in labels)
  {
    if (akLabel.status == kLabelStatusDeleting)
    {
      [labelsToRemove addObject: akLabel];
      continue;
    }
    else if (akLabel.status == kLabelStatusCreating)
    {
      [akLabel setStatus: kLabelStatusNormal];
    }

    [array addObject: akLabel.label];
  }
  [labels removeObjectsInArray: labelsToRemove];

  NSString *key = [NSString stringWithFormat: defaultsLabelKey, self.property];
  [[NSUserDefaults standardUserDefaults] setValue: array forKey: key];
}

- (void)revertLabels
{
  // Unmark any groups marked for removal
  
  NSMutableArray *labels = [self.labels objectAtIndex: kCustomSection];

  for (AKLabel *akLabel in labels)
  {
    if (akLabel.status == kLabelStatusDeleting)
    {
      akLabel.status = kLabelStatusNormal;
    }
  }
}

- (void)revertGroupsOrder
{
  NSMutableArray *labels = [self.labels objectAtIndex: kCustomSection];

  NSString *labelKey = [NSString stringWithFormat: defaultsLabelKey, self.property];
  NSArray *order = [[NSUserDefaults standardUserDefaults] arrayForKey: labelKey];

  if (order != nil)
  {
    [labels sortUsingComparator: ^NSComparisonResult(id obj1, id obj2)
     {
       NSString *label1 = [(AKLabel *)obj1 label];
       NSString *label2 = [(AKLabel *)obj2 label];

       return [label1 compare: label2];
     }];
  } else {
    [self commitLabels];
  }
}

- (NSArray *)indexPathsOfLabelsOutOfPosition
{
  NSMutableArray *labels = [self.labels objectAtIndex: kCustomSection];

  NSString *labelKey = [NSString stringWithFormat: defaultsLabelKey, self.property];
  NSArray *order = [[NSUserDefaults standardUserDefaults] arrayForKey: labelKey];
  
  NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
  
  NSInteger removedLabels = 0;
  
  for (AKLabel *akLabel in labels)
  {
    if (akLabel.status == kLabelStatusDeleting)
    {
      removedLabels += 1;
    }
    else
    {
      NSInteger index = [order indexOfObject: akLabel.label];
      
      NSInteger currentIndex = [labels indexOfObject: akLabel.label];
      if (currentIndex != NSNotFound && index != NSNotFound && index != currentIndex)
      {
        [indexPaths addObject: [NSIndexPath indexPathForRow: currentIndex - removedLabels
                                                  inSection: kCustomSection]];
      }
    }
  }
  
  return [[NSArray alloc] initWithArray: indexPaths];
}

- (NSArray *)indexPathsOfDeletedLabels
{
  NSMutableArray *labels = [self.labels objectAtIndex: kCustomSection];
  
  NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
  
  for (AKLabel *akLabel in labels)
  {
    if (akLabel.status == kLabelStatusDeleting)
    {
      [indexPaths addObject: [NSIndexPath indexPathForRow: [labels indexOfObject: akLabel]
                                                inSection: kCustomSection]];
    }
  }
  return [[NSArray alloc] initWithArray: indexPaths];
}

- (NSArray *)indexPathsOfCreatedLabels
{
  NSMutableArray *labels = [self.labels objectAtIndex: kCustomSection];
  
  NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
  
  NSInteger removedLabels = 0;
  
  for (AKLabel *akLabel in labels)
  {
    if (akLabel.status == kLabelStatusCreating)
    {
      NSInteger row = [labels count] - removedLabels - 1;
      NSIndexPath *indexPath = [NSIndexPath indexPathForRow: row inSection: kCustomSection];
      [indexPaths addObject: indexPath];
    }
    else if (akLabel.status == kLabelStatusDeleting)
    {
      removedLabels += 1;
    }
  }
  return [[NSArray alloc] initWithArray: indexPaths];
}

@end
