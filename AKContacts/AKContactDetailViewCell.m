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

@interface AKContactDetailViewCell ()

@property (nonatomic, assign) ABPropertyID abPropertyID;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIView *separator;

- (UIView *)datePickerInputViewWithDate: (NSDate *)date;
- (UIView *)datePickerInputAccessoryView;
- (void)datePickerDidChangeValue: (id)sender;
- (void)datePickerDidEndEditing: (id)sender;

@end

@implementation AKContactDetailViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self)
  {
    _textField = [[UITextField alloc] initWithFrame: CGRectZero];
    [_textField setContentVerticalAlignment: UIControlContentVerticalAlignmentCenter];
    [_textField setClearButtonMode: UITextFieldViewModeWhileEditing];
    [_textField setDelegate: self];
    [_textField setFont: [UIFont boldSystemFontOfSize: 15.f]];

    _textView = [[UITextView alloc] initWithFrame: CGRectZero];
    [_textView setDelegate: self];
    [_textView setBackgroundColor: [UIColor clearColor]];
    [_textView setFont: [UIFont boldSystemFontOfSize: [UIFont systemFontSize]]];

    _separator = [[UIView alloc] initWithFrame: CGRectZero];
    [_separator setBackgroundColor: [UIColor lightGrayColor]];
    [_separator setAutoresizingMask: UIViewAutoresizingFlexibleHeight];
    [self.contentView addSubview: _separator];
  }
  return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{

  [super setSelected:selected animated:animated];

  // Configure the view for the selected state
}

- (void)configureCellForProperty:(ABPropertyID)property atRow:(NSInteger)row
{
  [self setAbPropertyID: property];
  [self setTag: NSNotFound];
  [self.textLabel setText: nil];
  [self.detailTextLabel setText: nil];
  [self setSelectionStyle: UITableViewCellSelectionStyleBlue];
  [self.textField setKeyboardType: UIKeyboardTypeDefault];
  [self.textField setInputView: nil];
  [self.textField setInputAccessoryView: nil];
  
  AKContact *contact = self.parent.contact;

  NSString *text = nil;
  NSString *placeholder = nil;
  NSString *label = nil;

  [self.textField removeFromSuperview];
  [self.textView removeFromSuperview];
  [self.contentView addSubview: (self.abPropertyID == kABPersonNoteProperty) ? self.textView : self.textField];

  if (self.abPropertyID == kABPersonPhoneProperty ||
      self.abPropertyID == kABPersonEmailProperty ||
      self.abPropertyID == kABPersonURLProperty)
  {
    NSArray *identifiers = [contact identifiersForProperty: self.abPropertyID];
    [self setTag: (row < [contact countForProperty: self.abPropertyID]) ? [[identifiers objectAtIndex: row] integerValue] : NSNotFound];
      
    text = [contact valueForMultiValueProperty: self.abPropertyID andIdentifier: self.tag];
    label = [contact localizedLabelForMultiValueProperty: self.abPropertyID andIdentifier: self.tag];

    [self.textField setKeyboardType: (self.abPropertyID == kABPersonPhoneProperty) ? UIKeyboardTypePhonePad : UIKeyboardTypeDefault];
  }
  else if (self.abPropertyID == kABPersonNoteProperty)
  {
    label = [AKContact localizedNameForProperty: self.abPropertyID];

    text =  [contact valueForProperty: kABPersonNoteProperty];
    [self.textView setText: text];

    [self setSelectionStyle: UITableViewCellSelectionStyleNone];
  }
  else if (self.abPropertyID == kABPersonBirthdayProperty)
  {
    NSDate *date = (NSDate *)[contact valueForProperty: kABPersonBirthdayProperty];
    text = (date) ? [NSDateFormatter localizedStringFromDate: date
                                                   dateStyle: NSDateFormatterLongStyle
                                                   timeStyle: NSDateFormatterNoStyle] : nil;
    label = [AKContact localizedNameForProperty: self.abPropertyID];

    [self.textField setInputView: [self datePickerInputViewWithDate: (date) ? date : [NSDate date]]];
    [self.textField setInputAccessoryView: [self datePickerInputAccessoryView]];

    [self setSelectionStyle: UITableViewCellSelectionStyleNone];
  }
  else if (self.abPropertyID == kABPersonDateProperty)
  {
    NSDate *date = nil;
    
    NSArray *identifiers = [contact identifiersForProperty: self.abPropertyID];
    [self setTag: (row < [contact countForProperty: kABPersonDateProperty]) ? [[identifiers objectAtIndex: row] integerValue] : NSNotFound];

    date = (NSDate *)[contact valueForMultiValueProperty: kABPersonDateProperty andIdentifier: self.tag];
    text = (date) ? [NSDateFormatter localizedStringFromDate: date
                                                   dateStyle: NSDateFormatterLongStyle
                                                   timeStyle: NSDateFormatterNoStyle] : nil;
    label = [contact localizedLabelForMultiValueProperty: kABPersonDateProperty andIdentifier: self.tag];

    [self setSelectionStyle: UITableViewCellSelectionStyleNone];

    [self.textField setInputView: [self datePickerInputViewWithDate: (date) ? date : [NSDate date]]];
    [self.textField setInputAccessoryView: [self datePickerInputAccessoryView]];
  }
  else if (self.abPropertyID == kABPersonSocialProfileProperty)
  {
    NSArray *identifiers = [contact identifiersForProperty: self.abPropertyID];
    [self setTag: (row < [contact countForProperty: self.abPropertyID]) ? [[identifiers objectAtIndex: row] integerValue] : NSNotFound];
      
    NSDictionary *dict = (NSDictionary *)[contact valueForMultiValueProperty: self.abPropertyID andIdentifier: self.tag];
      
    text = [dict objectForKey: (NSString *)kABPersonSocialProfileUsernameKey];
    label = [contact localizedLabelForMultiValueProperty: self.abPropertyID andIdentifier: self.tag];
  }
  else if (self.abPropertyID == kABPersonInstantMessageProperty)
  {
    NSArray *identifiers = [contact identifiersForProperty: self.abPropertyID];
    [self setTag: (row < [contact countForProperty: self.abPropertyID]) ? [[identifiers objectAtIndex: row] integerValue] : NSNotFound];

    NSDictionary *dict = (NSDictionary *)[contact valueForMultiValueProperty: self.abPropertyID andIdentifier: self.tag];

    text = [dict objectForKey: (NSString *)kABPersonInstantMessageUsernameKey];
    label = [contact localizedLabelForMultiValueProperty: self.abPropertyID andIdentifier: self.tag];
  }

  placeholder = (text) ? text : [AKContact localizedNameForProperty: self.abPropertyID];

  [self.textField setPlaceholder: placeholder];
  [self.textField setText: text];
  if ([label compare: @"iPhone"] != NSOrderedSame) label = [label lowercaseString];
  [self.textLabel setText: label];
}

- (void)layoutSubviews
{
  [super layoutSubviews];

  CGRect frame = CGRectMake(self.contentView.bounds.origin.x + 85.f,
                            self.contentView.bounds.origin.y,
                            self.contentView.bounds.size.width - 85.f,
                            self.contentView.bounds.size.height);
  [self.textField setFrame: frame];
  [self.textField setUserInteractionEnabled: self.parent.editing];

  frame.size.height -= 10.f;
  frame.origin.x -= 7.f;
  frame.size.width += 7.f;
  [self.textView setFrame: frame];
  [self.textView setEditable: self.parent.editing];

  [self.separator setFrame: CGRectMake(80.f, 0.f, 1.f, self.contentView.bounds.size.height)];
  [self.separator setHidden: !self.parent.editing];

  if (self.abPropertyID == kABPersonNoteProperty)
  {
    [self.textLabel setFrame: CGRectMake(self.textLabel.frame.origin.x, 13.f,
                                         self.textLabel.frame.size.width,
                                         self.textLabel.frame.size.height)];
  }
}

- (void)dealloc
{
}

#pragma mark - UITextField delegate

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
  [self.parent setFirstResponder: textField];
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
  if ([textField isFirstResponder])
    [textField resignFirstResponder];

  [self.parent setFirstResponder: nil];

  AKContact *contact = self.parent.contact;
  
  NSString *oldValue = [contact valueForMultiValueProperty: self.abPropertyID andIdentifier: self.tag];
  if ([textField.text isEqualToString: oldValue] || [textField.text length] == 0)
    return;

  if (self.abPropertyID == kABPersonPhoneProperty ||
        self.abPropertyID == kABPersonEmailProperty)
  {
    NSInteger identifier = self.tag;
    NSString *value = ([textField.text length] > 0) ? textField.text : nil;
    NSString *label = [contact labelForMultiValueProperty: self.abPropertyID andIdentifier: identifier];
    [contact setValue: value andLabel: label forMultiValueProperty: self.abPropertyID andIdentifier: &identifier];
    if (identifier != self.tag)
    {
      [self setTag: identifier];
    }
  }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  if ([textField isFirstResponder])
    [textField resignFirstResponder];
  return YES;
}

#pragma mark - UITextView delegate

- (void)textViewDidBeginEditing:(UITextField *)textView
{
  [self.parent setFirstResponder: textView];
}

- (void)textViewDidEndEditing:(UITextField *)textView
{
  if ([textView isFirstResponder])
    [textView resignFirstResponder];

  [self.parent setFirstResponder: nil];

  if (self.abPropertyID == kABPersonNoteProperty)
  {
    AKContact *contact = self.parent.contact;

    NSString *oldValue = [contact valueForProperty: kABPersonNoteProperty];
    if ([textView.text isEqualToString: oldValue] || [textView.text length] == 0)
      return;
    
    NSString *value = ([textView.text length] > 0) ? textView.text : nil;
    [contact setValue: value forProperty: kABPersonNoteProperty];
  }
}

- (BOOL)textViewShouldReturn:(UITextField *)textField
{
  if ([textField isFirstResponder])
    [textField resignFirstResponder];
  return YES;
}

#pragma mark - Date Picker

- (UIView *)datePickerInputViewWithDate: (NSDate *)date
{
  UIDatePicker *picker = [[UIDatePicker alloc] initWithFrame: CGRectZero];
  [picker setDatePickerMode: UIDatePickerModeDate];
  [picker addTarget: self
             action: @selector(datePickerDidChangeValue:)
   forControlEvents: UIControlEventValueChanged];

  [picker setDate: date];
  return picker;
}

- (UIView *)datePickerInputAccessoryView
{
  UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame: CGRectMake(0.f, 0.f, 320.f, 44.f)];
  [toolbar setBarStyle: UIBarStyleBlackTranslucent];
  [toolbar sizeToFit];
  NSMutableArray *barItems = [[NSMutableArray alloc] init];
  
  UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
                                                                                target: self
                                                                                action: @selector(datePickerDidEndEditing:)];
  [cancelButton setTag: UIBarButtonSystemItemCancel];
  [barItems addObject: cancelButton];
  
  UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
                                                                             target: self
                                                                             action: nil];
  [barItems addObject: flexSpace];
  
  UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                              target: self
                                                                              action: @selector(datePickerDidEndEditing:)];
  [doneButton setTag: UIBarButtonSystemItemDone];
  [barItems addObject: doneButton];

  [toolbar setItems: barItems animated:NO];
  return toolbar;
}

- (void)datePickerDidChangeValue: (id)sender
{
  UIDatePicker *picker = (UIDatePicker *)sender;
  [self.textField setText: [NSDateFormatter localizedStringFromDate: picker.date
                                                          dateStyle: NSDateFormatterLongStyle
                                                          timeStyle: NSDateFormatterNoStyle]];
}

- (void)datePickerDidEndEditing: (id)sender
{
  if ([self.textField isFirstResponder])
    [self.textField resignFirstResponder];
  
  AKContact *contact = self.parent.contact;
  
  UIBarButtonItem *button = (UIBarButtonItem *)sender;
  if (button.tag == UIBarButtonSystemItemDone)
  {
    UIDatePicker *datePicker = (UIDatePicker *)self.textField.inputView;

    NSString *text = [NSDateFormatter localizedStringFromDate: datePicker.date
                                                    dateStyle: NSDateFormatterLongStyle
                                                    timeStyle: NSDateFormatterNoStyle];
    [self.textField setText: text];
    
    if (self.abPropertyID == kABPersonBirthdayProperty)
    {
      [contact setValue: datePicker.date forProperty: self.abPropertyID];
    }
    else if (self.abPropertyID == kABPersonDateProperty)
    {
      NSInteger identifier = self.tag;
      [contact setValue: datePicker.date andLabel: nil forMultiValueProperty: kABPersonDateProperty andIdentifier: &identifier];
    }
  }
  else if (button.tag == UIBarButtonSystemItemCancel)
  {
    if (self.abPropertyID == kABPersonBirthdayProperty)
    {
      NSDate *date = (NSDate *)[contact valueForProperty: kABPersonBirthdayProperty];
      NSString *text = [NSDateFormatter localizedStringFromDate: date
                                                    dateStyle: NSDateFormatterLongStyle
                                                    timeStyle: NSDateFormatterNoStyle];
      [self.textField setText: text];
    }
    else if (self.abPropertyID == kABPersonDateProperty)
    {
      NSDate *date = (NSDate *)[contact valueForMultiValueProperty: kABPersonDateProperty
                                                     andIdentifier: self.tag];
      NSString *text = (date) ? [NSDateFormatter localizedStringFromDate: date
                                                               dateStyle: NSDateFormatterLongStyle
                                                               timeStyle: NSDateFormatterNoStyle] : nil;
      [self.detailTextLabel setText: text];
    }
  }
}

@end
