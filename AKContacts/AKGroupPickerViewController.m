//
//  AKGroupPickerViewController.m
//  AKContacts
//
//  Created by Adam Kornafeld on 5/21/13.
//  Copyright (c) 2013 Adam Kornafeld. All rights reserved.
//

#import "AKGroupPickerViewController.h"
#import "AKAddressBook.h"
#import "AKContact.h"
#import "AKGroup.h"
#import "AKSource.h"

NSString *const AKGroupPickerViewDidDismissNotification = @"AKGroupPickerViewDidDismissNotification";

@interface AKGroupPickerViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UITableView *tableView;
@property (assign, nonatomic) NSInteger contactID;

@end

@implementation AKGroupPickerViewController

- (id)initWithContactID: (NSInteger)contactID
{
  self = [super init];
  if (self)
  {
    _contactID = contactID;
  }
  return self;
}

#pragma mark - View lifecycle

- (void)loadView
{
  CGFloat width = [UIScreen mainScreen].bounds.size.width;
  CGFloat height = [UIScreen mainScreen].bounds.size.height;
  height -= (self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height);
  [self setTableView: [[UITableView alloc] initWithFrame: CGRectMake(0.f, 0.f, width, height)
                                                   style: UITableViewStyleGrouped]];
  [self.tableView setDataSource: self];
  [self.tableView setDelegate: self];

  [self setView: [[UIView alloc] init]];
  [self.view addSubview: self.tableView];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
                                                                                 target: self
                                                                                 action: @selector(cancelButtonTouchUpInside:)];
  [self.navigationItem setLeftBarButtonItem: barButtonItem];
  
  barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                target: self
                                                                action: @selector(doneButtonTouchUpInside:)];
  [self.navigationItem setRightBarButtonItem: barButtonItem];
}

#pragma mark - Custom methods

- (void)cancelButtonTouchUpInside: (id)sender
{
  AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];

  AKSource *source = [akAddressBook sourceForContactId: self.contactID];

  for (AKGroup *group in source.groups)
  {
    [group revertMembers];
  }

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
  [self.navigationController dismissViewControllerAnimated: YES completion: nil];
#else
  [self.navigationController dismissModalViewControllerAnimated: YES];
#endif
}

- (void)doneButtonTouchUpInside: (id)sender
{
  AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];

  AKSource *source = [akAddressBook sourceForContactId: self.contactID];
  
  for (AKGroup *group in source.groups)
  {
    [group commitMembers];
  }

  [[NSNotificationCenter defaultCenter] postNotificationName: AKGroupPickerViewDidDismissNotification object: nil];

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
  [self.navigationController dismissViewControllerAnimated: YES completion: nil];
#else
  [self.navigationController dismissModalViewControllerAnimated: YES];
#endif
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  AKSource *source = [[AKAddressBook sharedInstance] sourceForContactId: self.contactID];

  return [source.groups count] - 1; // Do not include aggregate group
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }

  AKSource *source = [[AKAddressBook sharedInstance] sourceForContactId: self.contactID];

  AKGroup *group = [[source groups] objectAtIndex: indexPath.row + 1];

  [cell setAccessoryType: ([group.memberIDs member: [NSNumber numberWithInteger: self.contactID]] == nil) ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark];

  [cell.textLabel setText: [group valueForProperty: kABGroupNameProperty]];

  return (UITableViewCell *)cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection: (NSInteger)section
{
  AKSource *source = [[AKAddressBook sharedInstance] sourceForContactId: self.contactID];

  return [source typeName];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
  return NSLocalizedString(@"Only those groups are shown here that are in the same source the contact belongs to", @"");
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView cellForRowAtIndexPath: indexPath];

  AKSource *source = [[AKAddressBook sharedInstance] sourceForContactId: self.contactID];
  
  AKGroup *group = [[source groups] objectAtIndex: indexPath.row + 1];
  
  if (cell.accessoryType == UITableViewCellAccessoryNone)
  {
    [cell setAccessoryType: UITableViewCellAccessoryCheckmark];

    [group insertMemberWithID: self.contactID];
  }
  else
  {
    [cell setAccessoryType: UITableViewCellAccessoryNone];
    
    [group removeMemberWithID: self.contactID];
  }

  [tableView deselectRowAtIndexPath: indexPath animated: YES];
}

@end
