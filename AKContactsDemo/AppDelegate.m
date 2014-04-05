//
//  AppDelegate.m
//  AKContacts
//
//  Copyright (c) 2013 Adam Kornafeld. All rights reserved.
//

#import "AppDelegate.h"
#import "AKAddressBook.h"
#import "AKContactsViewController.h"
#import "AKGroupsViewController.h"
#import "AKMessenger.h"

@interface AppDelegate () <AKMessengerDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    [[AKAddressBook sharedInstance] requestAddressBookAccessWithCompletionHandler:^(BOOL granted) {
        if (granted)
        {
            [[AKAddressBook sharedInstance] loadAddressBook];
        }
    }];
    
    UIViewController *rootViewController = (ShowGroups == YES) ? [[AKGroupsViewController alloc] init] : [[AKContactsViewController alloc] init];
    
    self.navigationController = [[UINavigationController alloc] initWithRootViewController: rootViewController];
    self.window.rootViewController = self.navigationController;
    
    if (ShowGroups == YES) {
        [rootViewController setTitle: NSLocalizedString(@"Groups", @"")];
        [self.navigationController pushViewController: [[AKContactsViewController alloc] init] animated: NO];
    }
    
    [[AKMessenger sharedInstance] setDelegate: self];
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - AKMessenger delegate

- (void)presentModalComposeEmailViewController: (UIViewController *)viewController
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    [self.navigationController presentViewController: viewController animated: YES completion: nil];
#else
    [self.navigationController presentModalViewController: viewController animated: YES];
#endif
}

- (void)presentModalComposeMessageViewController: (UIViewController *)viewController
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    [self.navigationController presentViewController: viewController animated: YES completion: nil];
#else
    [self.navigationController presentModalViewController: viewController animated: YES];
#endif
}

- (void)presentActionSheet: (UIActionSheet *)actionSheet
{
    [actionSheet showInView: self.navigationController.view];
}

- (void)dismissModalViewController
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    [self.navigationController dismissViewControllerAnimated: YES completion: nil];
#else
    [self.navigationController dismissModalViewControllerAnimated: YES];
#endif
}

@end
