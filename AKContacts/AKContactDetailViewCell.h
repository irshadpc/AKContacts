//
//  AKContactDetailViewCell.h
//
//  Copyright (c) 2013 Adam Kornafeld All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>

@class AKContactViewController;

@interface AKContactDetailViewCell : UITableViewCell <UITextFieldDelegate, UITextViewDelegate> {
  
}

@property (nonatomic) AKContactViewController *parent;

-(void)configureCellForProperty: (ABPropertyID)property atRow: (NSInteger)row;
-(void)showDatePicker;
-(void)openURLForSocialProfile;

@end
