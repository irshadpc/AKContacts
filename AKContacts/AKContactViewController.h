//
//  AKContactViewController.h
//
//  Copyright (c) 2013 Adam Kornafeld All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, Sections) {
  /* Default Sections */
  kSectionHeader,
  kSectionPhoneNumbers,
  kSectionEmailAddresses,
  kSectionURLs,
  kSectionAddresses,
  kSectionBirthday,
  kSectionDate,
  kSectionSocialProfiles,
  kSectionInstantMessengers,
  kSectionNotes,
  kSectionButtons,
  /* Custom Sections Go Below */
  kSectionSwitch,
};

@class AKContact;

@interface AKContactViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
  
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic) AKContact *contact;

@end
