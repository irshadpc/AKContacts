//
//  AKGroup.m
//  AKContacts
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

#import "AKGroup.h"
#import "AKContact.h"
#import "AKSource.h"
#import "AKAddressBook.h"

NSString *const DefaultsKeyGroups = @"Groups";

@implementation AKGroup

- (instancetype)initWithABRecordID: (ABRecordID) recordID andAddressBookRef: (ABAddressBookRef)addressBookRef
{
  self = [super initWithABRecordID: recordID recordType: kABGroupType andAddressBookRef: addressBookRef];
  if (self)
  {
    _memberIDs = [[NSMutableSet alloc] init];
  }
  return  self;
}

- (NSInteger)count
{
  if (self.isMainAggregate == NO)
  {
    return [self.memberIDs count];
  }
  else
  {
    NSInteger ret = 0;
    AKAddressBook *addressBook = [AKAddressBook sharedInstance];
    for (AKSource *source in addressBook.sources)
    {
      for (AKGroup *group in source.groups)
      {
        if (group.isMainAggregate == YES) continue;
        if (group.recordID == kGroupAggregate)
        {
          ret += [group count];
        }
      }
    }
    return ret;
  }
}

- (void)insertMemberWithID: (ABRecordID)recordID
{
  NSNumber *identifier = [NSNumber numberWithInteger: recordID];
  if ([self.memberIDs member: identifier] == nil)
  {
    AKAddressBook *addressBook = [AKAddressBook sharedInstance];
    AKContact *contact = [addressBook contactForContactId: recordID];

    CFErrorRef error = NULL;
    ABGroupAddMember(self.recordRef, contact.recordRef, &error);
    if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }

    [self.memberIDs addObject: identifier];
  }
}

- (void)removeMemberWithID: (ABRecordID)recordID
{
  NSNumber *identifier = [NSNumber numberWithInteger: recordID];
  if ([self.memberIDs member: identifier] != nil)
  {
    AKAddressBook *addressBook = [AKAddressBook sharedInstance];
    AKContact *contact = [addressBook contactForContactId: recordID];
      
    CFErrorRef error = NULL;
    ABGroupRemoveMember(self.recordRef, contact.recordRef, &error);
    if (error != NULL) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }

    if (self.deleteMemberIDs == nil)
    {
      self.deleteMemberIDs = [[NSMutableSet alloc] init];
    }
    [self.deleteMemberIDs addObject: identifier];

    [self.memberIDs removeObject: identifier];
  }
}

- (void)commitMembers
{
  if (self.deleteMemberIDs != nil)
  {
    [self setDeleteMemberIDs: nil];
  }

  if (ABAddressBookHasUnsavedChanges(super.addressBookRef))
  {
    [[AKAddressBook sharedInstance] setNeedReload: NO];

    CFErrorRef error = NULL;
    ABAddressBookSave(super.addressBookRef, &error);
    if (error) { NSLog(@"%ld", CFErrorGetCode(error)); error = NULL; }
  }
}

- (void)revertMembers
{
  if (self.deleteMemberIDs != nil)
  {
    [self.memberIDs addObjectsFromArray: self.deleteMemberIDs.allObjects];
    [self setDeleteMemberIDs: nil];
  }

  if (ABAddressBookHasUnsavedChanges(super.addressBookRef))
  {
    ABAddressBookRevert(super.addressBookRef);
  }
}

@end
