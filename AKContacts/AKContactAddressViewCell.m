//
//  AKContactAddressViewCell.m
//
//  Copyright (c) 2013 Adam Kornafeld All rights reserved.
//

#import "AKContactAddressViewCell.h"
#import "AKContact.h"
#import "AKContactViewController.h"

typedef NS_ENUM(NSInteger, FieldTags) {
  kAddressStreet,
  kAddressCity,
  kAddressState,
  kAddressZIP,
  kAddressCountry
};

static const int editModeItem = 101;

@interface AKContactAddressViewCell ()

@property (nonatomic, assign) NSInteger identifier;

@end

@implementation AKContactAddressViewCell

@synthesize identifier = _identifier;

@synthesize parent = _parent;


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

-(void)configureCellAtRow:(NSInteger)row {

  [self setIdentifier: NSNotFound];
  [self.textLabel setText: nil];
  [self.detailTextLabel setText: nil];

  // Remove edit mode items that might be hanging around on reused cells
  for (UIView *subView in [self.contentView subviews]) {
    if (subView.tag == editModeItem || subView.tag == kAddressStreet ||
        subView.tag == kAddressCity || subView.tag == kAddressState ||
        subView.tag == kAddressCountry || subView.tag == kAddressZIP) {
      [subView removeFromSuperview];
    }
  }

  if (row < [self.parent.contact countForProperty: kABPersonAddressProperty]) {
    
    NSArray *addressIdentifiers = [self.parent.contact identifiersForProperty: kABPersonAddressProperty];
    [self setIdentifier: [[addressIdentifiers objectAtIndex: row] integerValue]];
    
    NSString *aSubStr = @"";
    NSMutableArray *aArr = [[NSMutableArray alloc] init];
    NSMutableArray *aSubArr = [[NSMutableArray alloc] init];
    NSString *street = [self.parent.contact valueForMultiDictKey: (NSString *)kABPersonAddressStreetKey forIdentifier: self.identifier];
    NSString *city = [self.parent.contact valueForMultiDictKey: (NSString *)kABPersonAddressCityKey forIdentifier: self.identifier];
    NSString *state = [self.parent.contact valueForMultiDictKey: (NSString *)kABPersonAddressStateKey forIdentifier: self.identifier];
    NSString *ZIP = [self.parent.contact valueForMultiDictKey: (NSString *)kABPersonAddressZIPKey forIdentifier: self.identifier];
    NSString *country = [self.parent.contact valueForMultiDictKey: (NSString *)kABPersonAddressCountryKey forIdentifier: self.identifier];
    
    if ([city length] > 0) [aSubArr addObject: city];
    if ([state length] > 0) [aSubArr addObject: state];
    if ([ZIP length] > 0) [aSubArr addObject: ZIP];
    if ([aSubArr count] > 0) aSubStr = [aSubArr componentsJoinedByString: @" "];
    
    if ([street length] > 0) [aArr addObject: street];
    if ([aSubStr length] > 0) [aArr addObject: aSubStr];
    if ([country length] > 0) [aArr addObject: country];
    
    [self.detailTextLabel setText: [aArr componentsJoinedByString: @"\n"]];
    [self.detailTextLabel setLineBreakMode: NSLineBreakByWordWrapping];
    [self.detailTextLabel setNumberOfLines: [aArr count]];
    
    [self.detailTextLabel setFont: [UIFont boldSystemFontOfSize: [UIFont systemFontSize]]];
    
    [self.textLabel setText: [self.parent.contact labelForMultiValueProperty: kABPersonAddressProperty forIdentifier: self.identifier]];
  }

  if (self.parent.editing == YES) {

    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(80.f, 0.f, 1.f, self.contentView.bounds.size.height)];
    [separator setBackgroundColor: [UIColor lightGrayColor]];
    [separator setAutoresizingMask: UIViewAutoresizingFlexibleHeight];
    [separator setTag: editModeItem];
    [self.contentView addSubview: separator];

    separator = [[UIView alloc] initWithFrame:CGRectMake(80.f, 40.f, self.contentView.bounds.size.width - 80.f, 1.f)];
    [separator setBackgroundColor: [UIColor lightGrayColor]];
    [separator setAutoresizingMask: UIViewAutoresizingFlexibleWidth];
    [separator setTag: editModeItem];
    [self.contentView addSubview: separator];

    separator = [[UIView alloc] initWithFrame:CGRectMake(80.f, 80.f, self.contentView.bounds.size.width - 80.f, 1.f)];
    [separator setBackgroundColor: [UIColor lightGrayColor]];
    [separator setAutoresizingMask: UIViewAutoresizingFlexibleWidth];
    [separator setTag: editModeItem];
    [self.contentView addSubview: separator];
    
    separator = [[UIView alloc] initWithFrame:CGRectMake(175.f, 40.f, 1.f, 80.f)];
    [separator setBackgroundColor: [UIColor lightGrayColor]];
    [separator setAutoresizingMask: UIViewAutoresizingNone];
    [separator setTag: editModeItem];
    [self.contentView addSubview: separator];
    
    UITextField *textField = [[UITextField alloc] initWithFrame: CGRectMake(83.f, 11.f, 175.f, 19.f)];
    [self.contentView addSubview: textField];
    [textField setClearButtonMode: UITextFieldViewModeWhileEditing];
    [textField setKeyboardType: UIKeyboardTypeAlphabet];
    [textField setFont: [UIFont boldSystemFontOfSize: 15.]];
    [textField setDelegate: self];
    [textField setTag: kAddressStreet];
    [textField setPlaceholder: (__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABPersonAddressStreetKey))];
    [textField setText: (self.identifier != NSNotFound) ? [self.parent.contact valueForMultiDictKey: (NSString *)kABPersonAddressStreetKey forIdentifier: self.identifier] : nil];
    
    textField = [[UITextField alloc] initWithFrame: CGRectMake(83.f, 51.f, 90.f, 19.f)];
    [self.contentView addSubview: textField];
    [textField setClearButtonMode: UITextFieldViewModeWhileEditing];
    [textField setKeyboardType: UIKeyboardTypeAlphabet];
    [textField setFont: [UIFont boldSystemFontOfSize: 15.]];
    [textField setDelegate: self];
    [textField setTag: kAddressCity];
    [textField setPlaceholder: (__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABPersonAddressCityKey))];
    [textField setText: (self.identifier != NSNotFound) ? [self.parent.contact valueForMultiDictKey: (NSString *)kABPersonAddressCityKey forIdentifier: self.identifier] : nil];
    
    textField = [[UITextField alloc] initWithFrame: CGRectMake(180.f, 51.f, 85.f, 19.f)];
    [self.contentView addSubview: textField];
    [textField setClearButtonMode: UITextFieldViewModeWhileEditing];
    [textField setFont: [UIFont boldSystemFontOfSize: 15.]];
    [textField setDelegate: self];
    [textField setTag: kAddressState];
    [textField setPlaceholder: (__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABPersonAddressStateKey))];
    
    [textField setText: (self.identifier != NSNotFound) ? [self.parent.contact valueForMultiDictKey: (NSString *)kABPersonAddressStateKey forIdentifier: self.identifier] : nil];

    textField = [[UITextField alloc] initWithFrame: CGRectMake(83.f, 91.f, 90.f, 19.f)];
    [self.contentView addSubview: textField];
    [textField setClearButtonMode: UITextFieldViewModeWhileEditing];
    [textField setKeyboardType: UIKeyboardTypeNumbersAndPunctuation];
    [textField setFont: [UIFont boldSystemFontOfSize: 15.]];
    [textField setDelegate: self];
    [textField setTag: kAddressZIP];
    [textField setPlaceholder: (__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABPersonAddressZIPKey))];
    [textField setText: (self.identifier != NSNotFound) ? [self.parent.contact valueForMultiDictKey: (NSString *)kABPersonAddressZIPKey forIdentifier: self.identifier] : nil];

    textField = [[UITextField alloc] initWithFrame: CGRectMake(180.f, 91.f, 85.f, 19.f)];
    [self.contentView addSubview: textField];
    [textField setClearButtonMode: UITextFieldViewModeWhileEditing];
    [textField setKeyboardType: UIKeyboardTypeAlphabet];
    [textField setFont: [UIFont boldSystemFontOfSize: 15.]];
    [textField setDelegate: self];
    [textField setTag: kAddressCountry];
    [textField setPlaceholder: (__bridge NSString *)(ABAddressBookCopyLocalizedLabel(kABPersonAddressCountryKey))];
    [textField setText: (self.identifier != NSNotFound) ? [self.parent.contact valueForMultiDictKey: (NSString *)kABPersonAddressCountryKey forIdentifier: self.identifier] : nil];

    [self.detailTextLabel setText: nil];

  }

}

-(void)layoutSubviews {
  [super layoutSubviews];

  [self.textLabel setFrame: CGRectMake(self.textLabel.frame.origin.x, 13.f,
                                       self.textLabel.frame.size.width,
                                       self.textLabel.frame.size.height)];

}

- (void)dealloc {
}

#pragma masrk - UITextField delegate

-(void)textFieldDidBeginEditing:(UITextField *)textField {
  
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
  if ([textField isFirstResponder])
    [textField resignFirstResponder];
  
  // Update ABContact here
  if (textField.tag == kAddressStreet) {
    
  } else if (textField.tag == kAddressCity) {
    
  } else if (textField.tag == kAddressState) {
    
  } else if (textField.tag == kAddressZIP) {
    
  } else if (textField.tag == kAddressCountry) {
    
  }

}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
  if ([textField isFirstResponder])
    [textField resignFirstResponder];
  return YES;
}

@end
