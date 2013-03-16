//
//  AKContactDetailViewCell.m
//
//  Copyright (c) 2013 Adam Kornafeld All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions
//  are met:
//  1. Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright
//  notice, this list of conditions and the following disclaimer in the
//  documentation and/or other materials provided with the distribution.
//  3. The name of the author may not be used to endorse or promote products
//  derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
//  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
//  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "AKContactDetailViewCell.h"
#import "AKContact.h"
#import "AKContactViewController.h"
#import "AKAddressBook.h"

static const int editModeItem = 101;

@interface AKContactDetailViewCell ()

@property (nonatomic, assign) ABPropertyID abPropertyID;
@property (nonatomic, assign) NSInteger identifier;
@property (nonatomic, strong) UIActionSheet *actionSheet;

@end

@implementation AKContactDetailViewCell

@synthesize abPropertyID = _abPropertyID;
@synthesize identifier = _identifier;
@synthesize actionSheet = _actionSheet;

@synthesize parent;

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    // Initialization code
  }
  return self;
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {

  [super setSelected:selected animated:animated];

  // Configure the view for the selected state
}

-(void)configureCellForProperty:(ABPropertyID)property atRow:(NSInteger)row {

  [self setAbPropertyID: property];
  [self setIdentifier: NSNotFound];
  [self.textLabel setText: nil];
  [self.detailTextLabel setText: nil];
  [self.detailTextLabel setTextColor: [UIColor blackColor]];
  [self setSelectionStyle: UITableViewCellSelectionStyleBlue];

  AKContact *contact = [[AKAddressBook sharedInstance] contactForContactId: self.parent.contactID];

  if (self.abPropertyID == kABPersonPhoneProperty ||
      self.abPropertyID == kABPersonEmailProperty ||
      self.abPropertyID == kABPersonURLProperty) {

    if (row < [contact countForProperty: self.abPropertyID]) {

      NSArray *identifiers = [contact identifiersForProperty: self.abPropertyID];
      [self setIdentifier: [[identifiers objectAtIndex: row] integerValue]];
      
      [self.detailTextLabel setText: [contact valueForMultiValueProperty: self.abPropertyID forIdentifier: self.identifier]];
      [self.textLabel setText: [contact labelForMultiValueProperty: self.abPropertyID forIdentifier: self.identifier]];

    } else {
      CFStringRef value = ABAddressBookCopyLocalizedLabel(kABOtherLabel);
      [self.textLabel setText: [(__bridge NSString *)value lowercaseString]];
      CFRelease(value);
    }

  } else if (self.abPropertyID == kABPersonNoteProperty) {

    CFStringRef value = ABPersonCopyLocalizedPropertyName(self.abPropertyID);
    [self.textLabel setText: [(__bridge NSString *)value lowercaseString]];
    CFRelease(value);

  } else if (self.abPropertyID == kABPersonBirthdayProperty) {

    NSDate *date = (NSDate *)[contact valueForProperty: kABPersonBirthdayProperty];
    CFStringRef placeholder = (ABPersonCopyLocalizedPropertyName(kABPersonDateProperty));
    NSString *strDate = (date) ? [NSDateFormatter localizedStringFromDate: date
                                                                dateStyle: NSDateFormatterLongStyle
                                                                timeStyle: NSDateFormatterNoStyle] : (__bridge NSString *)placeholder;
    [self.detailTextLabel setText: strDate];
    CFRelease(placeholder);
    [self.detailTextLabel setTextColor: (date) ? [UIColor blackColor] : [UIColor lightGrayColor]];
    
    CFStringRef value = ABPersonCopyLocalizedPropertyName(self.abPropertyID);
    [self.textLabel setText: [(__bridge NSString *)value lowercaseString]];
    CFRelease(value);
    
    [self setSelectionStyle: UITableViewCellSelectionStyleNone];

  } else if (self.abPropertyID == kABPersonDateProperty) {

    if (row < [contact countForProperty: kABPersonDateProperty]) {
      
      NSArray *identifiers = [contact identifiersForProperty: self.abPropertyID];
      [self setIdentifier: [[identifiers objectAtIndex: row] integerValue]];

      NSDate *date = (NSDate *)[contact valueForMultiValueProperty: kABPersonDateProperty forIdentifier: self.identifier];
      CFStringRef placeholder = (ABPersonCopyLocalizedPropertyName(kABPersonDateProperty));
      NSString *strDate = (date) ? [NSDateFormatter localizedStringFromDate: date
                                                                  dateStyle: NSDateFormatterLongStyle
                                                                  timeStyle: NSDateFormatterNoStyle] : (__bridge NSString *)placeholder;
      [self.detailTextLabel setText: strDate];
      CFRelease(placeholder);
      [self.detailTextLabel setTextColor: (date) ? [UIColor blackColor] : [UIColor lightGrayColor]];
      NSString *label = [contact labelForMultiValueProperty: kABPersonDateProperty forIdentifier: self.identifier];
      [self.textLabel setText: label];
      [self setSelectionStyle: UITableViewCellSelectionStyleNone];

    } else {
      CFStringRef label = ABAddressBookCopyLocalizedLabel(kABOtherLabel);
      [self.textLabel setText: [(__bridge NSString *)label lowercaseString]];
      CFRelease(label);
      CFStringRef value = ABPersonCopyLocalizedPropertyName(self.abPropertyID);
      [self.detailTextLabel setText: (__bridge NSString *)value];
      CFRelease(value);
      [self.detailTextLabel setTextColor: [UIColor lightGrayColor]];
    }
  } else if (self.abPropertyID == kABPersonSocialProfileProperty) {
    
    if (row < [contact countForProperty: self.abPropertyID]) {
      
      NSArray *identifiers = [contact identifiersForProperty: self.abPropertyID];
      [self setIdentifier: [[identifiers objectAtIndex: row] integerValue]];
      
      NSDictionary *dict = (NSDictionary *)[contact valueForMultiValueProperty: self.abPropertyID forIdentifier: self.identifier];
      
      [self.detailTextLabel setText: [dict objectForKey: (NSString *)kABPersonSocialProfileUsernameKey ]];
      [self.textLabel setText: [dict objectForKey: (NSString *)kABPersonSocialProfileServiceKey]];
      
    } else {
      CFStringRef label = ABAddressBookCopyLocalizedLabel(kABPersonSocialProfileServiceFacebook);
      [self.textLabel setText: (__bridge NSString *)label];
      CFRelease(label);
    }
  } else if (self.abPropertyID == kABPersonInstantMessageProperty) {

    if (row < [contact countForProperty: self.abPropertyID]) {

      NSArray *identifiers = [contact identifiersForProperty: self.abPropertyID];
      [self setIdentifier: [[identifiers objectAtIndex: row] integerValue]];

      NSDictionary *dict = (NSDictionary *)[contact valueForMultiValueProperty: self.abPropertyID forIdentifier: self.identifier];

      [self.detailTextLabel setText: [dict objectForKey: (NSString *)kABPersonInstantMessageUsernameKey]];
      [self.textLabel setText: [dict objectForKey: (NSString *)kABPersonInstantMessageServiceKey]];

    } else {
      CFStringRef label = ABAddressBookCopyLocalizedLabel(kABPersonInstantMessageServiceSkype);
      [self.textLabel setText: (__bridge NSString *)label];
      CFRelease(label);
    }
  }

  // Remove edit mode items that might be hanging around on reused cells
  for (UIView *subView in [self.contentView subviews]) {
    if (subView.tag == editModeItem) {
      [subView removeFromSuperview];
    }
  }

  if (self.abPropertyID == kABPersonNoteProperty) {

    UITextView *textView = [[UITextView alloc] initWithFrame: CGRectMake(83.f, 4.f, (self.parent.editing) ? 180.f : 210.f, 120.f)];
    [self.contentView addSubview: textView];
    [textView setTag: editModeItem];
    [textView setDelegate: self];
    [textView setBackgroundColor: [UIColor clearColor]];
    [textView setFont: [UIFont boldSystemFontOfSize: [UIFont systemFontSize]]];
    NSString *text =  [contact valueForProperty: kABPersonNoteProperty];
    [textView setText: ([text length] > 0) ? text : nil];
    [textView setUserInteractionEnabled: (self.parent.editing) ? YES : NO];

    if (textView.contentSize.height < 120.f)
      [textView setFrame: CGRectMake(textView.frame.origin.x, textView.frame.origin.y,
                                     textView.frame.size.width, textView.contentSize.height)];
  }
  
  if (self.parent.editing == YES) {
   
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(80.f, 0.f, 1.f, self.contentView.bounds.size.height)];
    [separator setBackgroundColor: [UIColor lightGrayColor]];
    [separator setAutoresizingMask: UIViewAutoresizingFlexibleHeight];
    [self.contentView addSubview: separator];
    [separator setTag: editModeItem];

    if (self.abPropertyID != kABPersonNoteProperty &&
        self.abPropertyID != kABPersonBirthdayProperty &&
        self.abPropertyID != kABPersonDateProperty) {
    
      UITextField *textField = [[UITextField alloc] initWithFrame: CGRectMake(83., 12., 175., 19.)];
      [self.contentView addSubview: textField];
      [textField setClearButtonMode: UITextFieldViewModeWhileEditing];
      [textField setFont: [UIFont boldSystemFontOfSize: 15.]];
      [textField setTag: editModeItem];
      [textField setDelegate: self];
      CFStringRef placeholder = ABPersonCopyLocalizedPropertyName(self.abPropertyID);
      [textField setPlaceholder: (__bridge NSString *)placeholder];
      CFRelease(placeholder);

      [textField setText: self.detailTextLabel.text];
      [self.detailTextLabel setText: nil];
      
    } 
  }
}

-(void)layoutSubviews {
  [super layoutSubviews];

  if (self.abPropertyID == kABPersonNoteProperty) {
    [self.textLabel setFrame: CGRectMake(self.textLabel.frame.origin.x, 13.f,
                                         self.textLabel.frame.size.width,
                                         self.textLabel.frame.size.height)];
  }
}

- (void)dealloc {
}

#pragma mark - UITextField delegate

-(void)textFieldDidBeginEditing:(UITextField *)textField {
  
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
  if ([textField isFirstResponder])
    [textField resignFirstResponder];
  
  AKContact *contact = [[AKAddressBook sharedInstance] contactForContactId: self.parent.contactID];
  
  NSString *oldValue = [contact valueForMultiValueProperty: self.abPropertyID forIdentifier: self.identifier];
  if ([textField.text isEqualToString: oldValue])
    return;

  if (self.abPropertyID == kABPersonPhoneProperty ||
        self.abPropertyID == kABPersonEmailProperty) {

    if (self.identifier != NSNotFound) {
      [contact updateValue: textField.text forMultiValueProperty: self.abPropertyID forIdentifier: self.identifier];
    } else {
      [contact createValue: textField.text forMultiValueProperty: self.abPropertyID forIdentifier: self.identifier];
    }
  }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
  if ([textField isFirstResponder])
    [textField resignFirstResponder];
  return YES;
}

#pragma mark - UITextView delegate

-(void)textViewDidBeginEditing:(UITextField *)textField {
  
}

-(void)textViewDidEndEditing:(UITextField *)textField {
  if ([textField isFirstResponder])
    [textField resignFirstResponder];
  
  if (self.abPropertyID == kABPersonNoteProperty) {
    
  }
}

-(BOOL)textViewShouldReturn:(UITextField *)textField {
  if ([textField isFirstResponder])
    [textField resignFirstResponder];
  return YES;
}

#pragma mark - Date Picker

-(void)showDatePicker {

  [self setActionSheet: [[UIActionSheet alloc] initWithTitle: @""
                                                   delegate: nil
                                          cancelButtonTitle: nil
                                     destructiveButtonTitle: nil
                                          otherButtonTitles: nil]];

  UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame: CGRectMake(0.f, 0.f, 320.f, 44.f)];
  [toolbar setBarStyle: UIBarStyleBlackTranslucent];
  [toolbar sizeToFit];
  NSMutableArray *barItems = [[NSMutableArray alloc] init];
  
  UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
                                                                                target: self
                                                                                action: @selector(actionSheetDidPressButton:)];
  [cancelButton setTag: UIBarButtonSystemItemCancel];
  [barItems addObject: cancelButton];

  UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
                                                                             target: self
                                                                             action: nil];
  [barItems addObject: flexSpace];
  
  UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                              target: self
                                                                              action: @selector(actionSheetDidPressButton:)];
  [doneButton setTag: UIBarButtonSystemItemDone];
  [barItems addObject: doneButton];

  
  [toolbar setItems: barItems animated:NO];
  
  [self.actionSheet addSubview: toolbar];
  
  UIDatePicker *dPicker = [[UIDatePicker alloc] initWithFrame: CGRectMake(0.f, 44.f, 0.f, 0.f)];
  [dPicker setDatePickerMode: UIDatePickerModeDate];
  [dPicker addTarget: self
              action: @selector(datePickerDidChangeValue:)
    forControlEvents: UIControlEventValueChanged];

  AKContact *contact = [[AKAddressBook sharedInstance] contactForContactId: self.parent.contactID];
  
  if (self.abPropertyID == kABPersonBirthdayProperty) {
    NSDate *date = [contact valueForProperty: kABPersonBirthdayProperty];
    [dPicker setDate: (date) ? date : [NSDate date]];
  } else if (self.abPropertyID == kABPersonDateProperty) {
    NSDate *date = [contact valueForMultiValueProperty: kABPersonDateProperty forIdentifier: self.identifier];
    [dPicker setDate: (date) ? date : [NSDate date]];
  }

  [self.actionSheet addSubview: dPicker];
  [self.actionSheet showInView: self.parent.navigationController.view];
  [self.actionSheet setBounds:CGRectMake(0.f, 0.f, 320.f, 429.f)];
}

-(void)datePickerDidChangeValue: (id)sender {

  UIDatePicker *dPicker = (UIDatePicker *)sender;

  [self.detailTextLabel setText: [NSDateFormatter localizedStringFromDate: dPicker.date
                                                          dateStyle: NSDateFormatterLongStyle
                                                          timeStyle: NSDateFormatterNoStyle]];
  [self.detailTextLabel setTextColor: [UIColor blackColor]];
  [self.detailTextLabel sizeToFit];
}

-(void)actionSheetDidPressButton: (id) sender {

  UIBarButtonItem *button = (UIBarButtonItem *)sender;
  if (button.tag == UIBarButtonSystemItemCancel) {

    AKContact *contact = [[AKAddressBook sharedInstance] contactForContactId: self.parent.contactID];
    
    if (self.abPropertyID == kABPersonBirthdayProperty) {
      
      NSDate *date = (NSDate *)[contact valueForProperty: kABPersonBirthdayProperty];
      CFStringRef placeholder = ABPersonCopyLocalizedPropertyName(kABPersonDateProperty);
      NSString *dateStr = (date) ? [NSDateFormatter localizedStringFromDate: date
                                                                  dateStyle: NSDateFormatterLongStyle
                                                                  timeStyle: NSDateFormatterNoStyle] : (__bridge NSString *)placeholder;
      [self.detailTextLabel setText: dateStr];
      CFRelease(placeholder);
      UIColor *color = (date) ? [UIColor blackColor] : [UIColor lightGrayColor];
      [self.detailTextLabel setTextColor: color];

    } else if (self.abPropertyID == kABPersonDateProperty) {

      NSDate *date = (NSDate *)[contact valueForMultiValueProperty: kABPersonDateProperty
                                                                 forIdentifier: self.identifier];
      CFStringRef placeholder = ABPersonCopyLocalizedPropertyName(kABPersonDateProperty);
      NSString *dateStr = (date) ? [NSDateFormatter localizedStringFromDate: date
                                                                  dateStyle: NSDateFormatterLongStyle
                                                                  timeStyle: NSDateFormatterNoStyle] : (__bridge NSString *)placeholder;
      [self.detailTextLabel setText: dateStr];
      CFRelease(placeholder);
      UIColor *color = (date) ? [UIColor blackColor] : [UIColor lightGrayColor];
      [self.detailTextLabel setTextColor: color];

    }
  }
  [self.actionSheet dismissWithClickedButtonIndex: 0 animated: YES];
}

#pragma mark - Open URL for social profile

-(void)openURLForSocialProfile {
  
  if (self.abPropertyID == kABPersonSocialProfileProperty) {

    AKContact *contact = [[AKAddressBook sharedInstance] contactForContactId: self.parent.contactID];
    
    NSDictionary *dict = (NSDictionary *)[contact valueForMultiValueProperty: self.abPropertyID forIdentifier: self.identifier];
    if ([dict objectForKey: (NSString *)kABPersonSocialProfileURLKey])
      [[UIApplication sharedApplication] openURL: [NSURL URLWithString: [dict objectForKey: (NSString *)kABPersonSocialProfileURLKey]]];
  }
}

@end
