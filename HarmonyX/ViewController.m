//
//  ViewController.m
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-10-28.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import "ViewController.h"

#import <MBProgressHUDExtensions/UIViewController+MBProgressHUD.h>
#import <TRZSlideLicenseViewController.h>

#import "FSCHarmonyCommon.h"
#import "FSCDataSharingController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *harmonyLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *harmonyLabelCenterYConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *harmonyLabelTopSpaceConstraint;

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *IPAddressTextField;
@property (weak, nonatomic) IBOutlet UITextField *portTextField;

@end

@implementation ViewController

#pragma mark - Superclass Methods

- (void) viewDidAppear: (BOOL) animated
{
    [super viewDidAppear: animated];
    
    [self loadValues];
    
    [[self harmonyController] loadConfiguration];
    
    [[self view] layoutIfNeeded];
    
    [[self view] removeConstraint: [self harmonyLabelCenterYConstraint]];
    [self setHarmonyLabelCenterYConstraint: nil];
    [[self harmonyLabelTopSpaceConstraint] setConstant: 50.0];
    
    [UIView animateWithDuration: 1
                          delay: 0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations: ^{
                         [[self view] layoutIfNeeded];
                     }
                     completion: ^(BOOL finished) {
                         
                         [UIView animateWithDuration: 1
                                          animations: ^{
                                              
                                              [[self contentView] setAlpha: 1.0];
                                          }];
                     }];
}

#pragma mark - Class Methods

- (void) loadValues
{
    NSString * username;
    NSString * password;
    NSString * IPAddress;
    NSUInteger port;
    
    [FSCDataSharingController loadUsername: &username
                                  password: &password
                                 IPAddress: &IPAddress
                                      port: &port];
    
    [[self usernameTextField] setText: username];
    [[self passwordTextField] setText: password];
    [[self IPAddressTextField] setText: IPAddress];
    [[self portTextField] setText: [NSString stringWithFormat: @"%lu", (unsigned long)port]];
}

- (IBAction) connectButtonTapped: (id) sender
{
    if ([[self harmonyController] client])
    {
        [[[self harmonyController] client] disconnect];
        [[self harmonyController] setClient: nil];
    }
    
    [[self usernameTextField] resignFirstResponder];
    [[self passwordTextField] resignFirstResponder];
    [[self IPAddressTextField] resignFirstResponder];
    [[self portTextField] resignFirstResponder];
    
    NSString * username = [[self usernameTextField] text];
    NSString * passsword = [[self passwordTextField] text];
    NSString * IPAddress = [[self IPAddressTextField] text];
    NSUInteger port = [[[self portTextField] text] integerValue];
    
    NSString * errorMessage = nil;
    
    if (!username ||
        [username isEqualToString: @""])
    {
        errorMessage = NSLocalizedString(@"VIEWCONTROLLER-CREDENTIALS_AND_SETUP_VALIDATION-MISSING_USERNAME", nil);
    }
    else if (!passsword ||
             [passsword isEqualToString: @""])
    {
        errorMessage = NSLocalizedString(@"VIEWCONTROLLER-CREDENTIALS_AND_SETUP_VALIDATION-MISSING_PASSWORD", nil);
    }
    else if (!IPAddress ||
             [IPAddress isEqualToString: @""])
    {
        errorMessage = NSLocalizedString(@"VIEWCONTROLLER-CREDENTIALS_AND_SETUP_VALIDATION-MISSING_IP_ADDRESS", nil);
    }
    else if (port == 0)
    {
        errorMessage = NSLocalizedString(@"VIEWCONTROLLER-CREDENTIALS_AND_SETUP_VALIDATION-INVALID_PORT", nil);
    }
    
    if (errorMessage)
    {
        UIAlertController * controller = [UIAlertController alertControllerWithTitle: @""
                                                                             message: errorMessage
                                                                      preferredStyle: UIAlertControllerStyleAlert];
        [controller addAction: [UIAlertAction actionWithTitle: NSLocalizedString(@"GENERAL-OK", nil)
                                                        style: UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          
                                                          [controller dismissViewControllerAnimated: YES
                                                                                         completion: nil];
                                                      }]];
        
        [self presentViewController: controller
                           animated: YES
                         completion: nil];
    }
    else
    {
        [FSCDataSharingController saveUsername: username
                                      password: passsword
                                     IPAddress: IPAddress
                                          port: port];
        
        __block FSCHarmonyConfiguration * configuration = nil;
        
        [self performBlockingClientActionsWithBlock: ^(FSCHarmonyClient *client) {
            
            configuration = [client configurationWithRefresh: YES];
            
            ALog(@"Current activity: %@", [[client currentActivityFromConfiguration: configuration] label]);
            
            [FSCDataSharingController saveHarmonyConfiguration: configuration];
        }
         mainThreadCompletionBlock: ^{
             
             [[self harmonyController] setHarmonyConfiguration: configuration];
         }];
    }
}

- (void) prepareForBlockingClientAction
{
    [super prepareForBlockingClientAction];
    
    [self showHUD];
}

- (void) cleanupAfterBlockingClientActionWithError: (NSError *) error
{
    [super cleanupAfterBlockingClientActionWithError: error];
    
    [self hideHUD];
    
    if (error &&
        [error code] != FSCErrorCodeMissingSetup)
    {
        UIAlertController * controller = [UIAlertController alertControllerWithTitle: @""
                                                                             message: [error localizedDescription]
                                                                      preferredStyle: UIAlertControllerStyleAlert];
        [controller addAction: [UIAlertAction actionWithTitle: NSLocalizedString(@"GENERAL-OK", nil)
                                                        style: UIAlertActionStyleDefault
                                                      handler: ^(UIAlertAction *action) {
                                                          
                                                          [self dismissViewControllerAnimated: YES
                                                                                   completion: nil];
                                                      }]];
        
        [self presentViewController: controller
                           animated: YES
                         completion: nil];
    }
}

- (IBAction) infoButtonTapped: (id) sender
{
    TRZSlideLicenseViewController * controller = [[TRZSlideLicenseViewController alloc] init];
    [controller setPodsPlistName: @"Pods-acknowledgements.plist"];
    [[controller navigationItem] setTitle: NSLocalizedString(@"VIEWCONTROLLER-TRZSLIDELICENSEVIEWCONTROLLER-TITLE", nil)];
    
    [controller setHeaderType: TRZSlideLicenseViewHeaderTypeCustom];
    [controller setHeaderTitle: @""];
    [controller setHeaderText: NSLocalizedString(@"VIEWCONTROLLER-TRZSLIDELICENSEVIEWCONTROLLER-HEADER", nil)];
    [controller setTitleColor: [[self view] tintColor]];
    
    [[controller navigationItem] setLeftBarButtonItem: [[UIBarButtonItem alloc] initWithTitle: NSLocalizedString(@"GENERAL-CLOSE", nil)
                                                                                        style: UIBarButtonItemStylePlain
                                                                                       target: self
                                                                                       action: @selector(closeInfoScreen:)]];
    
    UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController: controller];
    [navController setModalTransitionStyle: UIModalTransitionStyleFlipHorizontal];
    
    [self presentViewController: navController
                       animated: YES
                     completion: nil];
}

- (void) closeInfoScreen: (id) sender
{
    [self dismissViewControllerAnimated: YES
                             completion: nil];
}

- (IBAction) harmonyXLabelTapped: (id) sender
{
    UIAlertController * controller = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"VIEWCONTROLLER-HARMONY_LABEL_TAPPED-ACTION_SHEET-TITLE", nil)
                                                                         message: nil
                                                                  preferredStyle: UIAlertControllerStyleActionSheet];
    
    [controller addAction: [UIAlertAction actionWithTitle: NSLocalizedString(@"GENERAL-CANCEL", nil)
                                                    style: UIAlertActionStyleCancel
                                                  handler: nil]];
    
    [controller addAction: [UIAlertAction actionWithTitle: NSLocalizedString(@"VIEWCONTROLLER-HARMONY_LABEL_TAPPED-ACTION_SHEET-BUTTON-FLUSH_TOKENS", nil)
                                                    style: UIAlertActionStyleDestructive
                                                  handler: ^(UIAlertAction *action) {
                                                      
                                                      if ([[self harmonyController] client])
                                                      {
                                                          [[[self harmonyController] client] renewTokens];
                                                      }
                                                  }]];
    
    [self presentViewController: controller
                       animated: YES
                     completion: nil];

}

@end
