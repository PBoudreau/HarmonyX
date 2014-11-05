//
//  ViewController.m
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-10-28.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import "ViewController.h"

#import "FSCHarmonyController.h"

static NSString * const USERNAME = @"boudreau.philippe@gmail.com";
static NSString * const PASSWORD = @"J9TwoaQGDVCOTz6{V_qK";
static NSString * const HARMONY_IP = @"10.0.1.4";
static NSUInteger HARMONY_PORT = 5222;

@interface ViewController ()

@end

@implementation ViewController

#pragma mark - Superclass Methods

#pragma mark - Class Methods

- (IBAction) loginButtonPressed: (id) sender
{
    [[FSCHarmonyController sharedInstance] loginToLogitechWithUsername: USERNAME
                                                              password: PASSWORD
                                                                 forIP: HARMONY_IP
                                                                  port: HARMONY_PORT
                                                            completion: ^(NSString *token)
     {
         NSLog(@"%@: token = %@", NSStringFromSelector(_cmd), token);
     }];
}

- (IBAction) configButtonPressed: (id) sender
{
    [[FSCHarmonyController sharedInstance] clientWithWithUsername: USERNAME
                                                         password: PASSWORD
                                                            forIP: HARMONY_IP
                                                             port: HARMONY_PORT
                                                       completion: ^(FSCHarmonyClientController *client) {
                                                           
                                                           [client configWithCompletion: ^void(id result) {
                                                               
                                                               NSLog(@"Harmony config: %@", result);
                                                               
                                                               [client disconnect];
                                                           }];
                                                       }];
}

- (IBAction) currentActivityButtonPressed: (id) sender
{
    [[FSCHarmonyController sharedInstance] clientWithWithUsername: USERNAME
                                                         password: PASSWORD
                                                            forIP: HARMONY_IP
                                                             port: HARMONY_PORT
                                                       completion: ^(FSCHarmonyClientController *client) {
                                                           
                                                           [client currentActivityWithCompletion: ^void(NSString * activityId) {
                                                               
                                                               NSLog(@"Current activity ID: %@", activityId);
                                                               
                                                               [client disconnect];
                                                           }];
                                                       }];
}

- (IBAction) regarderChromecastButtonPressed: (id) sender
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

- (IBAction) offButtonPressed: (id) sender
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
