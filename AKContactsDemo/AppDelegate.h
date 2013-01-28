//
//  AppDelegate.h
//  AKContacts
//
//  Created by Adam Kornafeld on 1/28/13.
//  Copyright (c) 2013 Adam Kornafeld. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AddressBookManager;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) AddressBookManager *addressBookManager;

@end
