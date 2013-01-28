//
//  AKContactsViewController.h
//
//  Copyright (c) 2013 Adam Kornafeld All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@class AppDelegate;

@interface AKContactsViewController : UIViewController
  <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate> {

  UITableView* tableView;
  UISearchBar *searchBar;

  AppDelegate *appDelegate;

}

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) UISearchBar *searchBar;

-(void)reloadTableViewData;

@end
