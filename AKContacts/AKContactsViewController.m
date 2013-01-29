//
//  AKContactsViewController.m
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

#import "AKContactsViewController.h"
#import "AKContact.h"
#import "AddressBookManager.h"
#import "Constants.h"
#import "AppDelegate.h"

@implementation AKContactsViewController

@synthesize tableView;
@synthesize searchBar;

#pragma mark - View lifecycle

- (void)loadView {

  CGFloat navBarHeight = ([self.navigationController isNavigationBarHidden]) ? 0.f :
  self.navigationController.navigationBar.frame.size.height;

  [self setTableView: [[UITableView alloc] initWithFrame: CGRectMake(0.f, 0.f, 320.f, 460.f - navBarHeight)
                                                   style: UITableViewStylePlain]];
  [self.tableView setDataSource: self];
  [self.tableView setDelegate: self];

  [self setSearchBar: [[UISearchBar alloc] initWithFrame: CGRectMake(0.f, 0.f, 320.f, defaultCellHeight)]];
  [self.tableView setTableHeaderView: searchBar];
  [self.searchBar setDelegate: self];

  [self setView: [[UIView alloc] init]];
  [self.view addSubview: self.tableView];
}

-(void)viewDidLoad {
  [super viewDidLoad];
  
  // Uncomment the following line to preserve selection between presentations.
  // self.clearsSelectionOnViewWillAppear = NO;
  
  // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
  // self.navigationItem.rightBarButtonItem = self.editButtonItem;

  appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reloadTableViewData) name: AddressBookDidLoadNotification object: nil];

}

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  if (self.tableView.contentOffset.y <= self.searchBar.frame.size.height)
    self.tableView.contentOffset = CGPointMake(0.f, self.searchBar.frame.size.height);
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

-(BOOL)tableViewCellVisibleForIndexPath: (NSIndexPath *)indexPath {
  BOOL ret = NO;
  
  NSArray *indexPathForVisibleCells = [self.tableView indexPathsForVisibleRows];
  
  for (NSIndexPath *index in indexPathForVisibleCells) {
    if (index.section == indexPath.section &&
        index.row == indexPath.row) {
      ret = YES;
      break;
    }
  }
  
  return ret;
}

-(void)reloadTableViewData {
  dispatch_async(dispatch_get_main_queue(), ^(void){
    [self.tableView reloadData];
  });
}

#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  
  if (appDelegate.addressBookManager.status >= kAddressBookOnline)
    return ([appDelegate.addressBookManager contactsCount] > 0) ? [appDelegate.addressBookManager.keys count] : 1;
  else
    return 1;
  
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSInteger ret = 4;

  if (appDelegate.addressBookManager.status >= kAddressBookOnline) {
    if ([appDelegate.addressBookManager contactsCount] == 0) return ret;

    if ([appDelegate.addressBookManager.keys count] > section) {
      NSString *key = [appDelegate.addressBookManager.keys objectAtIndex: section];
      NSArray *nameSection = [appDelegate.addressBookManager.contactIdentifiersToDisplay objectForKey: key];
      ret = [nameSection count];
    }
  } else {
    ret = 8;
  }
  return ret;
}
 
-(UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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

  NSInteger section = [indexPath section];
  NSInteger row = [indexPath row];

  if (appDelegate.addressBookManager.status >= kAddressBookOnline) {
    if ([appDelegate.addressBookManager contactsCount] == 0) {
      [cell setAccessoryView: nil];

      [cell.textLabel setFont:[UIFont boldSystemFontOfSize: 17.f]];
      [cell.textLabel setTextAlignment: NSTextAlignmentCenter];
      [cell.textLabel setTextColor: [UIColor lightGrayColor]];
      if ([self.searchBar isFirstResponder]) {
        if (row == 2) {
          [cell.textLabel setText: @"No Results"];
        }
      } else {
        if (row == 3) {
          [cell.textLabel setText: @"No Contacts"];
        }
      }
    } else {
      NSString *key = nil;
      if ([appDelegate.addressBookManager.keys count] > section)
        key = [appDelegate.addressBookManager.keys objectAtIndex: section];

      NSArray *identifiersArray = [appDelegate.addressBookManager.contactIdentifiersToDisplay objectForKey: key];
      if ([identifiersArray count] == 0) return cell;
      NSNumber *recordId = [identifiersArray objectAtIndex: row];
      AKContact *contact = [appDelegate.addressBookManager contactForIdentifier: [recordId integerValue]];
      if (!contact) return cell;
      [cell setTag: [contact recordID]];
      [cell setSelectionStyle: UITableViewCellSelectionStyleBlue];
      
      [cell setAccessoryView: nil];
      if (![contact displayName]) {
        cell.textLabel.font = [UIFont italicSystemFontOfSize: 20];
        cell.textLabel.text = @"No Name";
      } else {
        cell.textLabel.font = [UIFont boldSystemFontOfSize: 20];
        cell.textLabel.text = [contact displayName];
      }
    }
  } else {
    [cell setAccessoryView: nil];

    if (row == 3) {
      [cell.textLabel setTextColor: [UIColor grayColor]];
      [cell.textLabel setTextAlignment: NSTextAlignmentCenter];
      if (appDelegate.addressBookManager.status == kAddressBookInitializing) {
        [cell.textLabel setText: @"Loading address book..."];
        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleGray];
        [cell setAccessoryView: activity];
        [activity startAnimating];
      } else if (appDelegate.addressBookManager.status == kAddressBookOffline) {
        [cell.textLabel setText: @"No Contacts"];
      }
    }
  }

  return cell;
}

-(NSString *)tableView:(UITableView *)table titleForHeaderInSection: (NSInteger)section {
  
  NSString *ret = @"";  
  if ([appDelegate.addressBookManager.keys count] == 0) return ret;
  
  NSString *key = nil;
  if ([appDelegate.addressBookManager.keys count] > section) {
    key = [appDelegate.addressBookManager.keys objectAtIndex: section];
    NSArray *nameSection = [appDelegate.addressBookManager.contactIdentifiersToDisplay objectForKey: key];
    if ([nameSection count] > 0) ret = key;
  }
  return ret;
}

-(NSArray *)sectionIndexTitlesForTableView:(UITableView *)table {

  BOOL index = YES;
  if ([self.searchBar isFirstResponder] ||
      [self.searchBar.text length] > 0 ||
      [[appDelegate.addressBookManager keys] count] > 0)
    index = NO;
  
  return (index) ? [appDelegate.addressBookManager keys] : nil;
}

-(NSInteger)tableView:(UITableView *)table sectionForSectionIndexTitle:(NSString *)title 
              atIndex:(NSInteger)index { 
  NSInteger ret = NSNotFound;
  if ([appDelegate.addressBookManager.keys count] > index) {
    NSString *key = [appDelegate.addressBookManager.keys objectAtIndex: index]; 
    if (key == UITableViewIndexSearch) {
      [table setContentOffset: CGPointZero animated:NO];
      ret = NSNotFound;
    } else {
      ret = index; 
    }
  }
  return ret;
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

-(void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
  [table deselectRowAtIndexPath: indexPath animated: YES];
}

-(NSIndexPath *)tableView: (UITableView *)table willSelectRowAtIndexPath: (NSIndexPath *)indexPath {
  [searchBar resignFirstResponder];
  return indexPath;
}

#pragma mark - Search Bar delegate

-(void)searchBarTextDidBeginEditing:(UISearchBar *)search {
	[search becomeFirstResponder];
	[search setShowsCancelButton: YES animated: YES];
  [self.tableView reloadData]; // To hide index
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)search {
	[search resignFirstResponder];
	[search setShowsCancelButton:NO animated:YES];
  [self.tableView reloadData]; // To show index
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)search {
  
  NSString *searchTerm = [search text];
  [appDelegate.addressBookManager handleSearchForTerm: searchTerm];
  [self.tableView reloadData];
}

-(void)searchBar: (UISearchBar *)searchBar textDidChange: (NSString *)searchTerm {
  
  if ([searchTerm length] == 0) {
    [appDelegate.addressBookManager resetSearch];
    [self.tableView reloadData];
    return;
  }
  [appDelegate.addressBookManager handleSearchForTerm: searchTerm];
  [self.tableView reloadData];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)search {
  
  search.text = @"";
  [appDelegate.addressBookManager resetSearch];
  [self.tableView reloadData];
  [searchBar resignFirstResponder];
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
