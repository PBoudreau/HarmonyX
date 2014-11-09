//
//  TodayViewController.m
//  TodayExtension
//
//  Created by Philippe Boudreau on 2014-11-05.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

#import "FSCHarmonyCommon.h"
#import "FSCDataSharingController.h"
#import "FSCHarmonyClient.h"

static const CGFloat extensionHeight = 37.0;

@interface TodayViewController () <NCWidgetProviding>

@end

@implementation TodayViewController

#pragma mark - Superclass Methods

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    [self setPreferredContentSize: CGSizeMake(0.0, extensionHeight)];
}

- (UIEdgeInsets) widgetMarginInsetsForProposedMarginInsets: (UIEdgeInsets) defaultMarginInsets
{
    return UIEdgeInsetsZero;
}

#pragma mark - Class Methods

- (FSCHarmonyClient *) connectedClient
{
    NSString * username;
    NSString * password;
    NSString * IPAddress;
    NSUInteger port;
    
    [FSCDataSharingController loadUsername: &username
                                  password: &password
                                 IPAddress: &IPAddress
                                      port: &port];
    
    FSCHarmonyClient * client = [FSCHarmonyClient clientWithMyHarmonyUsername: username
                                                            myHarmonyPassword: password
                                                          harmonyHubIPAddress: IPAddress
                                                               harmonyHubPort: port];

    return client;
}

- (void) executeBlockWithConnectedClient: (void (^)(FSCHarmonyClient *))block
{
    [[self view] setUserInteractionEnabled: NO];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        FSCHarmonyClient * client = nil;
        NSString * userMessage = nil;
        
        @try
        {
            client = [self connectedClient];
            
            userMessage = @"Sucessfully connected to Harmony Hub.";
            
            block(client);
        }
        @catch (NSException * exception)
        {
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
        }
        @finally
        {
            if (client)
            {
                [client disconnect];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[self view] setUserInteractionEnabled: YES];
            
            if (userMessage)
            {
                NSLog(@"%@", userMessage);
            }
        });
    });
}

- (IBAction) chromecastButtonTapped: (id) sender
{
    [self executeBlockWithConnectedClient:^(FSCHarmonyClient * client) {
        
        [client startActivity: @"9204546"];
    }];
}

- (IBAction) teleButtonPressed: (id) sender
{
    [self executeBlockWithConnectedClient:^(FSCHarmonyClient * client) {
        
        [client startActivity: @"5881221"];
    }];
}

- (IBAction) upButtonTapped: (id) sender
{
    
}

- (IBAction) downButtonTapped: (id) sender
{
    
}

- (IBAction) offButtonTapped: (id) sender
{
    [self executeBlockWithConnectedClient:^(FSCHarmonyClient * client) {
        
        [client turnOff];
    }];
}

@end
