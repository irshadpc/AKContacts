//
//  AKSource.h
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

FOUNDATION_EXPORT NSString *const defaultsSourceKey;

typedef NS_ENUM(NSInteger, SourceTypes)
{
  kSourceAggregate = -1,
};

@class AKGroup;

@interface AKSource : AKRecord

/**
 * From the docs: Each record in the address book database can belong to only one source.
 **/
@property (strong, nonatomic) NSMutableArray *groups;
@property (assign, nonatomic) BOOL isDefault;

- (id)initWithABRecordID: (ABRecordID) recordID;
/**
 * Return type of source
 */
- (NSString *)typeName;
/**
 * Return AKGroup object for a given recordId
 */
- (AKGroup *)groupForGroupId: (NSInteger)recordId;
/**
 * Return true if the source supports
 * group editing
 */
- (BOOL)hasEditableGroups;
/**
 * Commit changes to groups
 */
- (void)commitGroups;
/**
 * Revert changes to groups
 */
- (void)revertGroups;
/**
 * Revert order of groups to the order
 * currently saved in NSUserDefauls
 */
- (void)revertGroupsOrder;
/**
 * Return the indexPaths of groups that are
 * currently out of their position
 */
- (NSArray *)indexPathsOfGroupsOutOfPosition;
/**
 * Return the indexPaths of created groups
 */
- (NSArray *)indexPathsOfCreatedGroups;
/**
 * Return the indexPaths of deleted groups
 */
- (NSArray *)indexPathsOfDeletedGroups;

@end
