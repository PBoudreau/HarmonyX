//
//  ViewController.m
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-10-28.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import "ViewController.h"

#import <MBProgressHUDExtensions/UIViewController+MBProgressHUD.h>

#import "FSCActivityCollectionViewCell.h"

#import "FSCHarmonyCommon.h"
#import "FSCDataSharingController.h"
#import "FSCHarmonyClient.h"

@interface ViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *harmonyLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *harmonyLabelCenterYConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *harmonyLabelTopSpaceConstraint;

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *IPAddressTextField;
@property (weak, nonatomic) IBOutlet UITextField *portTextField;

@property (weak, nonatomic) IBOutlet UICollectionView *activityCollectionView;

@property (strong, nonatomic) FSCHarmonyConfiguration * harmonyConfiguration;

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

- (void) loadConfiguration
{
    [self setHarmonyConfiguration: [FSCDataSharingController loadHarmonyConfiguration]];
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
            
            NSLog(@"Current activity: %@", [client currentActivity]);
            
            configuration = [client configuration];
            
            [FSCDataSharingController saveHarmonyConfiguration: configuration];
        }
         mainThreadCompletionBlock: ^{
             
             [self setHarmonyConfiguration: configuration];
         }];
    }
}

- (void) performBlockingClientActionsWithBlock: (void (^)(FSCHarmonyClient * client))actionsBlock
                     mainThreadCompletionBlock: (void (^)(void))completionBlock
{
    [self showHUD];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        FSCHarmonyClient * client = nil;
        NSString * userTitle = @"";
        NSString * userMessage = nil;
        
        @try
        {
            NSString * username;
            NSString * password;
            NSString * IPAddress;
            NSUInteger port;
            
            [FSCDataSharingController loadUsername: &username
                                          password: &password
                                         IPAddress: &IPAddress
                                              port: &port];
            
            client = [FSCHarmonyClient clientWithMyHarmonyUsername: username
                                                 myHarmonyPassword: password
                                               harmonyHubIPAddress: IPAddress
                                                    harmonyHubPort: port];
            
            actionsBlock(client);
        }
        @catch (NSException * exception)
        {
            userTitle = @"Error";
            
            if ([[exception name] isEqualToString: FSCExceptionMyHarmonyConnection])
            {
                userMessage = @"Could not connect to My Harmony with the provided credentials.\n\nPlease verify that your username and password are correct.";
            }
            else if ([[exception name] isEqualToString: FSCExceptionHarmonyHubConnection])
            {
                userMessage = @"Could not connect to Harmony Hub with the provided IP address and port.";
            }
            
            if (!userMessage)
            {
                @throw exception;
            }
            else
            {
                NSLog(@"%@", exception);
            }
        }
        @finally
        {
            if (client)
            {
                [client disconnect];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (completionBlock)
            {
                completionBlock();
            }
            
            [self hideHUD];
            
            if (userMessage)
            {
                UIAlertController * controller = [UIAlertController alertControllerWithTitle: userTitle
                                                                                     message: userMessage
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
        });
    });
}

- (void) setHarmonyConfiguration: (FSCHarmonyConfiguration *) harmonyConfiguration
{
    _harmonyConfiguration = harmonyConfiguration;
    
    [[self activityCollectionView] reloadData];
}

#pragma mark - UICollectionViewDatasource

- (NSInteger) collectionView: (UICollectionView *) collectionView
      numberOfItemsInSection: (NSInteger) section
{
    NSInteger count = 0;
    
    if ([self harmonyConfiguration])
    {
        count = [[[self harmonyConfiguration] activity] count];
    }
    
    return count;
}

- (UICollectionViewCell *) collectionView: (UICollectionView *) collectionView
                   cellForItemAtIndexPath: (NSIndexPath *) indexPath
{
    FSCActivityCollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier: FSCActtivityCellIdentifier
                                                                                     forIndexPath: indexPath];
    
    FSCActivity * activity = [[self harmonyConfiguration] activity][[indexPath item]];
    
    [cell setActivity: activity
        withMaskColor: [UIColor whiteColor]];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void) collectionView:(UICollectionView *) collectionView
didSelectItemAtIndexPath: (NSIndexPath *) indexPath
{
    FSCActivity * activity = [[self harmonyConfiguration] activity][[indexPath item]];
    
    [self performBlockingClientActionsWithBlock:^(FSCHarmonyClient *client) {
        
        [client startActivity: activity];
    }
     mainThreadCompletionBlock: nil];
}

@end
