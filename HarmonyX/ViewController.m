//
//  ViewController.m
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-10-28.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import "ViewController.h"

#import <MBProgressHUDExtensions/UIViewController+MBProgressHUD.h>

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
    
    [self loadConfiguration];
    
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
        errorMessage = @"Username is required.";
    }
    else if (!passsword ||
             [passsword isEqualToString: @""])
    {
        errorMessage = @"Password is required.";
    }
    else if (!IPAddress ||
             [IPAddress isEqualToString: @""])
    {
        errorMessage = @"IP Address is required.";
    }
    else if (port == 0)
    {
        errorMessage = @"Invalid port number.";
    }
    
    if (errorMessage)
    {
        UIAlertController * controller = [UIAlertController alertControllerWithTitle: @""
                                                                             message: errorMessage
                                                                      preferredStyle: UIAlertControllerStyleAlert];
        [controller addAction: [UIAlertAction actionWithTitle: @"OK"
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
            
            NSLog(@"Current activity: %@", [[client currentActivityFromConfiguration: configuration] label]);
            
            [FSCDataSharingController saveHarmonyConfiguration: configuration];
        }
         mainThreadCompletionBlock: ^{
             
             [self setHarmonyConfiguration: configuration];
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
    
    if (error)
    {
        UIAlertController * controller = [UIAlertController alertControllerWithTitle: @""
                                                                             message: [error localizedDescription]
                                                                      preferredStyle: UIAlertControllerStyleAlert];
        [controller addAction: [UIAlertAction actionWithTitle: @"OK"
                                                        style: UIAlertActionStyleDefault
                                                      handler: ^(UIAlertAction *action) {
                                                          
                                                          [self dismissViewControllerAnimated: controller
                                                                                   completion: nil];
                                                      }]];
        
        [self presentViewController: controller
                           animated: YES
                         completion: nil];
    }
}

- (IBAction) harmonyXLabelTapped: (id) sender
{
    UIAlertController * controller = [UIAlertController alertControllerWithTitle: @"What would you like to do?"
                                                                         message: nil
                                                                  preferredStyle: UIAlertControllerStyleActionSheet];
    
    [controller addAction: [UIAlertAction actionWithTitle: @"Cancel"
                                                    style: UIAlertActionStyleCancel
                                                  handler: nil]];
    
    [controller addAction: [UIAlertAction actionWithTitle: @"Flush Tokens"
                                                    style: UIAlertActionStyleDestructive
                                                  handler: ^(UIAlertAction *action) {
                                                      
                                                      if ([self client])
                                                      {
                                                          [[self client] renewTokens];
                                                      }
                                                  }]];
    
    [self presentViewController: controller
                       animated: YES
                     completion: nil];

}

@end
