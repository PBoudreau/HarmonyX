//
//  TodayViewController.m
//  TodayExtension
//
//  Created by Philippe Boudreau on 2014-11-05.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

#import "FSCHarmonyController.h"

static NSString * const USERNAME = @"boudreau.philippe@gmail.com";
static NSString * const PASSWORD = @"J9TwoaQGDVCOTz6{V_qK";
static NSString * const HARMONY_IP = @"10.0.1.4";
static NSUInteger HARMONY_PORT = 5222;

static const CGFloat extensionHeight = 40.0;

@interface TodayViewController () <NCWidgetProviding>

@end

@implementation TodayViewController

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    [self setPreferredContentSize: CGSizeMake(0.0, extensionHeight)];
}

- (IBAction) chromecastButtonTapped: (id) sender
{
    [[FSCHarmonyController sharedInstance] clientWithWithUsername: USERNAME
                                                         password: PASSWORD
                                                            forIP: HARMONY_IP
                                                             port: HARMONY_PORT
                                                       completion: ^(FSCHarmonyClientController *client) {
                                                           
                                                           [client startActivity: @"9204546"
                                                                  withCompletion: ^(id result) {
                                                                      
                                                                      NSLog(@"Activity startup result: %@", result);
                                                                      
                                                                      [client disconnect];
                                                                  }];
                                                       }];
}

- (IBAction) teleButtonPressed: (id) sender
{
    [[FSCHarmonyController sharedInstance] clientWithWithUsername: USERNAME
                                                         password: PASSWORD
                                                            forIP: HARMONY_IP
                                                             port: HARMONY_PORT
                                                       completion: ^(FSCHarmonyClientController *client) {
                                                           
                                                           [client startActivity: @"5881221"
                                                                  withCompletion: ^(id result) {
                                                                      
                                                                      NSLog(@"Activity startup result: %@", result);
                                                                      
                                                                      [client disconnect];
                                                                  }];
                                                       }];
}

- (IBAction) offButtonTapped: (id) sender
{
    [[FSCHarmonyController sharedInstance] clientWithWithUsername: USERNAME
                                                         password: PASSWORD
                                                            forIP: HARMONY_IP
                                                             port: HARMONY_PORT
                                                       completion: ^(FSCHarmonyClientController *client) {
                                                           
                                                           [client turnOffWithCompletion: ^(id result) {
                                                               
                                                               NSLog(@"Turn off result: %@", result);
                                                               
                                                               [client disconnect];
                                                           }];
                                                       }];
}

@end
