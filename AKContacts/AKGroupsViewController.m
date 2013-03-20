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
#import "AKGroupsViewCell.h"
#import "AKContactsViewController.h"
#import "AKGroup.h"
#import "AKSource.h"
#import "AKAddressBook.h"

static const float defaultCellHeight = 44.f;

@interface AKGroupsViewController ()

@property (nonatomic, strong) UITableView *tableView;

-(void)addButtonTouchUp: (id)seneder;
-(void)cancelButtonTouchUp: (id)sender;
-(void)reloadTableViewData;

@end

@implementation AKGroupsViewController

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
  
  UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemAdd
                                                                             target: self
                                                                             action: @selector(addButtonTouchUp:)];
  [self.navigationItem setRightBarButtonItem: addButton];
  
  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reloadTableViewData) name: AddressBookDidLoadNotification object: nil];
}

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  [[AKAddressBook sharedInstance] addObserver: self forKeyPath: @"status" options: NSKeyValueObservingOptionNew context: nil];
}

-(void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];

  [[AKAddressBook sharedInstance] removeObserver: self forKeyPath: @"status"];
}

-(void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animate {

  [super setEditing: editing animated: YES]; // Toggles Done button
  [self.tableView setEditing: editing animated: YES];

  if (self.editing) {
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonTouchUp:)];
    [self.navigationItem setLeftBarButtonItem: barButtonItem];

    barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone target:self action:@selector(addButtonTouchUp:)];
    [self.navigationItem setRightBarButtonItem: barButtonItem];
  } else {
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemAdd target:self action:@selector(addButtonTouchUp:)];
    [self.navigationItem setRightBarButtonItem: barButtonItem];

    [self.navigationItem setLeftBarButtonItem: nil];
  }

  NSInteger section = 0;
  [self.tableView beginUpdates];
  for (AKSource *source in [AKAddressBook sharedInstance].sources) {
    if ([source hasEditableGroups] == YES) {
      NSIndexPath *indexPath = [NSIndexPath indexPathForRow: [source.groups count] inSection: section];
      if (self.editing == YES) {
        [self.tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
                              withRowAnimation: UITableViewRowAnimationTop];
      } else {
        [self.tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
                              withRowAnimation: UITableViewRowAnimationTop];
      }
    }
    section += 1;
  }
  [self.tableView endUpdates];
}

#pragma mark - Key-Value Observing

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  // This is not dispatched on main queue
  
  if (object == [AKAddressBook sharedInstance] && // Comparing the address
      [keyPath isEqualToString: @"status"]) {
    // Status property of AKAddressBook changed
    AKContactsViewController *contactsView = [[AKContactsViewController alloc] init];
    [self.navigationController pushViewController: contactsView animated: NO];
  }
}

#pragma mark - Custom methods

-(void)addButtonTouchUp: (id)sender {

  [self setEditing: !self.editing animated: YES];
}

-(void)cancelButtonTouchUp: (id)sender {

  [self setEditing: NO animated: YES];
}

-(void)reloadTableViewData {
  dispatch_async(dispatch_get_main_queue(), ^(void){
    [_tableView reloadData];
  });
}

#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  
  NSInteger ret = 0;
  
  AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];
  
  if (akAddressBook.status >= kAddressBookOnline) {
    ret = [[akAddressBook sources] count];
  }
  
  return ret;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

  AKSource *source = [[[AKAddressBook sharedInstance] sources] objectAtIndex: section];
  NSInteger ret = [[source groups] count];
  if (self.editing && [source hasEditableGroups]) ret += 1;
  return ret;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"Cell";

  AKGroupsViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[AKGroupsViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }

  [cell setParent: self];

  [cell configureCellAtIndexPath: indexPath];

  return (UITableViewCell *)cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection: (NSInteger)section {

  AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];

  NSInteger sourceCount = [akAddressBook.sources count];
  AKSource *source = [[akAddressBook sources] objectAtIndex: section];
  return (sourceCount > 1) ? [source typeName] : nil;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {

  AKSource *source = [[[AKAddressBook sharedInstance] sources] objectAtIndex: indexPath.section];

  if (indexPath.row == [source.groups count])
    return UITableViewCellEditingStyleInsert;

  AKGroup *group = [source.groups objectAtIndex: indexPath.row];
  if (group.recordID == kGroupAggregate)
    return UITableViewCellEditingStyleNone;

  return UITableViewCellEditingStyleDelete;    
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


// Override to support rearranging the table view.
-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {

}

// Override to support conditional rearranging of the table view.
-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {

  AKSource *source = [[[AKAddressBook sharedInstance] sources] objectAtIndex: indexPath.section];

  if (indexPath.row == [source.groups count])
    return NO;

  AKGroup *group = [source.groups objectAtIndex: indexPath.row];
  if (group.recordID == kGroupAggregate)
    return NO;

  return YES;
}

#pragma mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {

  NSInteger row = 1;
  if (sourceIndexPath.section != proposedDestinationIndexPath.section) {
    if (sourceIndexPath.section < proposedDestinationIndexPath.section) {
      row = [tableView numberOfRowsInSection: sourceIndexPath.section] - 2;
    }
  } else {
    if (proposedDestinationIndexPath.row == 0) {
      row = 1;
    } else if (proposedDestinationIndexPath.row == [tableView numberOfRowsInSection: sourceIndexPath.section] - 1) {
      row = [tableView numberOfRowsInSection: sourceIndexPath.section] - 2;
    } else {
      row = proposedDestinationIndexPath.row;
    }
  }
  return [NSIndexPath indexPathForRow:row inSection: sourceIndexPath.section];
}

-(NSIndexPath *)tableView: (UITableView *)tableView willSelectRowAtIndexPath: (NSIndexPath *)indexPath {
  return indexPath;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

  AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];
  
  AKSource *source = [akAddressBook.sources objectAtIndex: indexPath.section];
  AKGroup *group = [source.groups objectAtIndex: indexPath.row];

  [akAddressBook setSourceID: [source recordID]];
  [akAddressBook setGroupID: [group recordID]];
  [akAddressBook resetSearch];

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
