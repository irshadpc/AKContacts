//
//  AKContactViewController.m
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

#import "AKContactViewController.h"
#import "AKContactHeaderViewCell.h"
#import "AKContactDetailViewCell.h"
#import "AKContactAddressViewCell.h"
#import "AKContactSwitchViewCell.h"
#import "AKContactButtonsViewCell.h"
#import "AKContactDeleteButtonViewCell.h"
#import "AKContactLinkedViewCell.h"
#import "AKContactInstantMessageViewCell.h"
#import "AKContact.h"
#import "AKLabel.h"
#import "AKLabelViewController.h"
#import "AKAddressBook.h"
#import "AKMessenger.h"

typedef NS_ENUM(NSInteger, SectionID) {
  kSectionHeader = 0,
  kSectionSwitch, // Custom
  kSectionPhone,
  kSectionEmail,
  kSectionURL,
  kSectionAddress,
  kSectionBirthday,
  kSectionDate,
  kSectionSocialProfile,
  kSectionInstantMessage,
  kSectionNote,
  kSectionButtons,
  kSectionLinkedRecords,
  kSectionDeleteButton,
};

static const float defaultCellHeight = 44.f;

@interface AKContactViewController ()

@property (strong, nonatomic) NSMutableArray *sections;
@property (strong, nonatomic) NSArray *sectionIdentifiers;
@property (strong, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

/**
 * Return the ABPropertyID of a section
 */
+ (ABPropertyID)abPropertyIDforSection: (SectionID)section;
/**
 * Return the number of entries in a section
 **/
- (NSInteger)numberOfElementsInSection: (NSInteger)section;
/**
 * Return YES if a section is editable, NO otherwise
 **/
-(BOOL)isSectionEditable: (NSInteger)section;
/**
 * Returns the index a section should be inserted at
 */
- (NSInteger)insertIndexForSection: (NSInteger)section;

@end

@implementation AKContactViewController

#pragma mark - Class methods

+ (BOOL)sectionIsMultiValue: (SectionID)section
{
  switch (section) {
    case kSectionPhone:
    case kSectionEmail:
    case kSectionURL:
    case kSectionAddress:
    case kSectionBirthday:
    case kSectionDate:
    case kSectionSocialProfile:
    case kSectionInstantMessage:
    case kSectionNote:
    {
      ABPropertyID property = [AKContactViewController abPropertyIDforSection: section];
      ABPropertyType type = ABPersonGetTypeOfProperty(property);
      if ((type & kABMultiValueMask) == kABMultiValueMask) return YES;
      return NO;
    }
    default: return NO;
  }
}

+ (ABPropertyID)abPropertyIDforSection: (SectionID)section
{
  switch (section) {
    case kSectionPhone: return kABPersonPhoneProperty;
    case kSectionEmail: return kABPersonEmailProperty;
    case kSectionURL: return kABPersonURLProperty;
    case kSectionAddress: return kABPersonAddressProperty;
    case kSectionBirthday: return kABPersonBirthdayProperty;
    case kSectionDate: return kABPersonDateProperty;
    case kSectionSocialProfile: return kABPersonSocialProfileProperty;
    case kSectionInstantMessage: return kABPersonInstantMessageProperty;
    case kSectionNote: return kABPersonNoteProperty;
    default: return kABInvalidPropertyType;
  }
}

#pragma mark - Custom methods

- (id)initWithContactID: (NSInteger)contactID
{
  self = [self init];
  if (self)
  {
    _contact = (contactID != tagNewContact) ? [[AKAddressBook sharedInstance] contactForContactId: contactID] : [[AKContact alloc] initWithABRecordID: tagNewContact];
    _parentLinkedContactID = NSNotFound;
  }
  return self;
}

- (NSInteger)numberOfElementsInSection: (NSInteger)section
{
  ABPropertyID property = [AKContactViewController abPropertyIDforSection: section];
  
  switch (section)
  {
    case kSectionPhone:
    case kSectionEmail:
    case kSectionURL:
    case kSectionAddress:
    case kSectionDate:
    case kSectionSocialProfile:
    case kSectionInstantMessage: return [self.contact countForProperty: property];

    case kSectionBirthday:
    case kSectionNote: return ([self.contact valueForProperty: property]) ? 1 : 0;
      
    case kSectionDeleteButton: return 0;
      
    case kSectionLinkedRecords: return [[self.contact linkedContactIDs] count];
    // If custom section does not default to having one element add case here
    default: return 1;
  }
}

- (BOOL)isSectionEditable: (NSInteger)section
{
  switch (section)
  {
    case kSectionSwitch:
    case kSectionButtons:
    case kSectionLinkedRecords:
      return NO;
    default:
      return YES;
  }
}

- (NSInteger)insertIndexForSection: (NSInteger)section
{
  for (NSInteger i = 0; i < [self.sections count]; ++i)
  {
    NSInteger aSection = [[self.sections objectAtIndex: i] integerValue];
    if (section < aSection)
      return i;
  }
  return [self.sections count];
}

#pragma mark - UIViewController

- (void)loadView
{
  [self setSections: [[NSMutableArray alloc] init]];
  [self.sections addObject: [NSNumber numberWithInteger: kSectionHeader]];
  [self.sections addObject: [NSNumber numberWithInteger: kSectionSwitch]];
  [self.sections addObject: [NSNumber numberWithInteger: kSectionPhone]];
  [self.sections addObject: [NSNumber numberWithInteger: kSectionEmail]];
  [self.sections addObject: [NSNumber numberWithInteger: kSectionURL]];
  [self.sections addObject: [NSNumber numberWithInteger: kSectionAddress]];
  [self.sections addObject: [NSNumber numberWithInteger: kSectionBirthday]];
  [self.sections addObject: [NSNumber numberWithInteger: kSectionDate]];
  [self.sections addObject: [NSNumber numberWithInteger: kSectionSocialProfile]];
  [self.sections addObject: [NSNumber numberWithInteger: kSectionInstantMessage]];
  [self.sections addObject: [NSNumber numberWithInteger: kSectionNote]];
  [self.sections addObject: [NSNumber numberWithInteger: kSectionButtons]];
  [self.sections addObject: [NSNumber numberWithInteger: kSectionLinkedRecords]];
  [self.sections addObject: [NSNumber numberWithInteger: kSectionDeleteButton]];
  [self setSectionIdentifiers: [self.sections copy]];

  CGFloat height = ([UIScreen mainScreen].bounds.size.height == 568.f) ? 568.f : 480.f;
  height -= (self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height);
  [self setTableView: [[UITableView alloc] initWithFrame: CGRectMake(0.f, 0.f, 320.f, height)
                                                   style: UITableViewStyleGrouped]];
  [self.tableView setDataSource: self];
  [self.tableView setDelegate: self];
  [self.tableView setAllowsSelectionDuringEditing: YES];

  [self setView: self.tableView];

  [self.navigationItem setRightBarButtonItem: self.editButtonItem];
  
  if (self.contact.recordID == tagNewContact)
  {
    [self.sections removeObject: [NSNumber numberWithInteger: kSectionDeleteButton]];
    [self setEditing: YES animated: NO];
  }
  else
  {
    NSMutableArray *sectionsToRemove = [[NSMutableArray alloc] init];
    for (NSNumber *section in self.sections)
    {
      if ([self numberOfElementsInSection: [section integerValue]] == 0)
        [sectionsToRemove addObject: section];
    }
    [self.sections removeObjectsInArray: sectionsToRemove];
  }
}

- (void)viewDidLoad
{
  [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear: (BOOL)animated
{
  [super viewWillAppear:animated];
  
  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(keyboardWillShow:)
                                               name: UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(keyboardWillHide:)
                                               name: UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];

  [[NSNotificationCenter defaultCenter] removeObserver: self name: UIKeyboardWillShowNotification object: nil];
  [[NSNotificationCenter defaultCenter] removeObserver: self name: UIKeyboardWillHideNotification object: nil];
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
  CGFloat cellBottom = textFieldOrigin + self.firstResponder.superview.superview.frame.size.height;
  CGRect visibleFrame = self.view.frame;
  visibleFrame.size.height -= kbSize.height;

  CGFloat keyboardTop = visibleFrame.size.height;
  CGPoint point = CGPointMake(textFieldFrame.origin.x, cellBottom);
  
  if (CGRectContainsPoint(visibleFrame, point) == NO)
  {
    CGFloat posY = fabs(cellBottom - keyboardTop) + 10.f + offset;
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

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return [self.sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  NSInteger ret = 0;

  section = [[self.sections objectAtIndex: section] integerValue];

  if (section == kSectionHeader)
  {
    ret = (self.editing) ? 3 : 1;
  }
  else
  {
    ret = [self numberOfElementsInSection: section];
    if (self.editing == YES)
    {
      if ([AKContactViewController sectionIsMultiValue: section]) ret += 1;
      else if (section == kSectionDeleteButton) ret += 1;
      else if (section == kSectionBirthday && [self.contact valueForProperty: kABPersonBirthdayProperty] == nil) ret += 1;
      else if (section == kSectionNote && [self.contact valueForProperty: kABPersonNoteProperty] == nil) ret += 1;
    }
  }
  return ret;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSInteger section = [[self.sections objectAtIndex: indexPath.section] integerValue];
  
  switch (section)
  {
    case kSectionHeader:
      return  (self.editing) ? defaultCellHeight : (defaultCellHeight + 30.f);

    case kSectionAddress:
      if (self.editing == NO)
      {
        return defaultCellHeight + 30.f;
      }
      else
      {
        if (indexPath.row < [self.contact countForProperty: kABPersonAddressProperty])
          return 120.f;
        else
          return (self.willAddAddress == YES) ? 120.f : defaultCellHeight;
      }

    case kSectionInstantMessage:
      return (self.editing == YES) ? defaultCellHeight + 40.f : defaultCellHeight;

    case kSectionNote:
      return ([self.contact valueForProperty: kABPersonNoteProperty]) ?
        [[self.contact valueForProperty: kABPersonNoteProperty] sizeWithFont: [UIFont systemFontOfSize: [UIFont systemFontSize]]
                                                           constrainedToSize: CGSizeMake(210.f, 120.f)
                                                               lineBreakMode: NSLineBreakByWordWrapping].height + 25.f : defaultCellHeight;

    default:
      return defaultCellHeight;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSInteger section = [[self.sections objectAtIndex: indexPath.section] integerValue];

  switch (section)
  {
    case kSectionHeader:
      return [AKContactHeaderViewCell cellWithDelegate: self atRow: indexPath.row];

    case kSectionPhone:
    case kSectionEmail:
    case kSectionURL:
    case kSectionBirthday:
    case kSectionDate:
    case kSectionSocialProfile:
    case kSectionNote:
      return [AKContactDetailViewCell cellWithDelegate: self
                                           andProperty: [AKContactViewController abPropertyIDforSection: section]
                                                 atRow: indexPath.row];

    case kSectionAddress:
      return [AKContactAddressViewCell cellWithDelegate: self atRow: indexPath.row];

    case kSectionInstantMessage:
      return [AKContactInstantMessageViewCell cellWithDelegate: self atRow: indexPath.row];

    case kSectionSwitch:
      return [AKContactSwitchViewCell cellWithDelegate: self atRow: indexPath.row];

    case kSectionButtons:
      return [AKContactButtonsViewCell cellWithDelegate: self atRow: indexPath.row];

    case kSectionLinkedRecords:
      return [AKContactLinkedViewCell cellWithDelegate: self atRow: indexPath.row];

    case kSectionDeleteButton:
      return [AKContactDeleteButtonViewCell cellWithDelegate: self atRow: indexPath.row];

    default:
      return nil;
  }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  section = [[self.sections objectAtIndex: section] integerValue];

  switch (section) {
    case kSectionLinkedRecords:
      return (self.editing) ? nil : NSLocalizedString(@"Linked Contacts", @"");
    default: return nil;
  }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSInteger section = [[self.sections objectAtIndex: indexPath.section] integerValue];

  switch (section)
  {
    case kSectionHeader:
    case kSectionDeleteButton:
    case kSectionButtons:
    case kSectionLinkedRecords:
      return NO;
    default:
      return YES;
  }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSInteger section = [[self.sections objectAtIndex: indexPath.section] integerValue];

  ABPropertyID property = [AKContactViewController abPropertyIDforSection: section];

  switch (section)
  {
    case kSectionPhone:
    case kSectionEmail:
    case kSectionURL:
    case kSectionDate:
    case kSectionSocialProfile:
    case kSectionInstantMessage:
      return (indexPath.row < [self.contact countForProperty: property]) ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;

    case kSectionAddress:
      if (indexPath.row < [self.contact countForProperty: kABPersonAddressProperty])
        return UITableViewCellEditingStyleDelete;
      else
        return (self.willAddAddress == YES) ? UITableViewCellEditingStyleNone : UITableViewCellEditingStyleInsert;
   
    case kSectionBirthday:
    case kSectionNote:
      return ([self.contact valueForProperty: property]) ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;

    default:
      return UITableViewCellEditingStyleNone;
  }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete)
  {
    NSInteger section = [[self.sections objectAtIndex: indexPath.section] integerValue];

    ABPropertyID property = [AKContactViewController abPropertyIDforSection: section];
    
    switch (section) {
      case kSectionPhone:
      case kSectionEmail:
      case kSectionAddress:
      case kSectionURL:
      case kSectionDate:
      case kSectionSocialProfile:
      case kSectionInstantMessage:
      {
        NSArray *identifiers = [self.contact identifiersForProperty: property];
        NSInteger identifier = [[identifiers objectAtIndex: indexPath.row] integerValue];
        [self.contact setValue: nil  andLabel: nil forMultiValueProperty: property andIdentifier: &identifier];
        break;
      }
      case kSectionBirthday:
      case kSectionNote:
        [self.contact setValue: nil forProperty: property];
    }

    [tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: indexPath] withRowAnimation: UITableViewRowAnimationAutomatic];
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSInteger section = [[self.sections objectAtIndex: indexPath.section] integerValue];
  
  if (self.editing == YES)
  {
    if ([AKContactViewController sectionIsMultiValue: section] == YES)
    {
      if (section == kSectionAddress && indexPath.row == [self.contact countForProperty: kABPersonAddressProperty])
      {
        if (self.willAddAddress == NO)
        {
          [self setWillAddAddress: YES];
          [self.tableView reloadRowsAtIndexPaths: [NSArray arrayWithObject: indexPath] withRowAnimation: UITableViewRowAnimationBottom];
        }
        else
        {
          [self showLabelPickerModalViewForIndexPath: indexPath];
        }
      }
      else
      {
        [self showLabelPickerModalViewForIndexPath: indexPath];
      }
    }
  }
  else
  {
    if (section == kSectionPhone)
    {
      NSArray *identifiers = [self.contact identifiersForProperty: kABPersonPhoneProperty];
      NSInteger identifier = [[identifiers objectAtIndex: indexPath.row] integerValue];
      NSString *value = [self.contact valueForMultiValueProperty: kABPersonPhoneProperty andIdentifier: identifier];
      value = [[value componentsSeparatedByCharactersInSet:
                                [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                               componentsJoinedByString: @""];
      NSURL *url = [[NSURL alloc] initWithString: [NSString stringWithFormat: @"tel:%@", value]];
      [[UIApplication sharedApplication] openURL: url];
    }
    else if (section == kSectionEmail)
    {
      NSArray *identifiers = [self.contact identifiersForProperty: kABPersonEmailProperty];
      NSInteger identifier = [[identifiers objectAtIndex: indexPath.row] integerValue];
      NSString *value = [self.contact valueForMultiValueProperty: kABPersonEmailProperty andIdentifier: identifier];
      [[AKMessenger sharedInstance] sendEmailWithRecipients: [[NSArray alloc] initWithObjects: value, nil]];
    }
    else if (section == kSectionURL) {
      NSArray *identifiers = [self.contact identifiersForProperty: kABPersonURLProperty];
      NSInteger identifier = [[identifiers objectAtIndex: indexPath.row] integerValue];
      NSString *url = [self.contact valueForMultiValueProperty: kABPersonURLProperty andIdentifier: identifier];
      [[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
    }
    else if (section == kSectionAddress)
    {
      NSArray *identifiers = [self.contact identifiersForProperty: kABPersonAddressProperty];
      NSInteger identifier = [[identifiers objectAtIndex: indexPath.row] integerValue];
      NSString *address = [self.contact addressForIdentifier: identifier andNumRows: NULL];
      address = [address stringByReplacingOccurrencesOfString: @"\n" withString: @" "];
      address = [address stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
      address = [NSString stringWithFormat: @"http://maps.apple.com/?q=%@", address];
      [[UIApplication sharedApplication] openURL: [NSURL URLWithString: address]];
    }
    else if (section == kSectionSocialProfile)
    {
      NSArray *identifiers = [self.contact identifiersForProperty: kABPersonSocialProfileProperty];
      NSInteger identifier = [[identifiers objectAtIndex: indexPath.row] integerValue];
      NSDictionary *dict = [self.contact valueForMultiValueProperty: kABPersonSocialProfileProperty andIdentifier: identifier];
      if ([dict objectForKey: (NSString *)kABPersonSocialProfileURLKey])
      {
        [[UIApplication sharedApplication] openURL: [NSURL URLWithString: [dict objectForKey: (NSString *)kABPersonSocialProfileURLKey]]];
      }
    }
    else if (section == kSectionLinkedRecords)
    {
      NSInteger recordId = [[[self.contact linkedContactIDs] objectAtIndex: indexPath.row] integerValue];
      
      if (self.parentLinkedContactID != recordId)
      {
        AKContactViewController *contactView = [[AKContactViewController alloc ] initWithContactID: recordId];
        [contactView setParentLinkedContactID: self.contact.recordID];
        [self.navigationController pushViewController: contactView animated: YES];
      }
      else
      {
        self.delegate = nil;
        [self.navigationController popViewControllerAnimated: YES];
      }
    }
  }
  [self.tableView deselectRowAtIndexPath: indexPath animated: YES];
}

- (void)showLabelPickerModalViewForIndexPath: (NSIndexPath *)indexPath
{
  NSInteger section = [[self.sections objectAtIndex: indexPath.section] integerValue];
  
  ABPropertyID property = [AKContactViewController abPropertyIDforSection: section];
  NSArray *identifiers = [self.contact identifiersForProperty: property];
  NSInteger identifier = (indexPath.row < [identifiers count]) ? [[identifiers objectAtIndex: indexPath.row] integerValue] : NSNotFound;
  
  AKLabelViewCompletionHandler handler = ^(ABPropertyID property, NSInteger identifier, NSString *label){
    
    id value = [self.contact valueForMultiValueProperty: property andIdentifier: identifier];
    if (value == nil)
    {
        if (property == kABPersonAddressProperty)
          value = [[NSDictionary alloc] init];
        else if (property == kABPersonDateProperty)
          value = [NSDate date];
        else
          value = @"";
    }
    [self.contact setValue: value andLabel: label forMultiValueProperty: property andIdentifier: &identifier];

    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath: indexPath];
    [cell setTag: identifier];
    [cell.textLabel setText: [self.contact localizedLabelForMultiValueProperty: property andIdentifier: identifier]];
  };

  NSString *label = (identifier != NSNotFound) ? [self.contact labelForMultiValueProperty: property andIdentifier: identifier] : [AKLabel defaultLabelForABPropertyID: property];
  
  AKLabelViewController *labelView = [[AKLabelViewController alloc] initWithPropertyID: property andIdentifier: identifier andSelectedLabel: label andCompletionHandler: handler];
  UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController: labelView];
  
  if ([self.navigationController respondsToSelector:@selector(presentViewController:animated:completion:)])
    [self.navigationController presentViewController: navigationController animated: YES completion: nil];
  else
    [self.navigationController presentModalViewController: navigationController animated: YES];

}

#pragma mark - Button Delegate Methods

- (void)setEditing:(BOOL)editing animated:(BOOL)animate
{
  [super setEditing: editing animated: animate]; // Toggles Done button
  [self.tableView setEditing: editing animated: animate];

  if (self.editing)
  {
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonTouchUpInside:)];
    [self.navigationItem setLeftBarButtonItem: barButtonItem];
  }
  else
  {
    [self.navigationItem setLeftBarButtonItem: nil];
    
    [self.view endEditing: YES]; // Resign first responders

    ABRecordID contactID = self.contact.recordID;
    
    [self.contact commit]; // ContactID changes from tagNewContact here

    [self setWillAddAddress: NO];

    if (contactID == tagNewContact)
    {
      if ([self.delegate respondsToSelector: @selector(modalViewDidDismissWithContactID:)])
        [self.delegate modalViewDidDismissWithContactID: self.contact.recordID];

      if ([self respondsToSelector: @selector(dismissViewControllerAnimated:completion:)])
        [self dismissViewControllerAnimated: YES completion: nil];
      else
        [self dismissModalViewControllerAnimated: YES];

      return;
    }
  }

  NSMutableIndexSet *reloadSet = [[NSMutableIndexSet alloc] init];
  NSMutableIndexSet *deleteSet = [[NSMutableIndexSet alloc] init];
  NSMutableIndexSet *insertSet = [[NSMutableIndexSet alloc] init];
  NSMutableArray *insertSections = [[NSMutableArray alloc] init];

  for (NSNumber *section in self.sectionIdentifiers)
  {    
    if (self.editing == YES)
    {
      if ([self.sections indexOfObject: section] != NSNotFound)
      {
        if ([self isSectionEditable: [section integerValue]] == YES)
          [reloadSet addIndex: [self.sections indexOfObject: section]];
        else
          [deleteSet addIndex: [self.sections indexOfObject: section]];
      }
      else
      {
        if (section.integerValue != kSectionDeleteButton || self.contact.recordID != tagNewContact)
        {
          [insertSections addObject: section];
        }
      }
    }
    else
    {
      if ([self.sections indexOfObject: section] != NSNotFound)
      {
        if ([self numberOfElementsInSection: [section integerValue]] == 0)
        {
          [deleteSet addIndex: [self.sections indexOfObject: section]];
        }
        else
        {
          [reloadSet addIndex: [self.sections indexOfObject: section]];
        }
      }
      else
      {
        if ([self isSectionEditable: [section integerValue]] == NO)
          [insertSections addObject: section];
      }
    }
  }

  [self.sections removeObjectsAtIndexes: deleteSet];

  /*
   * Insert indexes are determined assuming reload and delete operations have already taken place
   * From the UITableView Class Reference:
   * Note the behavior of this method when it is called in an animation block defined by the beginUpdates and
   * endUpdates methods. UITableView defers any insertions of rows or sections until after it has
   * handled the deletions of rows or sections. This happens regardless of ordering of the insertion and 
   * deletion method calls. This is unlike inserting or removing an item in a mutable array, where the 
   * operation can affect the array index used for the successive insertion or removal operation.
   */
  
  for (NSNumber *section in insertSections)
  {
    NSInteger index = [self insertIndexForSection: [section integerValue]];
    [insertSet addIndex: index];
    [self.sections insertObject: section atIndex: index];
  }
  
  [self.tableView beginUpdates];
  [self.tableView reloadSections: reloadSet withRowAnimation: UITableViewRowAnimationAutomatic];
  [self.tableView deleteSections: deleteSet withRowAnimation: UITableViewRowAnimationAutomatic];
  [self.tableView insertSections: insertSet withRowAnimation: UITableViewRowAnimationAutomatic];
  [self.tableView endUpdates];
}

- (void)cancelButtonTouchUpInside: (id)sender
{
  [self.view endEditing: YES]; // Resign first responders

  [self.contact revert];

  if (self.contact.recordID == tagNewContact)
  {
    [[AKAddressBook sharedInstance].contacts removeObjectForKey: [NSNumber numberWithInteger: tagNewContact]];
    if ([self.navigationController respondsToSelector: @selector(dismissViewControllerAnimated:completion:)])
      [self.navigationController dismissViewControllerAnimated: YES completion: nil];
    else
      [self.navigationController dismissModalViewControllerAnimated: YES];
  }
  else
  {
    [self setEditing: NO animated: YES];
  }
}

- (void)tableViewTouchUpInside: (id)sender
{
  [self.firstResponder resignFirstResponder];
}

@end
