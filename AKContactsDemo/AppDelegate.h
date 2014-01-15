//
//  AppDelegate.h
//  AKContacts
//
//  Copyright (c) 2013 Adam Kornafeld. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AKAddressBook;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) AKAddressBook *akAddressBook;

@end
