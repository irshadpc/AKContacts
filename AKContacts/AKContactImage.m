//
//  AKContactImage.m
//  AKContacts
//
//  Created by Adam Kornafeld on 6/8/13.
//  Copyright (c) 2013 Adam Kornafeld. All rights reserved.
//

#import "AKContactImage.h"
#import "AKContact.h"
#import "AKContactViewController.h"
#import "AppDelegate.h" // SYSTEM_VERSION

#import <QuartzCore/QuartzCore.h> // Image Layer

@interface AKContactImage () <UIActionSheetDelegate>

@property (strong, nonatomic) AKContactViewController *controller;
@property (strong, nonatomic) UIView *editBackground;
@property (strong, nonatomic) UILabel *editLabel;

@end

@implementation AKContactImage

- (id)initWithFrame:(CGRect)frame andController:(AKContactViewController *)controller
{
    self = [super initWithFrame:frame];
    if (self) {
      _controller = controller;
      
      [self setBackgroundColor: [UIColor clearColor]];
      [self setUserInteractionEnabled: NO];
      [self addTarget: self action: @selector(contactImageTouchUpInside:) forControlEvents: UIControlEventTouchUpInside];
      [self.layer setBorderColor: [[UIColor whiteColor] CGColor]];
      [self.layer setMasksToBounds:YES];
      if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
      {
        CAShapeLayer *circle = [CAShapeLayer layer];
        CGRect rect = CGRectMake(5.f, 5.f, self.frame.size.width*.84, self.frame.size.height*.84);
        circle.path = [UIBezierPath bezierPathWithOvalInRect: rect].CGPath;
        circle.fillColor = [UIColor blackColor].CGColor;
        [self.layer setMask: circle];
      }
      else
      {
        [self.layer setBorderWidth: 4.f];
        [self.layer setShadowColor: [UIColor grayColor].CGColor];
        [self.layer setShadowOffset: CGSizeMake(0, 1)];
        [self.layer setShadowOpacity: 1];
        [self.layer setShadowRadius: 1.0];
      }
      [self setContentMode: UIViewContentModeScaleAspectFit];
 
      [self setEditBackground: [[UIView alloc] initWithFrame: CGRectMake(4.f, 45.f, 56.f, 15.f)]];
      [self.editBackground setBackgroundColor: [UIColor colorWithWhite: 0.f alpha: .2f]];
      [self.editBackground setUserInteractionEnabled: NO];
      [self addSubview: self.editBackground];
      [self setEditLabel: [[UILabel alloc] initWithFrame: CGRectMake(4.f, 45.f, 56.f, 15.f)]];
      [self.editLabel setText: NSLocalizedString(@"edit", @"")];
      [self.editLabel setTextColor: [UIColor whiteColor]];
      [self.editLabel setShadowColor: [UIColor grayColor]];
      [self.editLabel setShadowOffset: CGSizeMake(0.f, 1.f)];
      [self.editLabel setBackgroundColor: [UIColor clearColor]];
      [self.editLabel setTextAlignment: NSTextAlignmentCenter];
      [self.editLabel setFont: [UIFont boldSystemFontOfSize: 12.f]];
      [self.editLabel setUserInteractionEnabled: NO];
      [self addSubview: self.editLabel];
      
    }
    return self;
}

- (void)setEditing: (BOOL)editing
{
  [self setUserInteractionEnabled: editing];
  [self.editLabel setHidden: (editing == NO)];
  [self.editBackground setHidden: (editing == NO)];
}

- (void)contactImageTouchUpInside: (id)sender
{
  UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle: nil
                                                           delegate: self
                                                  cancelButtonTitle: nil
                                             destructiveButtonTitle: nil
                                                  otherButtonTitles: nil];
  NSString *label = nil;
  if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera] == YES)
  {
    label = NSLocalizedString(@"Take Photo", @"");
    [actionSheet addButtonWithTitle: label];
  }
  label = NSLocalizedString(@"Choose Photo", @"");
  [actionSheet addButtonWithTitle: label];
  if ([self.controller.contact imageData] != nil)
  {
    label = NSLocalizedString(@"Delete Photo", @"");
    [actionSheet addButtonWithTitle: label];
  }
  label = NSLocalizedString(@"Cancel", @"");
  [actionSheet addButtonWithTitle: label];
  [actionSheet setCancelButtonIndex: (actionSheet.numberOfButtons - 1)];
  [actionSheet showInView: self.controller.view];
}

#pragma mark - UIActionsheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if (buttonIndex != actionSheet.cancelButtonIndex)
  {
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    [cameraUI setMediaTypes: [[NSArray alloc] initWithObjects: (NSString *)kUTTypeImage, nil]];
    [cameraUI setAllowsEditing: YES];
    [cameraUI setDelegate: self.controller];
    
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera] == YES)
    {
      if (buttonIndex == 0)
      { // Take
        [cameraUI setSourceType: UIImagePickerControllerSourceTypeCamera];
        [self.controller presentModalViewController: cameraUI animated: YES];
      }
      else if (buttonIndex == 1)
      { // Choose
        [cameraUI setSourceType: UIImagePickerControllerSourceTypePhotoLibrary];
        [self.controller presentModalViewController: cameraUI animated: YES];
      }
      else if (buttonIndex == 2)
      { // Delete
        [self.controller.contact setImageData: nil];
        NSString *imageName = ([self.controller.contact recordType] == kABPersonType) ? @"Contact" : @"Company";
        [self setImage: [UIImage imageNamed: imageName] forState: UIControlStateNormal];
      }
    }
    else
    {
      if (buttonIndex == 0)
      { // Choose
        [cameraUI setSourceType: UIImagePickerControllerSourceTypePhotoLibrary];
        [self.controller presentModalViewController: cameraUI animated: YES];
      }
      else if (buttonIndex == 1)
      { // Delete
        [self.controller.contact setImageData: nil];
        NSString *imageName = ([self.controller.contact recordType] == kABPersonType) ? @"Contact" : @"Company";
        [self setImage: [UIImage imageNamed: imageName] forState: UIControlStateNormal];        
      }
    }
  }
  [actionSheet dismissWithClickedButtonIndex: buttonIndex animated: YES];
}

@end
