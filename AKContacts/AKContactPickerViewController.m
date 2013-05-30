//
//  AKContactPickerViewController.m
//  AKContacts
//
//  Created by Adam Kornafeld on 5/25/13.
//  Copyright (c) 2013 Adam Kornafeld. All rights reserved.
//

#import "AKContactPickerViewController.h"
#import "AKAddressBook.h"
#import "AKContact.h"
#import "AKGroup.h"
#import "AKSource.h"

@interface AKContactPickerViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UITableView *tableView;
/**
 * Dictionary keys of displayed contacts
 **/
@property (strong, nonatomic) NSMutableArray *keys;
/**
 * Identifiers of displayed contacts
 **/
@property (strong, nonatomic) NSMutableDictionary *contactIdentifiers;

@end

@implementation AKContactPickerViewController

#pragma mark - View lifecycle

- (void)loadView
{
  [self loadContacts];

  CGFloat height = ([UIScreen mainScreen].bounds.size.height == 568.f) ? 568.f : 480.f;
  height -= (self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height);
  [self setTableView: [[UITableView alloc] initWithFrame: CGRectMake(0.f, 0.f, 320.f, height)
                                                   style: UITableViewStylePlain]];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Custom methods

- (void)loadContacts
{
  [self setKeys: [[NSMutableArray alloc] init]];

  AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];

  AKSource *source = [akAddressBook sourceForSourceId: akAddressBook.sourceID];
  AKGroup *group = [source groupForGroupId: kGroupAggregate];
  NSMutableSet *groupMembers = [group memberIDs];

  NSArray *keyArray = [[akAddressBook.allContactIdentifiers allKeys] sortedArrayUsingSelector: @selector(compare:)];

  [self setContactIdentifiers: [[NSMutableDictionary alloc] init]];

  for (NSString *key in keyArray)
  {
    NSArray *arrayForKey = [akAddressBook.allContactIdentifiers objectForKey: key];
    NSMutableArray *sectionArray = [NSKeyedUnarchiver unarchiveObjectWithData: [NSKeyedArchiver archivedDataWithRootObject: arrayForKey]]; // Mutable deep copy

    NSMutableArray *recordsToRemove = [[NSMutableArray alloc] init];
    for (NSNumber *contactID in sectionArray)
    {
      if ([groupMembers member: contactID] == nil)
        [recordsToRemove addObject: contactID];
    }
    [sectionArray removeObjectsInArray: recordsToRemove];
    if ([sectionArray count] > 0)
    {
      [self.contactIdentifiers setObject: sectionArray forKey: key];
      [self.keys addObject: key];
    }
  }

  if ([self.keys count] > 0 && [[self.keys objectAtIndex: 0] isEqualToString: @"#"])
  { // Little hack to move # to the end of the list
    [self.keys addObject: [self.keys objectAtIndex: 0]];
    [self.keys removeObjectAtIndex: 0];
  }
}

- (void)cancelButtonTouchUpInside: (id)sender
{
  if ([self.navigationController respondsToSelector: @selector(dismissViewControllerAnimated:completion:)])
    [self.navigationController dismissViewControllerAnimated: YES completion: nil];
  else
    [self.navigationController dismissModalViewControllerAnimated: YES];
}

- (void)doneButtonTouchUpInside: (id)sender
{
  if ([self.navigationController respondsToSelector: @selector(dismissViewControllerAnimated:completion:)])
    [self.navigationController dismissViewControllerAnimated: YES completion: nil];
  else
    [self.navigationController dismissModalViewControllerAnimated: YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return [self.keys count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  NSString *key = [self.keys objectAtIndex: section];
  NSArray *nameSection = [self.contactIdentifiers objectForKey: key];

  return [nameSection count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }

  AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];

  NSString *key = nil;
  if ([self.keys count] > indexPath.section)
    key = [self.keys objectAtIndex: indexPath.section];
  
  NSArray *identifiersArray = [self.contactIdentifiers objectForKey: key];

  NSNumber *recordId = [identifiersArray objectAtIndex: indexPath.row];
  AKContact *contact = [akAddressBook contactForContactId: [recordId integerValue]];

  [cell setTag: [contact recordID]];
  [cell setSelectionStyle: UITableViewCellSelectionStyleBlue];

  [cell setAccessoryView: nil];
  if (![contact name])
  {
    cell.textLabel.font = [UIFont italicSystemFontOfSize: 20.f];
    cell.textLabel.text = NSLocalizedString(@"No Name", @"");
  }
  else
  {
    cell.textLabel.font = [UIFont boldSystemFontOfSize: 20.f];
    cell.textLabel.text = [contact name];
  }

  return (UITableViewCell *)cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection: (NSInteger)section
{
  return [self.keys objectAtIndex: section];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView cellForRowAtIndexPath: indexPath];

  if (cell.accessoryType == UITableViewCellAccessoryNone)
  {
    [cell setAccessoryType: UITableViewCellAccessoryCheckmark];
  }
  else
  {
    [cell setAccessoryType: UITableViewCellAccessoryNone];
  }
  
  [tableView deselectRowAtIndexPath: indexPath animated: YES];
}

@end