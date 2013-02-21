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
#import "AKContactViewController.h"
#import "AKAddressBook.h"
#import "AppDelegate.h"

static const float defaultCellHeight = 44.f;

@interface AKContactsViewController ()

@property (nonatomic, assign) AppDelegate *appDelegate;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchBar *searchBar;

@end

@implementation AKContactsViewController

@synthesize appDelegate = _appDelegate;

@synthesize tableView = _tableView;
@synthesize searchBar = _searchBar;

#pragma mark - View lifecycle

- (void)loadView {

  CGFloat navBarHeight = ([self.navigationController isNavigationBarHidden]) ? 0.f :
  self.navigationController.navigationBar.frame.size.height;

  [self setTableView: [[UITableView alloc] initWithFrame: CGRectMake(0.f, 0.f, 320.f, 460.f - navBarHeight)
                                                   style: UITableViewStylePlain]];
  [self.tableView setDataSource: self];
  [self.tableView setDelegate: self];

  [self setSearchBar: [[UISearchBar alloc] initWithFrame: CGRectMake(0.f, 0.f, 320.f, defaultCellHeight)]];
  [self.tableView setTableHeaderView: self.searchBar];
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

  [self setAppDelegate: (AppDelegate *)[[UIApplication sharedApplication] delegate]];
  
  UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemAdd
                                                                             target: self
                                                                             action: @selector(addButtonTouchUp:)];
  [self.navigationItem setRightBarButtonItem: addButton];

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

-(void)addButtonTouchUp: (id)sender {
  
  AKContactViewController *contactView = [[AKContactViewController alloc] initWithContact: nil];
  UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController: contactView];

  [self.navigationController presentViewController: navigationController animated: YES completion: ^{}];
}


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
  
  if (_appDelegate.akAddressBook.status >= kAddressBookOnline)
    return ([_appDelegate.akAddressBook contactsCount] > 0) ? [_appDelegate.akAddressBook.keys count] : 1;
  else
    return 1;
  
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSInteger ret = 4;

  if (_appDelegate.akAddressBook.status >= kAddressBookOnline) {
    if ([_appDelegate.akAddressBook contactsCount] == 0) return ret;

    if ([_appDelegate.akAddressBook.keys count] > section) {
      NSString *key = [_appDelegate.akAddressBook.keys objectAtIndex: section];
      NSArray *nameSection = [_appDelegate.akAddressBook.contactIdentifiers objectForKey: key];
      ret = [nameSection count];
    }
  } else {
    ret = 8;
  }
  return ret;
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

  NSInteger section = [indexPath section];
  NSInteger row = [indexPath row];

  if (_appDelegate.akAddressBook.status >= kAddressBookOnline) {
    if ([_appDelegate.akAddressBook contactsCount] == 0) {
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
      if ([_appDelegate.akAddressBook.keys count] > section)
        key = [_appDelegate.akAddressBook.keys objectAtIndex: section];

      NSArray *identifiersArray = [_appDelegate.akAddressBook.contactIdentifiers objectForKey: key];
      if ([identifiersArray count] == 0) return cell;
      NSNumber *recordId = [identifiersArray objectAtIndex: row];
      AKContact *contact = [_appDelegate.akAddressBook contactForIdentifier: [recordId integerValue]];
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
      if (_appDelegate.akAddressBook.status == kAddressBookInitializing) {
        [cell.textLabel setText: @"Loading address book..."];
        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleGray];
        [cell setAccessoryView: activity];
        [activity startAnimating];
      } else if (_appDelegate.akAddressBook.status == kAddressBookOffline) {
        [cell.textLabel setText: @"No Contacts"];
      }
    }
  }

  return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection: (NSInteger)section {
  
  NSString *ret = @"";  
  if ([_appDelegate.akAddressBook.keys count] == 0) return ret;
  
  NSString *key = nil;
  if ([_appDelegate.akAddressBook.keys count] > section) {
    key = [_appDelegate.akAddressBook.keys objectAtIndex: section];
    NSArray *nameSection = [_appDelegate.akAddressBook.contactIdentifiers objectForKey: key];
    if ([nameSection count] > 0) ret = key;
  }
  return ret;
}

-(NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {

  BOOL index = YES;
  if ([self.searchBar isFirstResponder] ||
      [self.searchBar.text length] > 0 ||
      [[_appDelegate.akAddressBook keys] count] > 0)
    index = NO;
  
  return (index) ? [_appDelegate.akAddressBook keys] : nil;
}

-(NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title
              atIndex:(NSInteger)index { 
  NSInteger ret = NSNotFound;
  if ([_appDelegate.akAddressBook.keys count] > index) {
    NSString *key = [_appDelegate.akAddressBook.keys objectAtIndex: index];
    if (key == UITableViewIndexSearch) {
      [tableView setContentOffset: CGPointZero animated:NO];
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

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
  UITableViewCell *cell = [tableView cellForRowAtIndexPath: indexPath];
  
  AKContact *contact = [_appDelegate.akAddressBook contactForIdentifier: cell.tag];
  
  AKContactViewController *contactView = [[AKContactViewController alloc ] initWithContact: contact];
  [self.navigationController pushViewController: contactView animated: YES];

  [tableView deselectRowAtIndexPath: indexPath animated: YES];
}

-(NSIndexPath *)tableView: (UITableView *)tableView willSelectRowAtIndexPath: (NSIndexPath *)indexPath {
  [self.searchBar resignFirstResponder];
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
  [_appDelegate.akAddressBook handleSearchForTerm: searchTerm];
  [self.tableView reloadData];
}

-(void)searchBar: (UISearchBar *)searchBar textDidChange: (NSString *)searchTerm {
  
  if ([searchTerm length] == 0) {
    [_appDelegate.akAddressBook resetSearch];
    [self.tableView reloadData];
    return;
  }
  [_appDelegate.akAddressBook handleSearchForTerm: searchTerm];
  [self.tableView reloadData];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)search {
  
  search.text = @"";
  [_appDelegate.akAddressBook resetSearch];
  [self.tableView reloadData];
  [self.searchBar resignFirstResponder];
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
