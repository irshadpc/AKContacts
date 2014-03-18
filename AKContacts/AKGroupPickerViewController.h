//
//  AKGroupPickerViewController.h
//  AKContacts
//
//  Created by Adam Kornafeld on 5/21/13.
//  Copyright (c) 2013 Adam Kornafeld. All rights reserved.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString *const AKGroupPickerViewDidDismissNotification;

@interface AKGroupPickerViewController : UIViewController

/**
 * Create a group picker view with a contactID
 */
- (id)initWithContactID: (ABRecordID)contactID;

@end
