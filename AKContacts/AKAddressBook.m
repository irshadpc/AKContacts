//
//  AKAddressBook.m
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

#import "AKAddressBook.h"
#import "AKContact.h"
#import "AKGroup.h"
#import "AKSource.h"
#import "AKAddressBook+Loader.h"

const BOOL ShowGroups = YES;

/**
 * This key is set for the main_queue to tell if we are on the main queue
 * From the docs:
 * Keys are only compared as pointers and are never dereferenced.
 * Thus, you can use a pointer to a static variable for a specific
 * subsystem or any other value that allows you to identify the value uniquely.
 **/
const void *const IsOnMainQueueKey = &IsOnMainQueueKey;
const void *const IsOnSerialBackgroundQueueKey = &IsOnSerialBackgroundQueueKey;

/**
 * kUnknownContactID is the 32-bit flavor of NSNotfound. Hardcoded to prevent change on 64 bit
 * 2147483647 is explicitly defined in core data as default
 */
const ABRecordID kUnkownContactID = 0x7FFFFFFF;

NSString *const noPhoneNumberKey = @"-";

@interface AKAddressBook () <UIAlertViewDelegate>

@property (assign, nonatomic) ABPersonSortOrdering sortOrdering;
@property (assign, nonatomic) ABAuthorizationStatus nativeAddressBookAuthorizationStatus;

@end

@implementation AKAddressBook

#pragma mark - Address Book Changed Callback

void addressBookChanged(ABAddressBookRef reference, CFDictionaryRef dictionary, void *context)
{
    @autoreleasepool
    {
        AKAddressBook *addressBook = (__bridge AKAddressBook *)context;
        [addressBook reloadAddressBook];
    }
}

#pragma mark - Class methods

+ (AKAddressBook *)sharedInstance
{
    static dispatch_once_t once;
    static AKAddressBook *akAddressBook;
    dispatch_once(&once, ^{ akAddressBook = [[self alloc] init]; });
    return akAddressBook;
}

+ (NSArray *)sectionKeys;
{
    return @[@"A",@"B",@"C",@"D",@"E",@"F",@"F",@"G",@"H",
             @"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",
             @"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z",@"#"];
}

+ (NSArray *)countryCodePrefixes
{
    return @[@"36", @"1"];
}

+ (NSString *)documentsDirectoryPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex: 0];
}

#pragma mark - Instance methods

- (id)init
{
    self = [super init];
    if (self)
    {
        _serial_queue = dispatch_queue_create([NSStringFromClass([AKAddressBook class]) UTF8String], DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(_serial_queue, IsOnSerialBackgroundQueueKey, (__bridge void *)self, NULL);
        _semaphore = dispatch_semaphore_create(1);
        
        _needReload = YES;
        
        _loadProgress = [[NSProgress alloc] initWithParent: nil userInfo: nil];
        [_loadProgress addObserver: self forKeyPath: NSStringFromSelector(@selector(totalUnitCount)) options: NSKeyValueObservingOptionNew context:nil];
        [_loadProgress addObserver: self forKeyPath: NSStringFromSelector(@selector(completedUnitCount)) options: NSKeyValueObservingOptionNew context:nil];
        
        _status = kAddressBookOffline;
        
        _sourceID = kSourceAggregate;
        _groupID = kGroupAggregate;
        
        _phoneNumberCache = [[NSCache alloc] init];
        
        /*
         * The ABAddressBook API is not thread safe. ABAddressBook related calls are dispatched on the main queue.
         * The only exception to this is the initial loading of the contacts data that is executed in
         * the background so the UI remains responsive. See loadAddressBook that uses a local addressBook reference.
         *
         * dispatch_queue_set_specific is used to set a unique key for the main queue that can be used to
         * determine if the current queue is the main one
         */
        dispatch_queue_set_specific(dispatch_get_main_queue(), IsOnMainQueueKey, (__bridge void *)self, NULL);
        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
        CFErrorRef error = NULL;
        _addressBookRef = ABAddressBookCreateWithOptions(NULL, &error);
        if (error) { CFStringRef desc = CFErrorCopyDescription(error); NSLog(@"Address book reference error (%ld): %@", CFErrorGetCode(error), desc); CFRelease(desc); error = NULL; }
#else
        _addressBookRef = ABAddressBookCreate();
#endif
        
        _sortOrdering = ABPersonGetSortOrdering();
        if (&ABAddressBookGetAuthorizationStatus) {
            _nativeAddressBookAuthorizationStatus = ABAddressBookGetAuthorizationStatus();
        }
        else {
            _nativeAddressBookAuthorizationStatus = kABAuthorizationStatusAuthorized;
        }
        
        
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(applicationWillEnterForeground:) name: UIApplicationWillEnterForegroundNotification object: nil];
        
        ABAddressBookRegisterExternalChangeCallback(_addressBookRef, addressBookChanged, (__bridge void*) self);
    }
    return self;
}

- (void)applicationWillEnterForeground: (NSNotification *)notification
{
    if ([self hasStatus: kAddressBookOnline])
    {
        NSInteger contactsCount = ABAddressBookGetPersonCount(self.addressBookRef);
        NSLog(@"Number of contacts: %ld %ld", (long)contactsCount, (long)self.nativeContactsCount);
        if (contactsCount != self.nativeContactsCount)
        {
            [self reloadAddressBook];
        }
    }
}

- (NSDate *)dateAddressBookLoaded
{
    NSDate *dateAddressBookLoaded = (NSDate *)[[NSUserDefaults standardUserDefaults] valueForKey: NSStringFromSelector(@selector(dateAddressBookLoaded))];
    return dateAddressBookLoaded;
}

- (void)setDateAddressBookLoaded:(NSDate *)dateAddressBookLoaded
{
    [[NSUserDefaults standardUserDefaults] setValue: dateAddressBookLoaded forKey: NSStringFromSelector(@selector(dateAddressBookLoaded))];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)dealloc
{
    if (_addressBookRef) {
        CFRelease(_addressBookRef);
    }
    [self.loadProgress removeObserver: self forKeyPath: NSStringFromSelector(@selector(totalUnitCount))];
    [self.loadProgress removeObserver: self forKeyPath: NSStringFromSelector(@selector(completedUnitCount))];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark - Address Book

- (BOOL)isLoading
{
    return ((self.status & kAddressBookLoadingMask) == kAddressBookLoadingMask);
}

- (void)setLoading:(BOOL)loading
{
    if (loading) {
        self.status |= kAddressBookLoadingMask;
    }
    else {
        self.status &= ~kAddressBookLoadingMask;
    }
}

- (BOOL)hasStatus: (AddressBookStatus)status
{
    return ((self.status & status) == status);
}

- (BOOL)canAccessNativeAddressBook
{
    BOOL canAccessNativeAddressBook = (self.nativeAddressBookAuthorizationStatus == kABAuthorizationStatusAuthorized);
    return canAccessNativeAddressBook;
}

- (void)requestAddressBookAccessWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    NSAssert(dispatch_get_specific(IsOnMainQueueKey), @"Must be dispatched on main queue");
    
    void (^requestBlock)(bool granted, CFErrorRef error) = ^(bool granted, CFErrorRef error){
        NSLog(@"Access %@ to addressBook", (granted) ? @"granted" : @"denied");
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                self.nativeAddressBookAuthorizationStatus = kABAuthorizationStatusAuthorized;
            }
            else {
                self.nativeAddressBookAuthorizationStatus = kABAuthorizationStatusDenied;
            }
            if (completionHandler) {
                completionHandler(granted);
            }
        });
    };
    
    ABAuthorizationStatus authorizationStatus = kABAuthorizationStatusAuthorized;
    if (&ABAddressBookGetAuthorizationStatus)
    {
        authorizationStatus = self.nativeAddressBookAuthorizationStatus;
        
        if (authorizationStatus == kABAuthorizationStatusNotDetermined)
        {
            ABAddressBookRequestAccessWithCompletion(self.addressBookRef, requestBlock);
        }
        else if (authorizationStatus == kABAuthorizationStatusDenied)
        {
            NSLog(@"kABAuthorizationStatusDenied");
        }
        else if (authorizationStatus == kABAuthorizationStatusRestricted)
        {
            NSLog(@"kABAuthorizationStatusRestricted");
        }
        else if (authorizationStatus == kABAuthorizationStatusAuthorized)
        {
            NSLog(@"kABAuthorizationStatusAuthorized");
        }
    }
    
    if (completionHandler)
    {
        completionHandler((authorizationStatus == kABAuthorizationStatusAuthorized));
    }
}

- (void)reloadAddressBook
{
    if (self.dateAddressBookLoaded)
    {
        NSTimeInterval elapsed = fabs([self.dateAddressBookLoaded timeIntervalSinceNow]);
        NSLog(@"Elapsed since last AB load: %f", elapsed);
        if (elapsed < 2.0)
        {
            return;
        }
        else
        {
            [self setNeedReload: YES];
        }
    }
    
    if (!self.isLoading && self.needReload)
    {
        __weak AKAddressBook *_self = self;
        dispatch_block_t block = ^{
            [_self loadAddressBook];
        };
        if (dispatch_get_specific(IsOnMainQueueKey)) block();
        else dispatch_async(dispatch_get_main_queue(), block);
    }
}

- (void)loadAddressBook
{
    NSAssert(dispatch_get_specific(IsOnMainQueueKey), @"Must be dispatched on main queue");
    
    if (self.isLoading) {
        // Skip if loading is already in progress
        return;
    }
    
    switch (self.status)
    {
        case kAddressBookOffline:
            self.status = kAddressBookInitializing;
            break;
        case kAddressBookOnline:
            // addressBookRef needs a revert to recognize external changes
            if (self.addressBookRef) {
                ABAddressBookRevert(self.addressBookRef);
            }
            break;
        case kAddressBookInitializing:
        default:
            break;
    }
    
    NSDate *start = [NSDate date];
    
    if ([self.presentationDelegate respondsToSelector:@selector(addressBookWillBeginLoading:)])
    {
        [self.presentationDelegate addressBookWillBeginLoading: self];
    }
    
    [self loadAddressBookWithCompletionHandler:^(BOOL addressBookChanged) {
        self.dateAddressBookLoaded = [NSDate date];
        NSLog(@"Address book loaded in %.2f", fabs([self.dateAddressBookLoaded timeIntervalSinceDate: start]));
        
        self.status = kAddressBookOnline;
        
        if ([self.presentationDelegate respondsToSelector:@selector(addressBookDidEndLoading:)])
        {
            [self.presentationDelegate addressBookDidEndLoading: self];
        }
    }];
}

- (NSDictionary *)hashTable
{
    return (self.sortOrdering == kABPersonSortByFirstName) ? self.hashTableSortedByFirst : self.hashTableSortedByLast;
}

- (NSDictionary *)hashTableSortedInverse
{
    return (self.sortOrdering != kABPersonSortByFirstName) ? self.hashTableSortedByFirst : self.hashTableSortedByLast;
}

- (NSArray *)allContactIDs
{
    NSMutableSet *contactIDs = [[NSMutableSet alloc] init];
    
    for (NSString *sectionKey in self.hashTable)
    {
        NSArray *sectionArray = [[self.hashTable objectForKey: sectionKey] copy];
        for (NSNumber *contactID in sectionArray)
        {
            [contactIDs addObject: contactID];
        }
    }
    return (contactIDs.count > 0) ? [contactIDs allObjects] : nil;
}

- (NSSet *)contactIDsWithoutPhoneNumber
{
    NSArray *contactIDsWithoutPhoneNumbers = [self.hashTableSortedByPhone objectForKey: noPhoneNumberKey];
    return (contactIDsWithoutPhoneNumbers.count > 0) ? [[NSSet alloc] initWithArray: contactIDsWithoutPhoneNumbers] : [[NSSet alloc] init];
}

- (AKSource *)defaultSource
{
    AKSource *ret = nil;
    
    for (AKSource *source in self.sources)
    {
        if ([source isDefault] == YES)
        {
            ret = source;
            break;
        }
    }
    
    NSAssert(ret != nil, @"No default source present");
    
    return ret;
}

- (AKSource *)sourceForSourceId: (ABRecordID)recordId
{
    AKSource *ret = nil;
    
    for (AKSource *source in self.sources)
    {
        if (source.recordID == recordId)
        {
            ret = source;
            break;
        }
    }
    return ret;
}

- (AKContact *)contactForContactId: (ABRecordID)recordId
{
    NSAssert(dispatch_get_specific(IsOnMainQueueKey), @"Must be dispatched on main queue");

    return [[AKContact alloc] initWithABRecordID: recordId sortOrdering: self.sortOrdering andAddressBookRef: self.addressBookRef];
}

- (AKContact *)contactForContactId: (ABRecordID)recordId withAddressBookRef: (ABAddressBookRef)addressBookRef
{
    return [[AKContact alloc] initWithABRecordID: recordId sortOrdering: self.sortOrdering andAddressBookRef: addressBookRef];
}

#warning Deal with hashTable being mutated on loading while this and other methods iterate on it
- (AKContact *)contactForPhoneNumber: (NSString *)phoneNumber
{
    NSAssert(dispatch_get_specific(IsOnMainQueueKey), @"Must be dispatched on main queue");
    
    return [self contactForPhoneNumber: phoneNumber withAddressBookRef: self.addressBookRef];
}

- (AKContact *)contactForPhoneNumber: (NSString *)phoneNumber withAddressBookRef: (ABAddressBookRef)addressBookRef
{
    AKContact *contact;
    phoneNumber = phoneNumber.stringWithNonDigitsRemoved;
    for (NSString *prefix in [AKAddressBook countryCodePrefixes]) {
        if ([phoneNumber hasPrefix: prefix]) {
            phoneNumber = [phoneNumber substringFromIndex: prefix.length];
        }
    }
    
    if (phoneNumber.length > 0)
    {
        NSNumber *recordID = [self.phoneNumberCache objectForKey: phoneNumber];
        if (recordID)
        {
            contact = [self contactForContactId: recordID.intValue withAddressBookRef: addressBookRef];
        }
        else
        {
            NSString *firstDigit = [phoneNumber substringToIndex: 1];
            NSArray *sectionArray = [[self.hashTableSortedByPhone objectForKey: firstDigit] copy];
            for (NSNumber *recordID in sectionArray)
            {
                AKContact *record = [self contactForContactId: recordID.intValue withAddressBookRef: addressBookRef];
                if (record)
                {
                    if ([[record indexesOfPhoneNumbersMatchingTerms: @[phoneNumber] preciseMatch: YES] count] > 0)
                    {
                        [self.phoneNumberCache setObject: recordID forKey: [phoneNumber copy]];
                        contact = record;
                        break;
                    }
                }
            }
        }
    }
    return contact;
}

- (AKSource *)sourceForContactId: (ABRecordID)recordId
{
    AKSource *ret = nil;
    NSNumber *contactId = [NSNumber numberWithInteger: recordId];
    for (AKSource *source in self.sources)
    {
        if (source.recordID == kSourceAggregate) continue;
        
        AKGroup *group = [source groupForGroupId: kGroupAggregate];
        if ([group.memberIDs member: contactId])
        {
            ret = source;
            break;
        }
    }
    return ret;
}

- (void)deleteRecordID: (ABRecordID)recordID
{
    NSAssert(dispatch_get_specific(IsOnMainQueueKey), @"Must be dispatched on main queue");
    
    AKContact *contact = [self contactForContactId: recordID];
    
    for (NSString *key in self.hashTableSortedByFirst)
    {
        NSMutableArray *sectionArray = [[self.hashTableSortedByFirst objectForKey: key] copy];
        [sectionArray removeObject: @(recordID)];
    }
    for (NSString *key in self.hashTableSortedByLast)
    {
        NSMutableArray *sectionArray = [[self.hashTableSortedByLast objectForKey: key] copy];
        [sectionArray removeObject: @(recordID)];
    }
    
    [self setNeedReload: NO];
    
    CFErrorRef error = NULL;
    ABAddressBookRemoveRecord(self.addressBookRef, contact.recordRef, &error);
    if (error) { CFStringRef desc = CFErrorCopyDescription(error); NSLog(@"ABAddressBookRemoveRecord (%ld): %@", CFErrorGetCode(error), desc); CFRelease(desc); error = NULL; }
    
    ABAddressBookSave(self.addressBookRef, &error);
    if (error) { CFStringRef desc = CFErrorCopyDescription(error); NSLog(@"ABAddressBookSave (%ld): %@", CFErrorGetCode(error), desc); CFRelease(desc); error = NULL; }
}

#pragma mark - Key-Value Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{   // This is not dispatched on main queue
    if (object == self.loadProgress)
    {
        int64_t completedUnitCount = self.loadProgress.completedUnitCount;
        int64_t totalUnitCount = self.loadProgress.totalUnitCount;
        
        int64_t denom = (totalUnitCount > 100) ? (totalUnitCount / 100) : totalUnitCount;
        if (completedUnitCount % denom == 0) { // Don't call to often; this eats precious CPU time
            dispatch_block_t block = ^{
                if ([self.presentationDelegate respondsToSelector:@selector(addressBook:didMakeLoadProgress:)]) {
                    [self.presentationDelegate addressBook: self didMakeLoadProgress: self.loadProgress.fractionCompleted];
                }
            };
            if (dispatch_get_specific(IsOnMainQueueKey)) block();
            else dispatch_async(dispatch_get_main_queue(), block);
        }
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
}

@end
