//
//  AKContactsRecordViewCell.m
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

#import "AKContactsRecordViewCell.h"
#import "AKAddressBook.h"
#import "AKContact.h"

@implementation AKContactsRecordViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureCellAtIndexPath:(NSIndexPath *)indexPath
{
  AKAddressBook *akAddressBook = [AKAddressBook sharedInstance];

  NSString *key = nil;
  if ([akAddressBook.keys count] > indexPath.section)
    key = [akAddressBook.keys objectAtIndex: indexPath.section];

  NSArray *identifiersArray = [akAddressBook.contactIdentifiers objectForKey: key];
  if ([identifiersArray count] == 0) return;
  NSNumber *recordId = [identifiersArray objectAtIndex: indexPath.row];
  AKContact *contact = [akAddressBook contactForContactId: [recordId integerValue]];
  if (!contact) return;
  [self setTag: [contact recordID]];
  [self setSelectionStyle: UITableViewCellSelectionStyleBlue];

  [self setAccessoryView: nil];
  if (![contact name])
  {
    [self.textLabel setFont: [UIFont italicSystemFontOfSize: 20.f] ];
    [self.textLabel setText: NSLocalizedString(@"No Name", @"")];
  }
  else
  {
    NSString *lastName = [contact valueForProperty: kABPersonLastNameProperty];
    NSRange range = [contact.name rangeOfString: lastName];
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString: contact.name];
    [text addAttribute: NSFontAttributeName value: [UIFont boldSystemFontOfSize: 20.f] range: range];
    [self.textLabel setAttributedText: text];
  }
}

@end
