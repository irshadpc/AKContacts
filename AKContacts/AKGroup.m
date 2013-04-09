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
#import "AKAddressBook.h"

NSString *const DefaultsKeyGroups = @"Groups";

const int createGroupTag = -128;
const int deleteGroupTag = -256;

@implementation AKGroup

@synthesize memberIDs = _memberIDs;
@synthesize provisoryName = _provisoryName;

-(id)initWithABRecordID: (ABRecordID) recordID {
  self = [super init];
  if (self) {
    super.recordID = recordID;

    _memberIDs = [[NSMutableArray alloc] init];
  }
  return  self;
}

-(ABRecordRef)recordRef {

  __block ABRecordRef ret;

  dispatch_block_t block = ^{
    if (super.recordRef == nil && super.recordID >= 0) {
      ABAddressBookRef addressBookRef = [[AKAddressBook sharedInstance] addressBookRef];
      super.recordRef = ABAddressBookGetGroupWithRecordID(addressBookRef, super.recordID);
    }
    ret = super.recordRef;
  };

  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);

  return ret;
}

-(NSInteger)count {
  return [_memberIDs count];
}

@end
