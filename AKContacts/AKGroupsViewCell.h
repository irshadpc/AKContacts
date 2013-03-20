//
//  AKGroupsViewCell.h
//  AKContacts
//
//  Created by Adam Kornafeld on 3/19/13.
//  Copyright (c) 2013 Adam Kornafeld. All rights reserved.
//

#import <UIKit/UIKit.h>

@class  AKGroupsViewController;

@interface AKGroupsViewCell : UITableViewCell <UITextFieldDelegate>

@property (nonatomic, strong) AKGroupsViewController *parent;

-(void)configureCellAtIndexPath: (NSIndexPath *)indexPath;

@end
