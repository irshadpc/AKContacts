//
//  AKGroupsViewController.h
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
      for (NSInteger i = indexPath.row; i < [source.groups count]; ++i)
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
