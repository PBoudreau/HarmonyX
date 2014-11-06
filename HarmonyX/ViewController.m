//
//  ViewController.m
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-10-28.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import "ViewController.h"

#import "FSCDataSharingController.h"
#import "FSCHarmonyController.h"

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
    NSString * username = [[self usernameTextField] text];
    NSString * passsord = [[self passwordTextField] text];
    NSString * IPAddress = [[self IPAddressTextField] text];
    NSUInteger port = [[[self portTextField] text] integerValue];
    
    NSString * errorMessage = nil;
    
    if (!username ||
        [username isEqualToString: @""])
    {
        errorMessage = @"Username is required.";
    }
    else if (!passsord ||
             [passsord isEqualToString: @""])
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
                                          password: passsord
                                         IPAddress: IPAddress
                                              port: port];
        
        [[FSCHarmonyController sharedInstance] clientWithWithUsername: username
                                                             password: passsord
                                                                forIP: IPAddress
                                                                 port: port
                                                           completion: ^(FSCHarmonyClientController *client) {
                                                               
                                                               NSLog(@"Client created successfully");
                                                               
                                                               [client disconnect];
                                                           }];
    }
}

@end
