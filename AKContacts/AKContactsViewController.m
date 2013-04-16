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
#import "AKSource.h"

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

static const float defaultCellHeight = 44.f;
static const int manyContacts = 20;

@interface AKContactsViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, AKContactViewControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSString *searchTerm;

- (void)addButtonTouchUp: (id)sender;
- (void)reloadTableViewData;
- (void)toggleBackButton;
/**
 * AKContactViewControllerDelegate
 */
- (void)modalViewDidDismissedWithContactID: (NSInteger)contactID;

@end

@implementation AKContactsViewController

@synthesize tableView = _tableView;
@synthesize searchBar = _searchBar;

@synthesize searchTerm = _searchTerm;

#pragma mark - View lifecycle

- (void)loadView
{
  CGFloat navBarHeight = ([self.navigationController isNavigationBarHidden]) ? 0.f :
  self.navigationController.navigationBar.frame.size.height;

  [self setTableView: [[UITableView alloc] initWithFrame: CGRectMake(0.f, 0.f, 320.f, 460.f - navBarHeight)
                                                   style: UITableViewStylePlain]];
  [self.tableView setDataSource: self];
  [self.tableView setDelegate: self];

  [self setSearchBar: [[UISearchBar alloc] initWithFrame: CGRectMake(0.f, 0.f, 320.f, defaultCellHeight)]];
  [self.tableView setTableHeaderView: self.searchBar];
  [self.searchBar setDelegate: self];
  [self.searchBar setBarStyle: UIBarStyleDefault];
  
  [self setView: [[UIView alloc] init]];
  [self.view addSubview: self.tableView];
  
  [self setSearchTerm: nil];
}

-(void)viewDidLoad
{
  [super viewDidLoad];
  
  // Uncomment the following line to preserve selection between presentations.
  // self.clearsSelectionOnViewWillAppear = NO;
  
  // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
  // self.navigationItem.rightBarButtonItem = self.editButtonItem;

  UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemAdd
                                                                             target: self
                                                                             action: @selector(addButtonTouchUp:)];
  [self.navigationItem setRightBarButtonItem: addButton];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];
  
  [akAddressBook addObserver: self forKeyPath: @"status" options: NSKeyValueObservingOptionNew context: nil];
  
  [[NSNotificationCenter defaultCenter] addObserver: self
                                           selector: @selector(reloadTableViewData)
                                               name: AddressBookSearchDidFinishNotification
                                             object: nil];

  [self toggleBackButton];

  if ([self.searchTerm length] > 0)
  {
    [self.searchBar becomeFirstResponder];
  }
  else
  {
    [self.tableView setTableHeaderView: ([akAddressBook displayedContactsCount] > manyContacts) ? self.searchBar : nil];

    if (self.tableView.tableHeaderView && self.tableView.contentOffset.y <= self.searchBar.frame.size.height)
      self.tableView.contentOffset = CGPointMake(0.f, self.searchBar.frame.size.height);
  }
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];

  [[AKAddressBook sharedInstance] removeObserver: self forKeyPath: @"status"];
  [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
}

#pragma mark - AKContactViewController delegate

- (void)modalViewDidDismissedWithContactID: (NSInteger)contactID
{
  [[AKAddressBook sharedInstance] resetSearch];
  [self reloadTableViewData];
  AKContactViewController *contactView = [[AKContactViewController alloc] initWithContactID: contactID];
  [self.navigationController pushViewController: contactView animated: NO];
}

#pragma mark - Custom methods

- (void)addButtonTouchUp: (id)sender
{
  AKContactViewController *contactView = [[AKContactViewController alloc] initWithContactID: tagNewContact];
  [contactView setDelegate: self];
  UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController: contactView];
  
  if ([self.navigationController respondsToSelector:@selector(presentViewController:animated:completion:)])
    [self.navigationController presentViewController: navigationController animated: YES completion: nil];
  else
    [self.navigationController presentModalViewController: navigationController animated: YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  // This is not dispatched on main queue

  if (object == [AKAddressBook sharedInstance] && // Comparing the address
      [keyPath isEqualToString: @"status"])
  {
    // Status property of AKAddressBook changed
    [self reloadTableViewData];
    [self toggleBackButton];
  }
}

- (void)toggleBackButton
{
  dispatch_block_t block = ^{
    NSInteger sourceCount = [[[AKAddressBook sharedInstance] sources] count];
    NSInteger groupCount = 0;
    if (sourceCount == 1)
    {
      AKSource *source = [[[AKAddressBook sharedInstance] sources] objectAtIndex: 0];
      groupCount = [source.groups count];
    }
    
    if (sourceCount > 1 || groupCount > 1)
      [self.navigationItem setHidesBackButton: NO];
    else
      [self.navigationItem setHidesBackButton: YES];
  };

  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_async(dispatch_get_main_queue(), block);
}

- (void)reloadTableViewData
{
  dispatch_block_t block = ^{
    if ([self.searchBar isFirstResponder] == NO)
    {
      [self.tableView setTableHeaderView: ([[AKAddressBook sharedInstance] displayedContactsCount] > manyContacts) ? self.searchBar : nil];

      if (self.tableView.tableHeaderView && self.tableView.contentOffset.y <= self.searchBar.frame.size.height)
        self.tableView.contentOffset = CGPointMake(0.f, self.searchBar.frame.size.height);
    }
    [self.tableView reloadData];
  };

  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_async(dispatch_get_main_queue(), block);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  if ([AKAddressBook sharedInstance].status == kAddressBookOnline)
    return ([[AKAddressBook sharedInstance] displayedContactsCount] > 0) ? [[AKAddressBook sharedInstance].keys count] : 1;
  else
    return 1;
  
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  NSInteger ret = 8;

  AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];

  if (akAddressBook.status == kAddressBookOnline)
  {
    if ([akAddressBook displayedContactsCount] > 0)
    {
      if ([akAddressBook.keys count] > section)
      {
        NSString *key = [akAddressBook.keys objectAtIndex: section];
        NSArray *nameSection = [akAddressBook.contactIdentifiers objectForKey: key];
        ret = [nameSection count];
      }
    }
  }
  return ret;
}
 
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil)
  {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }

  [cell.textLabel setText: nil];
  [cell setTag: NSNotFound];
  [cell.textLabel setTextAlignment: NSTextAlignmentLeft];
  [cell.textLabel setTextColor: [UIColor blackColor]];
  [cell setSelectionStyle: UITableViewCellSelectionStyleNone];

  NSInteger section = [indexPath section];
  NSInteger row = [indexPath row];

  AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];
  
  if (akAddressBook.status == kAddressBookOnline)
  {
    if ([akAddressBook displayedContactsCount] == 0)
    {
      [cell setAccessoryView: nil];

      [cell.textLabel setFont:[UIFont boldSystemFontOfSize: 20.f]];
      [cell.textLabel setTextAlignment: NSTextAlignmentCenter];
      [cell.textLabel setTextColor: [UIColor lightGrayColor]];
      if ([self.searchBar isFirstResponder])
      {
        if (row == 2)
        {
          [cell.textLabel setText: NSLocalizedString(@"No Results", @"")];
        }
      }
      else
      {
        if (row == 3)
        {
          [cell.textLabel setText: NSLocalizedString(@"No Contacts", @"")];
        }
      }
    }
    else
    {
      NSString *key = nil;
      if ([akAddressBook.keys count] > section)
        key = [akAddressBook.keys objectAtIndex: section];

      NSArray *identifiersArray = [akAddressBook.contactIdentifiers objectForKey: key];
      if ([identifiersArray count] == 0) return cell;
      NSNumber *recordId = [identifiersArray objectAtIndex: row];
      AKContact *contact = [akAddressBook contactForContactId: [recordId integerValue]];
      if (!contact) return cell;
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
    }
  }
  else
  {
    [cell setAccessoryView: nil];

    if (row == 3)
    {
      [cell.textLabel setTextColor: [UIColor grayColor]];
      [cell.textLabel setTextAlignment: NSTextAlignmentCenter];
      if (akAddressBook.status == kAddressBookInitializing ||
          akAddressBook.status == kAddressBookLoading)
      {
        [cell.textLabel setText: NSLocalizedString(@"Loading address book...", @"")];
        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleGray];
        [cell setAccessoryView: activity];
        [activity startAnimating];
      }
      else if (akAddressBook.status == kAddressBookOffline)
      {
        [cell.textLabel setText: NSLocalizedString(@"No Contacts", @"")];
      }
    }
  }

  return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection: (NSInteger)section
{
  AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];
  NSString *ret = @"";  
  if ([akAddressBook.keys count] == 0) return ret;
  
  NSString *key = nil;
  if ([akAddressBook.keys count] > section)
  {
    key = [akAddressBook.keys objectAtIndex: section];
    NSArray *nameSection = [akAddressBook.contactIdentifiers objectForKey: key];
    if ([nameSection count] > 0) ret = key;
  }
  return ret;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
  AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];
  BOOL index = YES;
  if ([akAddressBook status] != kAddressBookOnline ||
      [self.searchBar isFirstResponder] ||
      [self.searchBar.text length] > 0 ||
      [akAddressBook displayedContactsCount] < manyContacts)
    index = NO;

  return (index) ? [akAddressBook keys] : nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
  NSInteger ret = NSNotFound;
  
  AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];
  
  if ([akAddressBook.keys count] > index)
  {
    NSString *key = [akAddressBook.keys objectAtIndex: index];
    if (key == UITableViewIndexSearch)
    {
      [tableView setContentOffset: CGPointZero animated:NO];
      ret = NSNotFound;
    }
    else
    {
      ret = index; 
    }
  }
  return ret;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
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
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (NSIndexPath *)tableView: (UITableView *)tableView willSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
//  [self.searchBar resignFirstResponder];
  return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView cellForRowAtIndexPath: indexPath];

  AKContactViewController *contactView = [[AKContactViewController alloc ] initWithContactID: cell.tag];
  [self.navigationController pushViewController: contactView animated: YES];

  [tableView deselectRowAtIndexPath: indexPath animated: YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  if ([self.searchTerm length] > 0)
  {
    if (self.tableView.contentOffset.y >= self.searchBar.frame.size.height)
    {
      [self.searchBar resignFirstResponder];
    }
  }
}

#pragma mark - Search Bar delegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
	[searchBar becomeFirstResponder];
	[searchBar setShowsCancelButton: YES animated: YES];
  [self.tableView reloadSectionIndexTitles]; // To hide index
  
  if (self.tableView.contentOffset.y >= self.searchBar.frame.size.height)
  {
    [UIView animateWithDuration: .3f
                          delay: .0f
                        options: UIViewAnimationOptionAllowUserInteraction
                     animations: ^{
                       self.tableView.contentOffset = CGPointMake(0.f, 0.f);
                     }
                     completion: nil];
  }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
	[searchBar resignFirstResponder];
	[searchBar setShowsCancelButton: NO animated: YES];
  [self.tableView reloadSectionIndexTitles]; // To show index
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
  [[AKAddressBook sharedInstance] handleSearchForTerm: searchBar.text];
}

- (void)searchBar: (UISearchBar *)searchBar textDidChange: (NSString *)searchTerm
{
  if ([searchTerm length] == 0)
  {
    [self setSearchTerm: nil];
    [[AKAddressBook sharedInstance] resetSearch];
    [self.tableView reloadData];
  }
  else
  {
    [self setSearchTerm: searchTerm];
    [[AKAddressBook sharedInstance] handleSearchForTerm: searchTerm];
  }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
  [self setSearchTerm: nil];
  [searchBar setText: nil];
  [searchBar resignFirstResponder];
  [[AKAddressBook sharedInstance] resetSearch];
  [self reloadTableViewData];
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
}

@end
