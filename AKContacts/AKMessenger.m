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

#import "AKMessenger.h"
#import "AKAddressBook.h"
#import "AKContact.h"
#import "AppDelegate.h"

#import <MessageUI/MFMessageComposeViewController.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface AKMessenger () <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UIActionSheetDelegate>

@property (nonatomic, assign) NSInteger contactID;

@end

@implementation AKMessenger

#pragma mark - Class methods

+ (AKMessenger *)sharedInstance
{
  static dispatch_once_t once;
  static AKMessenger *messanger;
  dispatch_once(&once, ^{ messanger = [[self alloc] init]; });
  return messanger;
}

#pragma mark - Custom methods

- (void)sendTextWithRecipient: (NSString *)recipient
{
  NSString *sURL = [NSString stringWithFormat: @"heywire:%@", recipient];
  NSURL *URL = [[NSURL alloc] initWithString: sURL];

  UIApplication *application = [UIApplication sharedApplication];
  if ([application canOpenURL: URL])
  {
    [application openURL: URL];
  }
  else
  {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: @"HeyWire Free Texting Not Installed"
                                                        message: @"Please install/update the latest version of HeyWire to enable free texting."
                                                       delegate: nil
                                              cancelButtonTitle: @"OK"
                                              otherButtonTitles: nil];
    [alertView show];
  }
}

- (void)sendEmailWithRecipients: (NSArray *)recipients
{
  if ([MFMailComposeViewController canSendMail])
  {
    MFMailComposeViewController *emailVC = [[MFMailComposeViewController alloc] init];
    [emailVC setMailComposeDelegate: self];
    [emailVC setToRecipients: recipients];
    //AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    //[emailVC presentModalViewController:  animated: YES];
  }
  else
  {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Email Not Configured", @"")
                                                        message: @"Please verify that email is configured on your device."
                                                       delegate: self
                                              cancelButtonTitle: NSLocalizedString(@"OK", @"")
                                              otherButtonTitles: nil];
    [alertView show];
  }
}

- (void)showTextActionSheetWithContactID: (NSInteger)contactID
{
  [self setContactID: contactID];

  UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle: NSLocalizedString(@"Send Message", @"")
                                                           delegate: self
                                                  cancelButtonTitle: nil
                                             destructiveButtonTitle: nil otherButtonTitles: nil];
  AKContact *contact = [[AKAddressBook sharedInstance] contactForContactId: self.contactID];

  NSArray *identifiers = [contact identifiersForProperty: kABPersonPhoneProperty];
  for (NSNumber *identifier in identifiers)
  {
    NSString *value = [contact valueForMultiValueProperty: kABPersonPhoneProperty andIdentifier: [identifier integerValue]];
    [actionSheet addButtonWithTitle: value];
  }

  identifiers = [contact identifiersForProperty: kABPersonEmailProperty];
  for (NSNumber *identifier in identifiers)
  {
    NSString *value = [contact valueForMultiValueProperty: kABPersonEmailProperty andIdentifier: [identifier integerValue]];
    [actionSheet addButtonWithTitle: value];
  }
    
  [actionSheet addButtonWithTitle: NSLocalizedString(@"Cancel", @"")];
  [actionSheet setCancelButtonIndex: ([actionSheet numberOfButtons] - 1)];
    
  //AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  //[appDelegate showInView: ];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
  switch (result)
  {
    case MFMailComposeResultCancelled:
      break;
    case MFMailComposeResultSaved:
      break;
    case MFMailComposeResultFailed:
      break;
    case MFMailComposeResultSent:
      break;
    default:
      break;
  }
  //AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  //[appDelegate dismissModalViewControllerAnimated: YES];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
  switch (result)
  {
    case MessageComposeResultCancelled:
      break;
    case MessageComposeResultSent:
      break;
    case MessageComposeResultFailed:
      break;
    default:
      break;
  }
  //AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  //[appDelegate dismissModalViewControllerAnimated: YES];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (buttonIndex != actionSheet.cancelButtonIndex)
  {
    [self actionSheet: (UIActionSheet *)actionSheet didSelectButtonAtIndex: buttonIndex];
  }
  [actionSheet dismissWithClickedButtonIndex: buttonIndex animated: YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didSelectButtonAtIndex:(NSInteger)buttonIndex
{
  AKContact *contact = [[AKAddressBook sharedInstance] contactForContactId: self.contactID];

  NSArray *phoneIdentifiers = [contact identifiersForProperty: kABPersonPhoneProperty];
  NSArray *emailIdentifiers = [contact identifiersForProperty: kABPersonEmailProperty];
  NSInteger phoneCount = [contact countForProperty: kABPersonPhoneProperty];
  NSInteger emailCount = [contact countForProperty: kABPersonEmailProperty];
    
  if (phoneCount > 0 && buttonIndex < phoneCount)
  {
    NSInteger identifier = [[phoneIdentifiers objectAtIndex: buttonIndex] integerValue];
    NSString *value = [contact valueForMultiValueProperty: kABPersonPhoneProperty andIdentifier: identifier];
    [self sendTextWithRecipient: value];
  }
  else if (emailCount > 0)
  {
    NSInteger identifier = [[emailIdentifiers objectAtIndex: (buttonIndex - phoneCount)] integerValue];
    NSString *value = [contact valueForMultiValueProperty: kABPersonEmailProperty andIdentifier: identifier];
    [self sendEmailWithRecipients: [[NSArray alloc] initWithObjects: value, nil]];
  }
}

@end