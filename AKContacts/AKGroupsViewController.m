//
//  AKGroupsViewController.m
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

#import "AKGroupsViewController.h"
#import "AKContactsViewController.h"
#import "AKGroup.h"
#import "AKSource.h"
#import "AKAddressBook.h"
#import "AppDelegate.h"

static const float defaultCellHeight = 44.f;

@interface AKGroupsViewController ()

@property (nonatomic, unsafe_unretained) AppDelegate *appDelegate;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation AKGroupsViewController

@synthesize appDelegate = _appDelegate;

@synthesize tableView = _tableView;

#pragma mark - View lifecycle

- (void)loadView {

  CGFloat navBarHeight = ([self.navigationController isNavigationBarHidden]) ? 0.f :
  self.navigationController.navigationBar.frame.size.height;
  
  [self setTableView: [[UITableView alloc] initWithFrame: CGRectMake(0.f, 0.f, 320.f, 460.f - navBarHeight)
                                                   style: UITableViewStyleGrouped]];
  [self.tableView setDataSource: self];
  [self.tableView setDelegate: self];

  [self setView: [[UIView alloc] init]];
  [self.view addSubview: self.tableView];
}

-(void)viewDidLoad {
  [super viewDidLoad];
  
  // Uncomment the following line to preserve selection between presentations.
  // self.clearsSelectionOnViewWillAppear = NO;
  
  // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
  // self.navigationItem.rightBarButtonItem = self.editButtonItem;
  
  [self setAppDelegate: (AppDelegate *)[[UIApplication sharedApplication] delegate]];
  
  UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemAdd
                                                                             target: self
                                                                             action: @selector(addButtonTouchUp:)];
  [self.navigationItem setRightBarButtonItem: addButton];
  
  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reloadTableViewData) name: AddressBookDidLoadNotification object: nil];
  
}

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
}

-(void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
}

#pragma mark - Custom methods

-(void)addButtonTouchUp: (id)sender {
  
}

-(void)reloadTableViewData {
  dispatch_async(dispatch_get_main_queue(), ^(void){
    [_tableView reloadData];
  });
}

#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  
  NSInteger ret = 0;
  
  if (_appDelegate.akAddressBook.status >= kAddressBookOnline) {
    ret = [[_appDelegate.akAddressBook sources] count];
  }
  
  return ret;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

  AKSource *source = [[_appDelegate.akAddressBook sources] objectAtIndex: section];
  return [[source groups] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"Cell";

  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }

  [cell.textLabel setText: nil];
  [cell setTag: NSNotFound];
  [cell.textLabel setTextAlignment: NSTextAlignmentLeft];
  [cell.textLabel setTextColor: [UIColor blackColor]];
  [cell setSelectionStyle: UITableViewCellSelectionStyleNone];

  NSInteger sourceCount = [_appDelegate.akAddressBook.sources count];
  AKSource *source = [_appDelegate.akAddressBook.sources objectAtIndex: indexPath.section];
  AKGroup *group = [source.groups objectAtIndex: indexPath.row];

  NSMutableArray *groupAggregateName = [[NSMutableArray alloc] initWithObjects: @"All", @"Contacts", nil];
  if (source.recordID >= 0 && sourceCount > 1) [groupAggregateName insertObject: [source typeName] atIndex: 1];

  NSString *groupName = (group.recordID < 0) ? [groupAggregateName componentsJoinedByString: @" "]: [group valueForProperty:kABGroupNameProperty];

  if (!group) return cell;
  [cell setTag: group.recordID];
  [cell setSelectionStyle: UITableViewCellSelectionStyleBlue];

  [cell setAccessoryType: UITableViewCellAccessoryDisclosureIndicator];
  [cell.textLabel setFont: [UIFont boldSystemFontOfSize: 20.f]];
  [cell.textLabel setText: groupName];

  return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection: (NSInteger)section {
  
  NSInteger sourceCount = [_appDelegate.akAddressBook.sources count];
  AKSource *source = [[_appDelegate.akAddressBook sources] objectAtIndex: section];
  return (sourceCount > 1) ? [source typeName] : nil;
}

/*
 // Override to support conditional editing of the table view.
 -(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 -(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 -(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 -(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

-(NSIndexPath *)tableView: (UITableView *)tableView willSelectRowAtIndexPath: (NSIndexPath *)indexPath {
  return indexPath;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

  AKSource *source = [_appDelegate.akAddressBook.sources objectAtIndex: indexPath.section];
  AKGroup *group = [source.groups objectAtIndex: indexPath.row];

  [_appDelegate.akAddressBook setSourceID: [source recordID]];
  [_appDelegate.akAddressBook setGroupID: [group recordID]];
  [_appDelegate.akAddressBook resetSearch];

  AKContactsViewController *contactsView = [[AKContactsViewController alloc] init];
  [self.navigationController pushViewController: contactsView animated: YES];
  
  [tableView deselectRowAtIndexPath: indexPath animated: YES];
}

#pragma mark - Memory management

-(void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Release any cached data, images, etc that aren't in use.
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver: self];
}

@end
