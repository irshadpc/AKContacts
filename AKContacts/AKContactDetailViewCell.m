//
//  AKContactDetailViewCell.m
//
//  Copyright (c) 2013 Adam Kornafeld All rights reserved.
//

#import "AKContactDetailViewCell.h"
#import "AKContact.h"
#import "AKContactViewController.h"

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
  [self setSelectionStyle: UITableViewCellSelectionStyleNone];

  if (self.abPropertyID == kABPersonPhoneProperty ||
      self.abPropertyID == kABPersonEmailProperty) {

    if (row < [parent.contact countForProperty: self.abPropertyID]) {

      NSArray *identifiers = [parent.contact identifiersForProperty: self.abPropertyID];
      [self setIdentifier: [[identifiers objectAtIndex: row] integerValue]];
      
      [self.detailTextLabel setText: [parent.contact valueForMultiValueProperty: self.abPropertyID forIdentifier: self.identifier]];
      [self.textLabel setText: [parent.contact labelForMultiValueProperty: self.abPropertyID forIdentifier: self.identifier]];
  
    } else {
      [self.textLabel setText: [(__bridge NSString *)ABAddressBookCopyLocalizedLabel(kABOtherLabel) lowercaseString]];
    }
    
  } else if (self.abPropertyID == kABPersonNoteProperty) {

    [self.textLabel setText: [(__bridge NSString *)(ABPersonCopyLocalizedPropertyName(self.abPropertyID)) lowercaseString]];

  } else if (self.abPropertyID == kABPersonBirthdayProperty) {

    NSDate *date = (NSDate *)[self.parent.contact valueForProperty: kABPersonBirthdayProperty];
    [self.detailTextLabel setText: [NSDateFormatter localizedStringFromDate: date
                                                                  dateStyle: NSDateFormatterLongStyle
                                                                  timeStyle: NSDateFormatterNoStyle]];
    [self.textLabel setText: [(__bridge NSString *)(ABPersonCopyLocalizedPropertyName(self.abPropertyID)) lowercaseString]];
    [self setSelectionStyle: UITableViewCellSelectionStyleNone];

  } else if (self.abPropertyID == kABPersonDateProperty) {

    if (row < [parent.contact countForProperty: kABPersonDateProperty]) {
      
      NSArray *identifiers = [parent.contact identifiersForProperty: self.abPropertyID];
      [self setIdentifier: [[identifiers objectAtIndex: row] integerValue]];

      NSDate *date = (NSDate *)[self.parent.contact valueForMultiValueProperty: kABPersonDateProperty forIdentifier: self.identifier];
      [self.detailTextLabel setText: [NSDateFormatter localizedStringFromDate: date
                                                                    dateStyle: NSDateFormatterLongStyle
                                                                    timeStyle: NSDateFormatterNoStyle]];
      NSString *label = [self.parent.contact labelForMultiValueProperty: kABPersonDateProperty forIdentifier: self.identifier];
      [self.textLabel setText: label];
      [self setSelectionStyle: UITableViewCellSelectionStyleNone];

    } else {
      [self.textLabel setText: [(__bridge NSString *)ABAddressBookCopyLocalizedLabel(kABOtherLabel) lowercaseString]];
    }
  } else if (self.abPropertyID == kABPersonSocialProfileProperty) {
    
    if (row < [parent.contact countForProperty: self.abPropertyID]) {
      
      NSArray *identifiers = [parent.contact identifiersForProperty: self.abPropertyID];
      [self setIdentifier: [[identifiers objectAtIndex: row] integerValue]];
      
      NSDictionary *dict = (NSDictionary *)[parent.contact valueForMultiValueProperty: self.abPropertyID forIdentifier: self.identifier];
      
      [self.detailTextLabel setText: [dict objectForKey: (NSString *)kABPersonSocialProfileUsernameKey ]];
      [self.textLabel setText: [dict objectForKey: (NSString *)kABPersonSocialProfileServiceKey]];
      
    } else {
      [self.textLabel setText: (__bridge NSString *)ABAddressBookCopyLocalizedLabel(kABPersonSocialProfileServiceFacebook)];
    }
  } else if (self.abPropertyID == kABPersonInstantMessageProperty) {

    if (row < [parent.contact countForProperty: self.abPropertyID]) {

      NSArray *identifiers = [parent.contact identifiersForProperty: self.abPropertyID];
      [self setIdentifier: [[identifiers objectAtIndex: row] integerValue]];

      NSDictionary *dict = (NSDictionary *)[parent.contact valueForMultiValueProperty: self.abPropertyID forIdentifier: self.identifier];

      [self.detailTextLabel setText: [dict objectForKey: (NSString *)kABPersonInstantMessageUsernameKey]];
      [self.textLabel setText: [dict objectForKey: (NSString *)kABPersonInstantMessageServiceKey]];

    } else {
      [self.textLabel setText: (__bridge NSString *)ABAddressBookCopyLocalizedLabel(kABPersonInstantMessageServiceSkype)];
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
    NSString *text =  [parent.contact valueForProperty: kABPersonNoteProperty];
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
      [textField setPlaceholder: (__bridge NSString *)(ABPersonCopyLocalizedPropertyName(self.abPropertyID))];

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
  
  NSString *oldValue = [parent.contact valueForMultiValueProperty: self.abPropertyID forIdentifier: self.identifier];
  if ([textField.text isEqualToString: oldValue])
    return;

  if (self.abPropertyID == kABPersonPhoneProperty ||
        self.abPropertyID == kABPersonEmailProperty) {

    if (self.identifier != NSNotFound) {
      [self.parent.contact updateValue: textField.text forMultiValueProperty: self.abPropertyID forIdentifier: self.identifier];
    } else {
      [self.parent.contact createValue: textField.text forMultiValueProperty: self.abPropertyID forIdentifier: self.identifier];
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

  if (self.abPropertyID == kABPersonBirthdayProperty) {
    [dPicker setDate: [self.parent.contact valueForProperty: kABPersonBirthdayProperty]];
  } else if (self.abPropertyID == kABPersonDateProperty) {
    [dPicker setDate: [self.parent.contact valueForMultiValueProperty: kABPersonDateProperty
                                                        forIdentifier: self.identifier]];
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
}

-(void)actionSheetDidPressButton: (id) sender {

  UIBarButtonItem *button = (UIBarButtonItem *)sender;
  if (button.tag == UIBarButtonSystemItemCancel) {

    if (self.abPropertyID == kABPersonBirthdayProperty) {

      NSDate *date = (NSDate *)[self.parent.contact valueForProperty: kABPersonBirthdayProperty];
      [self.detailTextLabel setText: [NSDateFormatter localizedStringFromDate: date
                                                                    dateStyle: NSDateFormatterLongStyle
                                                                    timeStyle: NSDateFormatterNoStyle]];

    } else if (self.abPropertyID == kABPersonDateProperty) {

      NSDate *date = (NSDate *)[self.parent.contact valueForMultiValueProperty: kABPersonDateProperty
                                                                 forIdentifier: self.identifier];
      [self.detailTextLabel setText: [NSDateFormatter localizedStringFromDate: date
                                                                    dateStyle: NSDateFormatterLongStyle
                                                                    timeStyle: NSDateFormatterNoStyle]];

    }
  }
  [self.actionSheet dismissWithClickedButtonIndex: 0 animated: YES];
}

#pragma mark - Open URL for social profile

-(void)openURLForSocialProfile {
  
  if (self.abPropertyID == kABPersonSocialProfileProperty) {

    NSDictionary *dict = (NSDictionary *)[parent.contact valueForMultiValueProperty: self.abPropertyID forIdentifier: self.identifier];
    if ([dict objectForKey: (NSString *)kABPersonSocialProfileURLKey])
      [[UIApplication sharedApplication] openURL: [NSURL URLWithString: [dict objectForKey: (NSString *)kABPersonSocialProfileURLKey]]];
  }
}

@end
