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
#import "AKContactsProgressIndicatorView.h"
#import "AKContactsRecordViewCell.h"
#import "AKContact.h"
#import "AKContactPickerViewController.h"
#import "AKContactViewController.h"
#import "AKGroup.h"
#import "AKSource.h"
#import "AKGroupPickerViewController.h"
#import "AKGroupsViewController.h"
#import "AKContactPickerViewController.h"
#import "AKContactsTableViewDataSource.h"
#import "AKAddressBook+Loader.h"

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

static const float defaultCellHeight = 44.f;
static const int manyContacts = 20;

typedef NS_ENUM(NSInteger, ActionSheetButtons)
{
  kButtonNewContact = 0,
  kButtonExistingContact,
  kButtonCancel,
  NUM_ACTIONSHEET_BUTTONS
};

@interface AKContactsViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UIActionSheetDelegate, AKContactViewControllerDelegate>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) AKContactsTableViewDataSource *dataSource;

- (void)presentNewContactViewController;
- (void)presentContactPickerViewController;
- (void)presentAddToGroupActionSheet;
- (void)addButtonTouchUpInside: (id)sender;
- (void)reloadTableViewData;
- (void)toggleBackButton;
- (void)setRightBarButtonItem;
/**
 * AKContactViewControllerDelegate
 */
- (void)modalViewDidDismissWithContactID: (NSInteger)contactID;
- (void)recordDidRemoveWithContactID: (NSInteger)contactID;
/**
 * Keyboard notification handlers
 */
- (void)keyboardWillShow: (NSNotification *)notification;
- (void)keyboardWillHide: (NSNotification *)notification;

@end

@implementation AKContactsViewController

#pragma mark - View lifecycle

- (void)dealloc
{
  NSString *keyPath = NSStringFromSelector(@selector(status));
  [[AKAddressBook sharedInstance] removeObserver: self forKeyPath: keyPath];
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  [AKAddressBook sharedInstance].dataSourceDelegate = nil;
}

- (void)loadView
{
  CGFloat width = [UIScreen mainScreen].bounds.size.width;
  CGFloat height = [UIScreen mainScreen].bounds.size.height;
  if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
    height -= (self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height);
  }
  self.tableView = [[UITableView alloc] initWithFrame: CGRectMake(0.f, 0.f, width, height) style: UITableViewStylePlain];
  self.dataSource = [[AKContactsTableViewDataSource alloc] init];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;

  self.searchBar = [[UISearchBar alloc] initWithFrame: CGRectMake(0.f, 0.f, 320.f, defaultCellHeight)];
  self.tableView.tableHeaderView = self.searchBar;
  self.searchBar.delegate = self;
  self.searchBar.barStyle = UIBarStyleDefault;

  self.view = self.tableView;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.edgesForExtendedLayout = UIRectEdgeLeft | UIRectEdgeBottom | UIRectEdgeRight;

  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reloadTableViewData) name: AKGroupPickerViewDidDismissNotification object: nil];

  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reloadTableViewData) name: AKContactPickerViewDidDismissNotification object: nil];

  NSString *keyPath = NSStringFromSelector(@selector(status));
  [[AKAddressBook sharedInstance] addObserver: self
                                   forKeyPath: keyPath
                                      options: NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                                      context: nil];

  [AKAddressBook sharedInstance].dataSourceDelegate = self;

  [self.dataSource resetSearch];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  [self toggleBackButton];

  [self setRightBarButtonItem];

  if ([self.searchBar.text length] > 0)
  {
    [self.searchBar becomeFirstResponder];
  }
  else
  {
    [self.tableView setTableHeaderView: (self.dataSource.displayedContactsCount > manyContacts) ? self.searchBar : nil];

    if (self.tableView.tableHeaderView && self.tableView.contentOffset.y <= self.searchBar.frame.size.height)
      self.tableView.contentOffset = CGPointMake(0.f, self.searchBar.frame.size.height);
  }
  
  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(keyboardWillShow:)
                                               name: UIKeyboardWillShowNotification object: nil];
  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(keyboardWillHide:)
                                               name: UIKeyboardWillHideNotification object: nil];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];

  [[NSNotificationCenter defaultCenter] removeObserver: self name: UIKeyboardWillShowNotification object: nil];
  [[NSNotificationCenter defaultCenter] removeObserver: self name: UIKeyboardWillHideNotification object: nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
}

#pragma mark - AKContactViewController delegate

- (void)modalViewDidDismissWithContactID: (NSInteger)contactID
{
  [self.dataSource resetSearch];
  [self reloadTableViewData];
  AKContactViewController *contactView = [[AKContactViewController alloc] initWithContactID: contactID];
  [contactView setDelegate: self];
  [self.navigationController pushViewController: contactView animated: NO];
}

- (void)recordDidRemoveWithContactID: (NSInteger)contactID
{
  [self.dataSource resetSearch];
  [self reloadTableViewData];
  
  id rootViewController = [self.navigationController.viewControllers objectAtIndex: 0];
  
  if ([rootViewController isKindOfClass: [AKGroupsViewController class]])
  { // Update group count badge
    [(AKGroupsViewController *)rootViewController reloadTableViewData];
  }
}

#pragma mark - Custom methods

- (void)presentNewContactViewController
{
  AKContactViewController *contactView = [[AKContactViewController alloc] initWithContactID: newContactID];
  [contactView setDelegate: self];
  UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController: contactView];
  
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
  [self.navigationController presentViewController: navigationController animated: YES completion: nil];
#else
  [self.navigationController presentModalViewController: navigationController animated: YES];
#endif
}

- (void)presentContactPickerViewController
{
  AKContactPickerViewController *contactView = [[AKContactPickerViewController alloc] init];
  UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController: contactView];

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
  [self.navigationController presentViewController: navigationController animated: YES completion: nil];
#else
  [self.navigationController presentModalViewController: navigationController animated: YES];
#endif
}

- (void)presentAddToGroupActionSheet
{
  NSString *title = NSLocalizedString(@"Add to Group:", @"");
  UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle: title
                                                           delegate: self
                                                  cancelButtonTitle: nil
                                             destructiveButtonTitle: nil
                                                  otherButtonTitles: nil];
  NSString *label = NSLocalizedString(@"New Contact", @"");
  [actionSheet addButtonWithTitle: label];
  label = NSLocalizedString(@"Existing Contact", @"");
  [actionSheet addButtonWithTitle: label];
  label = NSLocalizedString(@"Cancel", @"");
  [actionSheet addButtonWithTitle: label];
  [actionSheet setCancelButtonIndex: (actionSheet.numberOfButtons - 1)];
  [actionSheet showInView: self.view];
}

- (void)addButtonTouchUpInside: (id)sender
{
  if ([AKAddressBook sharedInstance].groupID < 0)
  {
    [self presentNewContactViewController];
  }
  else
  {
    [self presentAddToGroupActionSheet];
  }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{ // This is not dispatched on main queue

  NSString *statusKeyPath = NSStringFromSelector(@selector(status));
  if (object == [AKAddressBook sharedInstance] && [keyPath isEqualToString: statusKeyPath])
  {
    NSInteger oldValue = [[change objectForKey: NSKeyValueChangeOldKey] integerValue];
    NSInteger newValue = [[change objectForKey: NSKeyValueChangeNewKey] integerValue];

    if (!(oldValue == kAddressBookLoading && newValue == kAddressBookOnline) &&
        !(oldValue == kAddressBookOnline && newValue == kAddressBookLoading))
    {
        [self reloadTableViewData];

        [self toggleBackButton];
    }
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

    if (sourceCount > 1 || groupCount > 1) {
      [self.navigationItem setHidesBackButton: NO];
    }
    else {
      [self.navigationItem setHidesBackButton: YES];
    }
  };

  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_async(dispatch_get_main_queue(), block);
}

- (void)setRightBarButtonItem
{
  AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];
  
  if ([akAddressBook sourceForSourceId: akAddressBook.sourceID].canCreateRecord == YES)
  { // Display 'Add' button only if source supports create records
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemAdd
                                                                               target: self
                                                                               action: @selector(addButtonTouchUpInside:)];
    [self.navigationItem setRightBarButtonItem: addButton];
  }
}

- (void)reloadTableViewData
{
  dispatch_block_t block = ^{
    if ([self.searchBar isFirstResponder] == NO)
    {
      [self.tableView setTableHeaderView: (self.dataSource.displayedContactsCount > manyContacts) ? self.searchBar : nil];

      if (self.tableView.tableHeaderView && self.tableView.contentOffset.y <= self.searchBar.frame.size.height)
        self.tableView.contentOffset = CGPointMake(0.f, self.searchBar.frame.size.height);
    }

    [self setRightBarButtonItem];

    [self.dataSource resetSearch];

    CGPoint offset = self.tableView.contentOffset;
    [self.tableView reloadData];
    self.tableView.contentOffset = offset;
  };

  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_async(dispatch_get_main_queue(), block);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];

  if (akAddressBook.status == kAddressBookOnline ||
      akAddressBook.status == kAddressBookLoading)
    return (self.dataSource.displayedContactsCount > 0) ? [self.dataSource.keys count] : 1;
  else
    return 1;
  
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  NSInteger ret = 8;

  AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];

  if (akAddressBook.status == kAddressBookOnline ||
      akAddressBook.status == kAddressBookLoading)
  {
    if (self.dataSource.displayedContactsCount > 0)
    {
      if ([self.dataSource.keys count] > section)
      {
        NSString *key = [self.dataSource.keys objectAtIndex: section];
        NSArray *nameSection = [self.dataSource.contactIdentifiers objectForKey: key];
        ret = [nameSection count];
      }
    }
  }
  return ret;
}
 
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];

  if (akAddressBook.status == kAddressBookOnline ||
      akAddressBook.status == kAddressBookLoading)
  {
    if (self.dataSource.displayedContactsCount == 0)
    {
      return [self noContactsCellAtIndexPath: indexPath];
    }
    else
    {
      return [self recordCellAtIndexPath: indexPath];
    }
  }
  else
  {
    if (akAddressBook.status == kAddressBookInitializing)
    {
      return [self loadingCellAtIndexPath: indexPath];
    }
    else
    {
      return [self noContactsCellAtIndexPath: indexPath];
    }      
  }
  return [self emptyCellView];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection: (NSInteger)section
{
  NSString *ret = @"";  
  if (self.dataSource.keys.count == 0) return ret;
  
  NSString *key = nil;
  if ([self.dataSource.keys count] > section)
  {
    key = [self.dataSource.keys objectAtIndex: section];
    NSArray *nameSection = [self.dataSource.contactIdentifiers objectForKey: key];
    if ([nameSection count] > 0) ret = key;
  }
  return ret;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
  BOOL index = YES;
  if ([AKAddressBook sharedInstance].status != kAddressBookOnline ||
      [self.searchBar isFirstResponder] ||
      [self.searchBar.text length] > 0 ||
      self.dataSource.displayedContactsCount < manyContacts)
    index = NO;

  return (index) ? self.dataSource.keys : nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
  NSInteger ret = NSNotFound;

  if (self.dataSource.keys.count > index)
  {
    NSString *key = [self.dataSource.keys objectAtIndex: index];
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

#pragma mark - Table view delegate

- (NSIndexPath *)tableView: (UITableView *)tableView willSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
//  [self.searchBar resignFirstResponder];
  return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView cellForRowAtIndexPath: indexPath];

  if (cell.tag != NSNotFound)
  {
    AKContactViewController *contactView = [[AKContactViewController alloc ] initWithContactID: cell.tag];
    [contactView setDelegate: self];
    [self.navigationController pushViewController: contactView animated: YES];
  }

  [tableView deselectRowAtIndexPath: indexPath animated: YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  if ([self.searchBar.text length] > 0)
  {
    if (self.tableView.contentOffset.y >= self.searchBar.frame.size.height)
    {
      [self.searchBar resignFirstResponder];
    }
  }
}

#pragma mark - Table View Cells

- (UITableViewCell *)emptyCellView
{
  static NSString *CellIdentifier = @"Cell";

  UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil)
  {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }

  [cell.textLabel setText: nil];
  [cell setAccessoryView: nil];
  [cell setTag: NSNotFound];
  [cell.textLabel setTextAlignment: NSTextAlignmentLeft];
  [cell.textLabel setTextColor: [UIColor blackColor]];
  [cell setSelectionStyle: UITableViewCellSelectionStyleNone];

  return cell;
}

- (UITableViewCell *)noContactsCellAtIndexPath: (NSIndexPath *)indexPath
{
  UITableViewCell *cell = [self emptyCellView];

  [cell.textLabel setFont:[UIFont boldSystemFontOfSize: 20.f]];
  [cell.textLabel setTextAlignment: NSTextAlignmentCenter];
  [cell.textLabel setTextColor: [UIColor lightGrayColor]];
  if ([self.searchBar isFirstResponder])
  {
    if (indexPath.row == 2)
    {
      [cell.textLabel setText: NSLocalizedString(@"No Results", @"")];
    }
  }
  else
  {
    if (indexPath.row == 3)
    {
      [cell.textLabel setText: NSLocalizedString(@"No Contacts", @"")];
    }
  }
  return cell;
}

- (UITableViewCell *)recordCellAtIndexPath: (NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"AKContactsRecordCellView";

  AKContactsRecordViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier: CellIdentifier];
  if (cell == nil)
  {
    cell = [[AKContactsRecordViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }

  [cell setController: self];

  [cell configureCellAtIndexPath: indexPath];

  return (UITableViewCell *)cell;
}

- (UITableViewCell *)loadingCellAtIndexPath: (NSIndexPath *)indexPath
{
  UITableViewCell *cell = [self emptyCellView];

  if (indexPath.row == 3)
  {
    [cell.textLabel setTextColor: [UIColor grayColor]];
    [cell.textLabel setTextAlignment: NSTextAlignmentCenter];
    [cell.textLabel setText: NSLocalizedString(@"Loading address book...", @"")];

    CGRect frame = CGRectMake(0.f, 0.f, 20.f, 20.f);
    AKContactsProgressIndicatorView *activity = [[AKContactsProgressIndicatorView alloc] initWithFrame: frame];
    [cell setAccessoryView: activity];
  }
  return cell;
}

#pragma mark - Keyboard 

- (void)keyboardWillShow: (NSNotification *)notification
{
  NSDictionary* info = [notification userInfo];
  CGSize kbSize = [[info objectForKey: UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
  
  UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.f, 0.f, kbSize.height, 0.f);
  [self.tableView setContentInset: contentInsets];
  [self.tableView setScrollIndicatorInsets: contentInsets];
}

- (void)keyboardWillHide: (NSNotification *)notification
{
  UIEdgeInsets contentInsets = UIEdgeInsetsZero;
  [self.tableView setContentInset: contentInsets];
  [self.tableView setScrollIndicatorInsets: contentInsets];
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
  [self.dataSource handleSearchForTerm: searchBar.text];
}

- (void)searchBar: (UISearchBar *)searchBar textDidChange: (NSString *)searchTerm
{
  if ([searchTerm length] == 0)
  {
    [self.dataSource resetSearch];
    [self.tableView reloadData];
  }
  else
  {
    [self.dataSource handleSearchForTerm: searchTerm];
  }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
  [searchBar setText: nil];
  [searchBar resignFirstResponder];
  [self.dataSource resetSearch];
  [self reloadTableViewData];
}

#pragma mark - UIActionsheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if (buttonIndex == kButtonNewContact)
  {
    [self presentNewContactViewController];
  }
  else if (buttonIndex == kButtonExistingContact)
  {
    [self presentContactPickerViewController];
  }
}

#pragma mark - AKAddressBookDataSourceDelegate

- (void)addressBookWillBeginUpdates: (AKAddressBook *)addressBook
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.tableView beginUpdates];
  });
}

- (void)addressBook: (AKAddressBook *)addressBook didInsertRecordID: (ABRecordID)recordID
{
  dispatch_block_t block = ^{
    AKContact *contact = [addressBook contactForContactId: recordID];
    NSString *sectionKey = [AKContact sectionKeyForName: contact.sortName];

    NSMutableArray *sectionArray = [self.dataSource.contactIdentifiers objectForKey: sectionKey];

    NSUInteger row = [AKAddressBook indexOfRecordID: recordID inArray: sectionArray
                                   withSortOrdering: addressBook.sortOrdering
                                  andAddressBookRef: addressBook.addressBookRef];

    [sectionArray insertObject: @(recordID) atIndex: row];

    NSUInteger section = [self.dataSource.keys indexOfObject: sectionKey];
    NSArray *sections = @[[NSIndexPath indexPathForRow: row inSection: section]];
    [self.tableView insertRowsAtIndexPaths: sections withRowAnimation: UITableViewRowAnimationAutomatic];
  };
  dispatch_async(dispatch_get_main_queue(), block);
}

- (void)addressBook: (AKAddressBook *)addressBook didRemoveRecordID: (ABRecordID)recordID
{
  dispatch_block_t block = ^{
    for (NSString *key in self.dataSource.contactIdentifiers)
    {
      NSMutableArray *sectionArray = [self.dataSource.contactIdentifiers objectForKey: key];
      NSUInteger row = [sectionArray indexOfObject: @(recordID)];
      if (row != NSNotFound)
      {
        NSUInteger section = [self.dataSource.keys indexOfObject: key];

        NSArray *sections = @[[NSIndexPath indexPathForRow: row inSection: section]];
        [sectionArray removeObjectAtIndex: row];

        [self.tableView deleteRowsAtIndexPaths: sections withRowAnimation: UITableViewRowAnimationAutomatic];
        break;
      }
    }
  };
  dispatch_async(dispatch_get_main_queue(), block);
}

- (void)addressBookDidEndUpdates: (AKAddressBook *)addressBook
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.tableView endUpdates];
  });
}

@end
