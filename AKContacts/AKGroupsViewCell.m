//
//  AKGroupsViewCell.m
//  AKContacts
//
//  Created by Adam Kornafeld on 3/19/13.
//  Copyright (c) 2013 Adam Kornafeld. All rights reserved.
//

#import "AKGroupsViewCell.h"
#import "AKAddressBook.h"
#import "AKGroup.h"
#import "AKGroupsViewController.h"
#import "AKSource.h"

static const int newGroupTag = 2^10;

@interface AKGroupsViewCell ()

@property (nonatomic, strong) UITextField *textField;

@end

@implementation AKGroupsViewCell

@synthesize parent = _parent;
@synthesize textField = _textField;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
 
      UITextField *textField = [[UITextField alloc] initWithFrame: CGRectZero];
      [textField setContentVerticalAlignment: UIControlContentVerticalAlignmentCenter];
      [textField setClearButtonMode: UITextFieldViewModeWhileEditing];
      [textField setDelegate: self];
      [textField setFont: [UIFont boldSystemFontOfSize: 17.f]];
      [self setTextField: textField];
      [self.contentView addSubview: textField];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)configureCellAtIndexPath: (NSIndexPath *)indexPath {

  [self.textLabel setText: nil];
  [self setTag: NSNotFound];
  [self.textLabel setTextAlignment: NSTextAlignmentLeft];
  [self.textLabel setTextColor: [UIColor blackColor]];
  [self setSelectionStyle: UITableViewCellSelectionStyleNone];

  AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];

  NSInteger sourceCount = [akAddressBook.sources count];
  AKSource *source = [akAddressBook.sources objectAtIndex: indexPath.section];

  NSString *text = nil;
  NSString *placeholder = nil;
  NSInteger tag = newGroupTag;

  if (indexPath.row < [source.groups count]) {

    AKGroup *group = [source.groups objectAtIndex: indexPath.row];

    tag = group.recordID;
    text = [group valueForProperty: kABGroupNameProperty];
    if (group.recordID == kGroupAggregate) {
      NSMutableArray *groupAggregateName = [[NSMutableArray alloc] initWithObjects: NSLocalizedString(@"All", @""),
                                            NSLocalizedString(@"Contacts", @""), nil];
      if (source.recordID >= 0 && sourceCount > 1) [groupAggregateName insertObject: [source typeName] atIndex: 1];
      text = [groupAggregateName componentsJoinedByString: @" "];
    }
    placeholder = text;
  } else {
    placeholder = NSLocalizedString(@"New Group", @"");
  }

  [self setTag: tag];
  [self setSelectionStyle: UITableViewCellSelectionStyleBlue];

  [self setAccessoryType: UITableViewCellAccessoryDisclosureIndicator];
  [self.textField setEnabled: self.parent.editing];
  [self.textField setTag: tag];
  [self.textField setPlaceholder: placeholder];
  [self.textField setText: text];
}

-(void)layoutSubviews {
  [super layoutSubviews];

  CGRect frame = CGRectMake(self.contentView.bounds.origin.x + 10.f,
                            self.contentView.bounds.origin.y,
                            self.contentView.bounds.size.width - 20.f,
                            self.contentView.bounds.size.height);
  [self.textField setFrame: frame];
  [self.textField setEnabled: (self.parent.editing && self.tag != kGroupAggregate)];
}

#pragma mark - UITextField delegate

-(void)textFieldDidBeginEditing:(UITextField *)textField {
  
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
  if ([textField isFirstResponder])
    [textField resignFirstResponder];
  
  if (textField.tag != newGroupTag && textField.text.length == 0)
    [textField setText: textField.placeholder];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
  if ([textField isFirstResponder])
    [textField resignFirstResponder];
  return YES;
}

@end
