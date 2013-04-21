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
#import "AKContactDeleteButtonViewCell.h"
#import "AKContact.h"
#import "AKAddressBook.h"

typedef NS_ENUM(NSInteger, Identifier) {
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
  kSectionButton,
  kSectionDeleteButton,
};

static const float defaultCellHeight = 44.f;

@interface AKContactViewController ()

@property (nonatomic, strong) NSMutableArray *sections;
@property (nonatomic, strong) NSArray *sectionIdentifiers;

@end

@implementation AKContactViewController

@synthesize tableView = _tableView;
@synthesize contactID = _contactID;
@synthesize delegate = _delegate;
@synthesize sections = _sections;
@synthesize sectionIdentifiers = _sectionIdentifiers;

-(id)initWithContactID: (NSInteger)contactID {
  self = [self init];
  if (self) {
    _contactID = contactID;
  }
  return self;
}

-(void)loadView {

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
  [self.sections addObject: [NSNumber numberWithInteger: kSectionDeleteButton]];
  [self setSectionIdentifiers: [self.sections copy]];

  if (self.contactID == tagNewContact) {
    [self setEditing: YES animated: NO];
  } else {
    NSMutableArray *sectionsToRemove = [[NSMutableArray alloc] init];
    for (NSNumber *section in self.sections) {
      if ([self numberOfElementsInSection: [section integerValue]] == 0)
        [sectionsToRemove addObject: section];
    }
    [self.sections removeObjectsInArray: sectionsToRemove];    
  }

  CGFloat navBarHeight = ([self.navigationController isNavigationBarHidden]) ? 0.f :
  self.navigationController.navigationBar.frame.size.height;

  [self setTableView: [[UITableView alloc] initWithFrame: CGRectMake(0.0, 0.0, 320.0, 460.0 - navBarHeight) style: UITableViewStyleGrouped]];
  [self.tableView setDataSource: self];
  [self.tableView setDelegate: self];
  [self.tableView setAllowsSelectionDuringEditing: YES];

  [self setView: [[UIView alloc] init]];
  [self.view addSubview: self.tableView];

  [self.navigationItem setRightBarButtonItem: self.editButtonItem];
}

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 * Return the number of entries in a section
 **/
-(NSInteger)numberOfElementsInSection: (NSInteger)section {

  AKContact *contact = [[AKAddressBook sharedInstance] contactForContactId: self.contactID];

  switch (section) {
    case kSectionPhone:
      return [contact countForProperty: kABPersonPhoneProperty];
    case kSectionEmail:
      return [contact countForProperty: kABPersonEmailProperty];
    case kSectionURL:
      return [contact countForProperty: kABPersonURLProperty];
    case kSectionAddress:
      return [contact countForProperty: kABPersonAddressProperty];
    case kSectionBirthday:
      return ([contact valueForProperty: kABPersonBirthdayProperty]) ? 1 : 0;
    case kSectionDate:
      return [contact countForProperty: kABPersonDateProperty];
    case kSectionSocialProfile:
      return [contact countForProperty: kABPersonSocialProfileProperty];
    case kSectionInstantMessage:
      return [contact countForProperty: kABPersonInstantMessageProperty];
    case kSectionNote:
      return ([contact valueForProperty: kABPersonNoteProperty]) ? 1 : 0;
    case kSectionDeleteButton:
      return 0;
    // If custom section does not default to having one element add case here
    default:
      return 1;
  }
}

-(BOOL)isSectionEditable: (NSInteger)section
{
  switch (section)
  {
    case kSectionSwitch:
      return NO;
    default:
      return YES;
  }
}

-(NSInteger)insertIndexForSection: (NSInteger)section
{
  for (NSInteger i = 0; i < [self.sections count]; ++i)
  {
    NSInteger aSection = [[self.sections objectAtIndex: i] integerValue];
    if (section < aSection)
      return i;
  }
  return [self.sections count];  
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
  } else if (section == kSectionBirthday ||
             section == kSectionNote)
  {
    ret = 1;
  }
  else
  {
    ret = [self numberOfElementsInSection: section];
    if (self.editing) ret += 1;
  }

  return ret;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSInteger section = [[self.sections objectAtIndex: indexPath.section] integerValue];

  AKContact *contact = [[AKAddressBook sharedInstance] contactForContactId: self.contactID];
  
  switch (section)
  {
    case kSectionHeader:
      return  (self.editing) ? defaultCellHeight : (defaultCellHeight + 30.f);

    case kSectionAddress:
      return  (self.editing) ? 120.f : (defaultCellHeight + 30.f);

    case kSectionNote:
      return ([contact valueForProperty: kABPersonNoteProperty]) ?
        [[contact valueForProperty: kABPersonNoteProperty] sizeWithFont: [UIFont systemFontOfSize: [UIFont systemFontSize]]
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
      return [self headerCellViewAtRow: indexPath.row];

    case kSectionPhone:
      return [self detailCellViewForProperty: kABPersonPhoneProperty atRow: indexPath.row];

    case kSectionEmail:
      return [self detailCellViewForProperty: kABPersonEmailProperty atRow: indexPath.row];

    case kSectionURL:
      return [self detailCellViewForProperty: kABPersonURLProperty atRow: indexPath.row];

    case kSectionAddress:
      return [self addressCellViewAtRow: indexPath.row];

    case kSectionBirthday:
      return [self detailCellViewForProperty: kABPersonBirthdayProperty atRow: indexPath.row];

    case kSectionDate:
      return [self detailCellViewForProperty: kABPersonDateProperty atRow: indexPath.row];

    case kSectionSocialProfile:
      return [self detailCellViewForProperty: kABPersonSocialProfileProperty atRow: indexPath.row];

    case kSectionInstantMessage:
      return [self detailCellViewForProperty: kABPersonInstantMessageProperty atRow: indexPath.row];

    case kSectionNote:
      return [self detailCellViewForProperty: kABPersonNoteProperty atRow: indexPath.row];

    case kSectionSwitch:
      return [self switchCellViewAtRow: indexPath.row];

    case kSectionDeleteButton:
      return [self deleteButtonCellViewAtRow: indexPath.row];

    default:
      return nil;
  }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {

  NSInteger section = [[self.sections objectAtIndex: indexPath.section] integerValue];

  switch (section) {
    case kSectionHeader:
    case kSectionDeleteButton:
      return NO;
    default:
      return YES;
  }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSInteger section = [[self.sections objectAtIndex: indexPath.section] integerValue];

  AKContact *contact = [[AKAddressBook sharedInstance] contactForContactId: self.contactID];

  switch (section)
  {
    case kSectionBirthday:
    case kSectionNote:
      return UITableViewCellEditingStyleDelete;

    case kSectionPhone:
      return (indexPath.row < [contact countForProperty: kABPersonPhoneProperty]) ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;

    case kSectionEmail:
      return (indexPath.row < [contact countForProperty: kABPersonEmailProperty]) ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;

    case kSectionURL:
      return (indexPath.row < [contact countForProperty: kABPersonURLProperty]) ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;

    case kSectionAddress:
      return (indexPath.row < [contact countForProperty: kABPersonAddressProperty]) ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;

    case kSectionDate:
      return (indexPath.row < [contact countForProperty: kABPersonDateProperty]) ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;

    case kSectionSocialProfile:
      return  (indexPath.row < [contact countForProperty: kABPersonSocialProfileProperty]) ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;

    case kSectionInstantMessage:
      return  (indexPath.row < [contact countForProperty: kABPersonInstantMessageProperty]) ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;

    default:
      return UITableViewCellEditingStyleNone;
  }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    //[_objects removeObjectAtIndex:indexPath.row];
    //[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
  } else if (editingStyle == UITableViewCellEditingStyleInsert) {
    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
  }
}

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

  NSInteger section = [[self.sections objectAtIndex: indexPath.section] integerValue];
  
  if (self.editing) {

  } else {
    
    if (section == kSectionSocialProfile) {
      
      AKContactDetailViewCell *cell = (AKContactDetailViewCell *)[self.tableView cellForRowAtIndexPath: indexPath];
      [cell openURLForSocialProfile];
    }
  }

  [self.tableView deselectRowAtIndexPath: indexPath animated: YES];

}

#pragma mark - Button Delegate Methods

- (void)setEditing:(BOOL)editing animated:(BOOL)animate
{
  [super setEditing: editing animated: YES]; // Toggles Done button
  [self.tableView setEditing: editing animated:YES];

  if (self.editing)
  {
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonTouchUp:)];
    [self.navigationItem setLeftBarButtonItem: barButtonItem];

  }
  else
  {
    [self.navigationItem setLeftBarButtonItem: nil];
    
    if (self.contactID == tagNewContact)
    {
      [self.view endEditing: YES]; // Resign first responders
      AKContact *contact = [[AKAddressBook sharedInstance] contactForContactId: self.contactID];
      [contact commit];

      if ([self.delegate respondsToSelector: @selector(modalViewDidDismissWithContactID:)])
        [self.delegate modalViewDidDismissWithContactID: contact.recordID];

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
        [insertSections addObject: section];
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

- (void)cancelButtonTouchUp: (id)sender {
  if (self.contactID == tagNewContact)
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

#pragma mark - Table View Cells

- (UITableViewCell *)headerCellViewAtRow: (NSInteger)row {
  static NSString *CellIdentifier = @"AKContactHeaderCellView";

  AKContactHeaderViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier: CellIdentifier];
  if (cell == nil) {
    cell = [[AKContactHeaderViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }

  [cell setParent: self];
  
  [cell configureCellAtRow: row];

  return (UITableViewCell *)cell;
}

- (UITableViewCell *)detailCellViewForProperty: (ABPropertyID)property atRow: (NSInteger)row {

  static NSString *CellIdentifier = @"AKContactDetailViewCell";

  AKContactDetailViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier: CellIdentifier];
  if (cell == nil) {
    cell = [[AKContactDetailViewCell alloc] initWithStyle: UITableViewCellStyleValue2 reuseIdentifier: CellIdentifier];
  }

  [cell setParent: self];

  [cell configureCellForProperty: property atRow: row];

  return (UITableViewCell *)cell;
}

- (UITableViewCell *)addressCellViewAtRow: (NSInteger)row {

  static NSString *CellIdentifier = @"AKContactAddressViewCell";

  AKContactAddressViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier: CellIdentifier];
  if (cell == nil) {
    cell = [[AKContactAddressViewCell alloc] initWithStyle: UITableViewCellStyleValue2 reuseIdentifier: CellIdentifier];
  }

  [cell setParent: self];

  [cell configureCellAtRow: row];

  return (UITableViewCell *)cell;
}

- (UITableViewCell *)switchCellViewAtRow: (NSInteger)row {
  static NSString *CellIdentifier = @"AKContactSwitchViewCell";

  AKContactSwitchViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier: CellIdentifier];
  if (cell == nil) {
    cell = [[AKContactSwitchViewCell alloc] initWithStyle: UITableViewCellStyleValue2 reuseIdentifier: CellIdentifier];
  }
  
  [cell setParent: self];
  
  [cell configureCellAtRow: row];
  
  return (UITableViewCell *)cell;
}

- (UITableViewCell *)deleteButtonCellViewAtRow: (NSInteger)row {
  static NSString *CellIdentifier = @"AKContactDeleteButtonViewCell";

  AKContactDeleteButtonViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier: CellIdentifier];
  if (cell == nil) {
    cell = [[AKContactDeleteButtonViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: CellIdentifier];
  }

  [cell setParent: self];

  [cell configureCell];

  return (UITableViewCell *)cell;
}

@end
