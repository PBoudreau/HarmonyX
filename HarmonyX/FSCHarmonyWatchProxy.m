//
//  FSCHarmonyWatchProxy.m
//  HarmonyX
//
//  Created by Philippe Boudreau on 2015-11-02.
//  Copyright © 2015 Fasterre. All rights reserved.
//

#import "FSCHarmonyWatchProxy.h"

#import <WatchConnectivity/WatchConnectivity.h>

#import "FSCHarmonyClient.h"
#import "FSCDataSharingController.h"

@interface FSCHarmonyWatchProxy () <WCSessionDelegate>

@property (strong, nonatomic) FSCHarmonyClient * client;

@end

@implementation FSCHarmonyWatchProxy

- (instancetype) init
{
    if (self = [super init])
    {
        if ([WCSession isSupported])
        {
            WCSession * session = [WCSession defaultSession];
            
            [session setDelegate: self];
            [session activateSession];
        }
    }
    
    return self;
}

#pragma mark - Class Methods

- (FSCHarmonyClient *) client
{
    if (!_client)
    {
        NSString * username;
        NSString * password;
        NSString * IPAddress;
        NSUInteger port;
        
        [FSCDataSharingController loadUsername: &username
                                      password: &password
                                     IPAddress: &IPAddress
                                          port: &port];
        
        if (username &&
            password &&
            IPAddress)
        {
            [self setClient: [FSCHarmonyClient clientWithMyHarmonyUsername: username
                                                         myHarmonyPassword: password
                                                       harmonyHubIPAddress: IPAddress
                                                            harmonyHubPort: port]];
        }
    }
    
    return _client;
}

#pragma mark - WCSessionDelegate

- (void) session: (WCSession *) session
didReceiveMessage: (NSDictionary <NSString *, id> *) message
    replyHandler: (void (^) (NSDictionary <NSString *,id> * _Nonnull)) replyHandler
{
    NSString * command = message[@"command"];
    
    if (command &&
        [command isKindOfClass: [NSString class]])
    {
        if ([command isEqualToString: @"getHarmonyState"])
        {
            FSCHarmonyConfiguration * config = [[self client] configurationWithRefresh: YES];
            FSCActivity * currentActivity = [[self client] currentActivityFromConfiguration: config];
            
            replyHandler(@{
                           @"configuration": [config dictionaryRepresentation],
                           @"currentActivity": [currentActivity dictionaryRepresentation]
                           });

        }
    }
}

@end
