//
//  AKContactImage.h
//  AKContacts
//
//  Created by Adam Kornafeld on 6/8/13.
//  Copyright (c) 2013 Adam Kornafeld. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MobileCoreServices/MobileCoreServices.h> // kUTTypeImage

@class AKContactViewController;

@interface AKContactImage : UIButton

- (id)initWithFrame:(CGRect)frame andDelegate: (AKContactViewController *)delegate;
- (void)setEditing: (BOOL)editing;

@end
