//
//  AKGroup.h
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

#import "AKRecord.h"

FOUNDATION_EXPORT NSString *const DefaultsKeyGroups;

/**
 * Add custom groups with negative IDs to avoid
 * ID collision with groups from address book
 **/
typedef NS_ENUM(NSInteger, GroupTypes)
{
  kGroupAggregate = -1,
  kGroupWillCreate = -128,
  kGroupWillDelete = -256,
};

@interface AKGroup : AKRecord

/**
 * Set of contactIDs the group contains
 **/
@property (strong, nonatomic) NSMutableSet *memberIDs;
/**
 * Set of contactIDs being removed from the group
 **/
@property (strong, nonatomic) NSMutableSet *deleteMemberIDs;
/**
 * Temporary storage for new group name 
 * before storing in AB database
 **/
@property (copy, nonatomic) NSString *provisoryName;
/**
 * Set to YES for the main aggregator group
 * the count value of which is not [memberIDs count]
 * but rather the sum of members of all aggregator groups
 */
@property (assign, nonatomic) BOOL isMainAggregate;

- (instancetype)initWithABRecordID: (ABRecordID) recordID;
/**
 * Return the member count of the group
 **/
- (NSInteger)count;

- (void)addMemberWithID: (ABRecordID)recordID;
- (void)removeMemberWithID: (NSInteger)recordID;
- (void)commit;
- (void)revert;

@end
