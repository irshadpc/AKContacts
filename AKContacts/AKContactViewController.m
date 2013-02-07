//
//  AKContactViewController.m
//
//  Copyright (c) 2013 Adam Kornafeld All rights reserved.
//

#import "AKContactViewController.h"
#import "AKContact.h"
#import "AKContactHeaderViewCell.h"
#import "AKContactDetailViewCell.h"
#import "AKContactAddressViewCell.h"

static const float defaultCellHeight = 44.f;

@interface AKContactViewController ()

@property (nonatomic, strong) NSMutableArray *sections;

@end

@implementation AKContactViewController

@synthesize tableView;
@synthesize contact;
@synthesize sections;

- (void)loadView {

  CGFloat navBarHeight = ([self.navigationController isNavigationBarHidden]) ? 0.f :
  self.navigationController.navigationBar.frame.size.height;
  
  [self setTableView: [[UITableView alloc] initWithFrame: CGRectMake(0.0, 0.0, 320.0, 460.0 - navBarHeight) style: UITableViewStyleGrouped]];
  [self.tableView setDataSource: self];
  [self.tableView setDelegate: self];
  [self.tableView setAllowsSelectionDuringEditing: YES];

  [self setView: [[UIView alloc] init]];
  [self.view addSubview: self.tableView];

//  UIBarButtonItem * editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(setEditing:animated:)];
  [self.navigationItem setRightBarButtonItem: self.editButtonItem];

}

- (void)viewDidLoad {

  [super viewDidLoad];

  [self setSections: [[NSMutableArray alloc] init]];

  [self.sections addObject: [NSNumber numberWithInteger: kSectionHeader]];

  if ([self.contact countForProperty: kABPersonPhoneProperty] > 0)
    [self.sections addObject: [NSNumber numberWithInteger: kSectionPhoneNumbers]];

  if ([self.contact countForProperty: kABPersonEmailProperty] > 0)
    [self.sections addObject: [NSNumber numberWithInteger: kSectionEmailAddresses]];

  if ([self.contact countForProperty: kABPersonAddressProperty] > 0)
    [self.sections addObject: [NSNumber numberWithInteger: kSectionAddresses]];

  if ([self.contact valueForProperty: kABPersonBirthdayProperty])
    [self.sections addObject: [NSNumber numberWithInteger: kSectionBirthday]];

  if ([self.contact countForProperty: kABPersonDateProperty] > 0)
    [self.sections addObject: [NSNumber numberWithInteger: kSectionDate]];

  if ([self.contact countForProperty: kABPersonSocialProfileProperty] > 0)
    [self.sections addObject: [NSNumber numberWithInteger: kSectionSocialProfiles]];

  if ([self.contact countForProperty: kABPersonInstantMessageProperty] > 0)
    [self.sections addObject: [NSNumber numberWithInteger: kSectionInstantMessengers]];

  if ([[self.contact valueForProperty: kABPersonNoteProperty] length] > 0)
    [self.sections addObject: [NSNumber numberWithInteger: kSectionNotes]];
  
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
  return [self.sections count];
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
  NSInteger ret = 0;

  switch ([[self.sections objectAtIndex: section] integerValue]) {

    case kSectionHeader:
      ret = (self.isEditing) ? 3 : 1;
      break;

    case kSectionPhoneNumbers:
      ret = [self.contact countForProperty: kABPersonPhoneProperty];
      if (self.isEditing) ret += 1;
      break;

    case kSectionEmailAddresses:
      ret = [self.contact countForProperty: kABPersonEmailProperty];
      if (self.isEditing) ret += 1;
      break;

    case kSectionAddresses:
      ret = [self.contact countForProperty: kABPersonAddressProperty];
      if (self.editing) ret += 1;
      break;

    case kSectionBirthday:
      ret = 1;
      break;
      
    case kSectionDate:
      ret = [self.contact countForProperty: kABPersonDateProperty];
      if (self.editing) ret += 1;
      break;

    case kSectionSocialProfiles:
      ret = [self.contact countForProperty: kABPersonSocialProfileProperty];
      if (self.editing) ret += 1;
      break;

    case kSectionInstantMessengers:
      ret = [self.contact countForProperty: kABPersonInstantMessageProperty];
      if (self.editing) ret += 1;
      break;

    case kSectionNotes:
      ret = ([[self.contact valueForProperty: kABPersonNoteProperty] length] > 0) ? 1 : 0;
    default:
      break;

  }

  return ret;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

  NSInteger section = [[self.sections objectAtIndex: indexPath.section] integerValue];

  switch (section) {
    case kSectionHeader:
      return  (self.editing) ? defaultCellHeight : (defaultCellHeight + 30.f);

    case kSectionAddresses:
      return  (self.editing) ? 120.f : (defaultCellHeight + 30.f);

    case kSectionNotes:
      return [[self.contact valueForProperty: kABPersonNoteProperty] sizeWithFont: [UIFont systemFontOfSize: [UIFont systemFontSize]]
                        constrainedToSize: CGSizeMake(210.f, 120.f)
                            lineBreakMode: NSLineBreakByWordWrapping].height + 25.f;

    default:
      return defaultCellHeight;
  }
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  NSInteger section = [[self.sections objectAtIndex: indexPath.section] integerValue];

  switch (section) {

    case kSectionHeader:
      return [self headerCellViewAtRow: indexPath.row];

    case kSectionPhoneNumbers:
      return [self detailCellViewForProperty: kABPersonPhoneProperty atRow: indexPath.row];

    case kSectionEmailAddresses:
      return [self detailCellViewForProperty: kABPersonEmailProperty atRow: indexPath.row];

    case kSectionAddresses:
      return [self addressCellViewAtRow: indexPath.row];

    case kSectionBirthday:
      return [self detailCellViewForProperty: kABPersonBirthdayProperty atRow: indexPath.row];

    case kSectionDate:
      return [self detailCellViewForProperty: kABPersonDateProperty atRow: indexPath.row];

    case kSectionSocialProfiles:
      return [self detailCellViewForProperty: kABPersonSocialProfileProperty atRow: indexPath.row];
      
    case kSectionInstantMessengers:
      return [self detailCellViewForProperty: kABPersonInstantMessageProperty atRow: indexPath.row];

    case kSectionNotes:
      return [self detailCellViewForProperty: kABPersonNoteProperty atRow: indexPath.row];

    default:
      return nil;
  }
}

- (BOOL)tableView:(UITableView *)aTableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {

  NSInteger section = [[self.sections objectAtIndex: indexPath.section] integerValue];
  
  switch (section) {
    case kSectionHeader:
      return NO;
    default:
      return YES;
  }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {

  NSInteger section = [[self.sections objectAtIndex: indexPath.section] integerValue];

  switch (section) {
    case kSectionBirthday:
    case kSectionNotes:
      return UITableViewCellEditingStyleDelete;
    case kSectionPhoneNumbers:
      return (indexPath.row < [self.contact countForProperty: kABPersonPhoneProperty]) ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
    case kSectionEmailAddresses:
      return (indexPath.row < [self.contact countForProperty: kABPersonEmailProperty]) ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
    case kSectionAddresses:
      return (indexPath.row < [self.contact countForProperty: kABPersonAddressProperty]) ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
    case kSectionDate:
      return (indexPath.row < [self.contact countForProperty: kABPersonDateProperty]) ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
    case kSectionSocialProfiles:
      return  (indexPath.row < [self.contact countForProperty: kABPersonSocialProfileProperty]) ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
    case kSectionInstantMessengers:
      return  (indexPath.row < [self.contact countForProperty: kABPersonInstantMessageProperty]) ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
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
    
    if (section == kSectionBirthday ||
        section == kSectionDate) {
      AKContactDetailViewCell *cell = (AKContactDetailViewCell *)[self.tableView cellForRowAtIndexPath: indexPath];
      [cell showDatePicker];
    }
  } else {
    
    if (section == kSectionSocialProfiles) {
      
      AKContactDetailViewCell *cell = (AKContactDetailViewCell *)[self.tableView cellForRowAtIndexPath: indexPath];
      [cell openURLForSocialProfile];
    }
  }

  [self.tableView deselectRowAtIndexPath: indexPath animated: YES];

}

#pragma mark - Button Delegate Methods

- (void)setEditing:(BOOL)editing animated:(BOOL)animate {

  [super setEditing: !super.editing animated: YES]; // Toggles Done button
  [self.tableView setEditing:!self.tableView.editing animated:YES];

  if (self.editing) {
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonTouchUp:)];
    [self.navigationItem setLeftBarButtonItem: barButtonItem];

  } else {
    [self.navigationItem setLeftBarButtonItem: nil];
  }

  /* Reload sections to toggle edit mode */
  NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
  [indexSet addIndex: [self.sections indexOfObject: [NSNumber numberWithInteger: kSectionHeader]]];

  [indexSet addIndex: [self.sections indexOfObject: [NSNumber numberWithInteger: kSectionPhoneNumbers]]];
  [indexSet addIndex: [self.sections indexOfObject: [NSNumber numberWithInteger: kSectionEmailAddresses]]];
  [indexSet addIndex: [self.sections indexOfObject: [NSNumber numberWithInteger: kSectionAddresses]]];

  if ([self.sections indexOfObject: [NSNumber numberWithInteger: kSectionNotes]] != NSNotFound)
    [indexSet addIndex: [self.sections indexOfObject: [NSNumber numberWithInteger: kSectionBirthday]]];

  [indexSet addIndex: [self.sections indexOfObject: [NSNumber numberWithInteger: kSectionDate]]];

  if ([self.sections indexOfObject: [NSNumber numberWithInteger: kSectionNotes]] != NSNotFound)
    [indexSet addIndex: [self.sections indexOfObject: [NSNumber numberWithInteger: kSectionNotes]]];

  [self.tableView reloadSections: indexSet withRowAnimation: UITableViewRowAnimationAutomatic];

}

- (void)cancelButtonTouchUp: (id)sender {
  [self setEditing: NO animated: YES];
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

@end
