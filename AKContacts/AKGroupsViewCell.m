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

@interface AKGroupsViewCell ()

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) NSIndexPath *indexPath;

@end

@implementation AKGroupsViewCell

@synthesize parent = _parent;
@synthesize textField = _textField;
@synthesize indexPath = _indexPath;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
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

- (void)configureCellAtIndexPath: (NSIndexPath *)indexPath
{
  [self setIndexPath: indexPath];
  [self.textLabel setText: nil];
  [self setTag: NSNotFound];
  [self.textLabel setTextAlignment: NSTextAlignmentLeft];
  [self.textLabel setTextColor: [UIColor blackColor]];
  [self setSelectionStyle: UITableViewCellSelectionStyleNone];

  AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];

  NSInteger sourceCount = [akAddressBook.sources count];
  AKSource *source = [akAddressBook.sources objectAtIndex: indexPath.section];

  NSString *text = nil;
  NSString *placeholder = NSLocalizedString(@"New Group", @"");;
  NSInteger tag = createGroupTag;

  if (indexPath.row < [source.groups count])
  {
    AKGroup *group = [source.groups objectAtIndex: indexPath.row];
    if (group.recordID == deleteGroupTag) {
      for (uint64_t i = indexPath.row; i < [source.groups count]; ++i)
      {
        if (group.recordID != deleteGroupTag)
        {
          group = [source.groups objectAtIndex: i];
          break;
        }
      }
    }
    
    tag = group.recordID;
    text = [group valueForProperty: kABGroupNameProperty];
    if (group.recordID == kGroupAggregate)
    {
      NSMutableArray *groupAggregateName = [[NSMutableArray alloc] initWithObjects: NSLocalizedString(@"All", @""),
                                            NSLocalizedString(@"Contacts", @""), nil];
      if (source.recordID >= 0 && sourceCount > 1) [groupAggregateName insertObject: [source typeName] atIndex: 1];
      text = [groupAggregateName componentsJoinedByString: @" "];
    }
    placeholder = text;
  }

  [self setTag: tag];
  [self setSelectionStyle: UITableViewCellSelectionStyleBlue];

  [self setAccessoryType: UITableViewCellAccessoryDisclosureIndicator];
  [self.textField setEnabled: self.parent.editing];
  [self.textField setTag: tag];
  [self.textField setPlaceholder: placeholder];
  [self.textField setText: text];
}

- (void)layoutSubviews
{
  [super layoutSubviews];

  CGRect frame = CGRectMake(self.contentView.bounds.origin.x + 10.f,
                            self.contentView.bounds.origin.y,
                            self.contentView.bounds.size.width - 20.f,
                            self.contentView.bounds.size.height);
  [self.textField setFrame: frame];
  [self.textField setEnabled: (self.parent.editing && self.tag != kGroupAggregate)];
}

#pragma mark - UITextField delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
  [self.parent setFirstResponder: textField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
  [self.parent setFirstResponder: nil];

  if ([textField isFirstResponder])
    [textField resignFirstResponder];

  if (textField.tag != createGroupTag && textField.text.length == 0)
  {
    [textField setText: textField.placeholder];
  }
  else if (textField.text.length > 0)
  {
    AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];
    AKSource *source = [akAddressBook.sources objectAtIndex: self.indexPath.section];

    if (textField.tag == createGroupTag)
    {
      AKGroup *group = [source groupForGroupId: createGroupTag];
      if (group == nil)
      {
        group = [[AKGroup alloc] initWithABRecordID: createGroupTag];
        [source.groups addObject: group];
      }
      [group setProvisoryName: textField.text];
    }
    else
    {
      AKGroup *group = [source.groups objectAtIndex: self.indexPath.row];
      [group setProvisoryName: textField.text];
    }
  }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  if ([textField isFirstResponder])
    [textField resignFirstResponder];
  return YES;
}

@end
