//
//  AKContactAddressViewCell.h
//
//  Copyright (c) 2013 Adam Kornafeld All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>

@class AKContactViewController;

@interface AKContactAddressViewCell : UITableViewCell <UITextFieldDelegate> {
  
}

@property (nonatomic) AKContactViewController *parent;

-(void)configureCellAtRow: (NSInteger)row;

@end
