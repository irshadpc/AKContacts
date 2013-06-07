//
//  AKContactButtonsViewCell.h
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

#import "AKContactLinkedViewCell.h"
#import "AKAddressBook.h"
#import "AKContactViewController.h"
#import "AKContact.h"
#import "AKSource.h"

@interface AKContactLinkedViewCell ()

@property (unsafe_unretained, nonatomic) AKContactViewController *delegate;

-(void)configureCellAtRow:(NSInteger)row;

@end

@implementation AKContactLinkedViewCell

+ (UITableViewCell *)cellWithDelegate: (AKContactViewController *)delegate atRow: (NSInteger)row
{
  static NSString *CellIdentifier = @"AKContactLinkedViewCell";
  
  AKContactLinkedViewCell *cell = [delegate.tableView dequeueReusableCellWithIdentifier: CellIdentifier];
  if (cell == nil)
  {
    cell = [[AKContactLinkedViewCell alloc] initWithStyle: UITableViewCellStyleValue2 reuseIdentifier: CellIdentifier];
  }

  [cell setDelegate: delegate];

  [cell configureCellAtRow: row];

  return (UITableViewCell *)cell;
}

- (void)configureCellAtRow:(NSInteger)row
{
  [self.textLabel setText: nil];
  [self.detailTextLabel setText: nil];
  [self setSelectionStyle: UITableViewCellSelectionStyleBlue];
  [self setAccessoryType: UITableViewCellAccessoryNone];
  
  NSInteger recordID = [[[self.delegate.contact linkedContactIDs] objectAtIndex: row] integerValue];

  if (recordID != self.delegate.parentLinkedContactID)
  {
    [self setAccessoryType: UITableViewCellAccessoryDisclosureIndicator];
  }

  AKSource *source = [[AKAddressBook sharedInstance] sourceForContactId: recordID];
  AKContact *contact = [[AKAddressBook sharedInstance] contactForContactId: recordID];

  [self.textLabel setText: [source typeName]];
  [self.detailTextLabel setText: [contact name]];
}

@end
