//
//  AKGroupSelectViewController.m
//  AKContacts
//
//  Created by Adam Kornafeld on 5/21/13.
//  Copyright (c) 2013 Adam Kornafeld. All rights reserved.
//

#import "AKGroupSelectViewController.h"
#import "AKAddressBook.h"
#import "AKSource.h"
#import "AKGroup.h"

@interface AKGroupSelectViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UITableView *tableView;

@end

@implementation AKGroupSelectViewController

#pragma mark - View lifecycle

- (void)loadView
{
  CGFloat height = ([UIScreen mainScreen].bounds.size.height == 568.f) ? 568.f : 480.f;
  height -= (self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height);
  [self setTableView: [[UITableView alloc] initWithFrame: CGRectMake(0.f, 0.f, 320.f, height)
                                                   style: UITableViewStyleGrouped]];
  [self.tableView setDataSource: self];
  [self.tableView setDelegate: self];

  [self setView: [[UIView alloc] init]];
  [self.view addSubview: self.tableView];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return [[AKAddressBook sharedInstance].sources count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  AKSource *source = [[AKAddressBook sharedInstance].sources objectAtIndex: section];

  return [source.groups count] - 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }

  AKSource *source = [[AKAddressBook sharedInstance].sources objectAtIndex: indexPath.section];
  
  AKGroup *group = [[source groups] objectAtIndex: indexPath.row + 1];

  cell.textLabel.text = [group valueForProperty: kABGroupNameProperty];

  return (UITableViewCell *)cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection: (NSInteger)section
{
  return nil;
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
