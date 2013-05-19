//
//  AKLabelViewController.h
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

#import <UIKit/UIKit.h>
#import "AKAddressBook.h"

typedef NS_ENUM(NSInteger, Sections)
{
  kStandardSection = 0,
  kCustomSection,
  NUM_SECTIONS
};

@interface AKLabelViewController : UIViewController

typedef void (^AKLabelViewCompletionHandler)(ABPropertyID property, NSInteger identifier, NSString *label);

@property (nonatomic, assign) ABPropertyID property;
@property (nonatomic, strong) NSMutableArray *labels;
/**
 * UITextField currently being edited
 */
@property (nonatomic, strong) UITextField *firstResponder;

- (id)initWithPropertyID: (ABPropertyID)property andIdentifier: (NSInteger)identifier andSelectedLabel: (NSString *)selectedLabel andCompletionHandler: (AKLabelViewCompletionHandler)handler;

@end
