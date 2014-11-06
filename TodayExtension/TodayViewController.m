//
//  TodayViewController.m
//  TodayExtension
//
//  Created by Philippe Boudreau on 2014-11-05.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

#import "FSCDataSharingController.h"

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

//- (void) connectedClientWithCompletion: (void (^)(FSCHarmonyClientController * client))completion
//{
//    NSString * username;
//    NSString * password;
//    NSString * IPAddress;
//    NSUInteger port;
//    
//    [FSCDataSharingController loadUsername: &username
//                                      password: &password
//                                     IPAddress: &IPAddress
//                                          port: &port];
//    
//    [[FSCHarmonyController sharedInstance] clientWithWithUsername: username
//                                                         password: password
//                                                            forIP: IPAddress
//                                                             port: port
//                                                       completion: completion];
//}

- (IBAction) chromecastButtonTapped: (id) sender
{
//    [self connectedClientWithCompletion: ^(FSCHarmonyClientController *client) {
//        
//        [client startActivity: @"9204546"
//               withCompletion: ^(id result) {
//                   
//                   NSLog(@"Activity startup result: %@", result);
//                   
//                   [client disconnect];
//               }];
//    }];
}

- (IBAction) teleButtonPressed: (id) sender
{
//    [self connectedClientWithCompletion: ^(FSCHarmonyClientController *client) {
//        
//        [client startActivity: @"5881221"
//               withCompletion: ^(id result) {
//                   
//                   NSLog(@"Activity startup result: %@", result);
//                   
//                   [client disconnect];
//               }];
//    }];
}

- (IBAction) offButtonTapped: (id) sender
{
//    [self connectedClientWithCompletion: ^(FSCHarmonyClientController *client) {
//        
//        [client turnOffWithCompletion: ^(id result) {
//            
//            NSLog(@"Turn off result: %@", result);
//            
//            [client disconnect];
//        }];
//    }];
}

@end
