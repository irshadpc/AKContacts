//
//  AKSource.m
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

#import "AKSource.h"
#import "AKAddressBook.h"
#import "AKGroup.h"

@interface AKAddressBook ()

-(ABRecordRef)recordRef;

@end

@implementation AKSource

@synthesize groups = _groups;
@synthesize isDefault = _isDefault;

-(id)initWithABRecordID: (ABRecordID) recordID {
  self = [super init];
  if (self) {
    super.recordID = recordID;
    
    _isDefault = NO;
    
    _groups = [[NSMutableArray alloc] init];
  }
  return  self;
}

-(ABRecordRef)recordRef {

  __block ABRecordRef ret;

  dispatch_block_t block = ^{
    if (super.recordRef == nil && super.recordID >= 0) {
      ABAddressBookRef addressBookRef = [[AKAddressBook sharedInstance] addressBookRef];
      super.recordRef = ABAddressBookGetSourceWithRecordID(addressBookRef, super.recordID);
    }
    ret = super.recordRef;
	};

  if (dispatch_get_specific(IsOnMainQueueKey)) block();
  else dispatch_sync(dispatch_get_main_queue(), block);

  return ret;
}

-(NSString *)typeName {

  if (super.recordID < 0) {
    switch (super.recordID) {
      case kSourceAggregate:
        return nil;
      default:
        return nil;
    }
  }

  NSInteger type = [(NSNumber *)[self valueForProperty: kABSourceTypeProperty] integerValue];
  type = type & ~kABSourceTypeSearchableMask;

  switch (type) {
    case kABSourceTypeLocal:
      return [[UIDevice currentDevice] localizedModel];

    case kABSourceTypeExchange:
      return @"Exchange";

    case kABSourceTypeMobileMe:
      return @"MobileMe";

    case kABSourceTypeLDAP:
      return @"LDAP";

    case kABSourceTypeCardDAV:
      return ([(NSString *)[self valueForProperty: kABSourceNameProperty] isEqualToString: @"Card"]) ? @"iCloud" : @"CardDAV";

    default:
      return @"Anonym Source";
  }
}

-(AKGroup *)groupForGroupId: (NSInteger)recordId {
  AKGroup *ret = nil;
  
  for (AKGroup *group in _groups) {
    if (group.recordID == recordId) {
      ret = group;
      break;
    }
  }
  return ret;
}

-(BOOL)hasEditableGroups {
  
  if (super.recordID < 0) {
    switch (super.recordID) {
      case kSourceAggregate:
        return NO;
      default:
        return NO;
    }
  }

  NSInteger type = [(NSNumber *)[self valueForProperty: kABSourceTypeProperty] integerValue];
  type = type & ~kABSourceTypeSearchableMask;

  switch (type) {
    case kABSourceTypeLocal:
      return YES;

    case kABSourceTypeExchange:
      return NO;

    case kABSourceTypeMobileMe:
      return NO;

    case kABSourceTypeLDAP:
      return NO;

    case kABSourceTypeCardDAV:
      return YES;

    default:
      return NO;
  }
}

-(void)commitGroupsOrder {

  NSMutableArray *groupsOrder = [[NSMutableArray alloc] init];

  for (AKGroup *group in self.groups) {
    [groupsOrder addObject: [NSNumber numberWithInteger: group.recordID]];
  }

  [[NSUserDefaults standardUserDefaults] setObject: [NSArray arrayWithArray: groupsOrder]
                                            forKey: DefaultsKeyGroups];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)revertGroupsOrder {
  
  NSArray *order = [[NSUserDefaults standardUserDefaults] arrayForKey: DefaultsKeyGroups];
  if (order != nil) {
    [self.groups sortUsingComparator: ^NSComparisonResult(id obj1, id obj2) {
      NSNumber *groupID1 = [NSNumber numberWithInteger: [(AKGroup *)obj1 recordID]];
      NSNumber *groupID2 = [NSNumber numberWithInteger: [(AKGroup *)obj2 recordID]];

      NSInteger index1 = [order indexOfObject: groupID1];
      NSInteger index2 = [order indexOfObject: groupID2];

      if (index1 < index2) {
        return NSOrderedAscending;
      } else if (index1 > index2) {
        return NSOrderedDescending;
      } else {
        return NSOrderedSame;
      }
    }];
  }
}

@end
