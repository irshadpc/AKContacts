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

#import "AKLabelViewCell.h"
#import "AKLabel.h"
#import "AKLabelViewController.h"

@interface AKLabelViewCell ()

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) NSIndexPath *indexPath;

@end

@implementation AKLabelViewCell

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

  NSMutableArray *labels = [self.parent.labels objectAtIndex: indexPath.section];

  if (indexPath.row == [labels count])
  {
    NSString *placeholder = NSLocalizedString(@"New Label", @"");;
    [self.textField setPlaceholder: placeholder];
    [self.textField setText: nil];
    [self.textField setTag: createLabelTag];
  }
  else
  {
    AKLabel *akLabel = [labels objectAtIndex: indexPath.row];
    if (akLabel.status == kLabelStatusDeleting) {
      for (NSInteger i = indexPath.row; i < [labels count]; ++i)
      {
        if (akLabel.status != kLabelStatusDeleting)
        {
          akLabel = [labels objectAtIndex: i];
          break;
        }
      }
    }

    [self setAccessoryType: ([akLabel selected]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone];
    [self.textField setText: akLabel.localizedLabel];
    [self.textField setPlaceholder: akLabel.localizedLabel];
  }
}

- (void)layoutSubviews
{
  [super layoutSubviews];

  CGRect frame = CGRectMake(self.contentView.bounds.origin.x + 10.f,
                            self.contentView.bounds.origin.y,
                            self.contentView.bounds.size.width - 20.f,
                            self.contentView.bounds.size.height);
  [self.textField setFrame: frame];
  [self.textField setEnabled: (self.parent.editing && self.indexPath.section == kCustomSection)];
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

  if (textField.tag != createLabelTag && textField.text.length == 0)
  {
    [textField setText: textField.placeholder];
  }
  else if (textField.text.length > 0)
  {
    NSMutableArray *labels = [self.parent.labels objectAtIndex: kCustomSection];

    AKLabel *label = [[AKLabel alloc] initWithLabel: textField.text andIsStandard: NO];
    
    if (self.indexPath.row == [labels count])
    { // Create
      [label setStatus: kLabelStatusCreating];
      [labels addObject: label];
    }
    else
    { // Rename
      [labels replaceObjectAtIndex: self.indexPath.row withObject: label];
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
