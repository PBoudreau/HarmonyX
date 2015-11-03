//
//  FSCHarmonyWatchProxy.m
//  HarmonyX
//
//  Created by Philippe Boudreau on 2015-11-02.
//  Copyright © 2015 Fasterre. All rights reserved.
//

#import "FSCHarmonyWatchProxy.h"

#import <WatchConnectivity/WatchConnectivity.h>

#import "FSCHarmonyController.h"

@interface FSCHarmonyWatchProxy () <WCSessionDelegate>

@property (strong, nonatomic) FSCHarmonyController * harmonyController;

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
            
            [self setHarmonyController: [FSCHarmonyController new]];
            
            [[self harmonyController] loadConfiguration];
            
            [[NSNotificationCenter defaultCenter] addObserver: self
                                                     selector: @selector(handleFSCHarmonyControllerConfigurationChangedNotification:)
                                                         name: FSCHarmonyControllerConfigurationChangedNotification
                                                       object: [self harmonyController]];
            
            [[NSNotificationCenter defaultCenter] addObserver: self
                                                     selector: @selector(handleFSCHarmonyControllerCurrentActivityChangedNotification:)
                                                         name: FSCHarmonyControllerCurrentActivityChangedNotification
                                                       object: [self harmonyController]];
        }
    }
    
    return self;
}

#pragma mark - Class Methods



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
            FSCHarmonyConfiguration * config = [[self harmonyController] harmonyConfiguration];
            FSCActivity * currentActivity = [[self harmonyController] currentActivity];
            
            replyHandler(@{
                           @"configuration": [config dictionaryRepresentation],
                           @"currentActivity": [currentActivity dictionaryRepresentation]
                           });

        }
        else if ([command isEqualToString: @"connect"])
        {
            if (![[self harmonyController] client])
            {
                [[self harmonyController] performClientActionsWithBlock: nil
                                              mainThreadCompletionBlock: nil];
            }
            else
            {
                [[[self harmonyController] client] connect];
            }
        }
        else if ([command isEqualToString: @"disconnect"])
        {
            [[[self harmonyController] client] disconnect];
        }
    }
}

#pragma mark - Notification Handling


- (void) handleFSCHarmonyControllerConfigurationChangedNotification: (NSNotification *) note
{
    WCSession * session = [WCSession defaultSession];
    
    [session sendMessage: @{
                            @"command": @"configurationChanged",
                            @"configuration": [[[self harmonyController] harmonyConfiguration] dictionaryRepresentation],
                            @"activity": [[[self harmonyController] currentActivity] dictionaryRepresentation]
                            }
            replyHandler: nil
            errorHandler: ^(NSError * _Nonnull error) {
                
                NSLog(@"%@", error);
            }];
}

- (void) handleFSCHarmonyControllerCurrentActivityChangedNotification: (NSNotification *) note
{
    FSCActivity * activity = [note userInfo][FSCHarmonyClientCurrentActivityChangedNotificationActivityKey];
    
    WCSession * session = [WCSession defaultSession];
    
    [session sendMessage: @{
                            @"command": @"currentActivityChanged",
                            @"configuration": [[[self harmonyController] harmonyConfiguration] dictionaryRepresentation],
                            @"activity": [activity dictionaryRepresentation]
                            }
            replyHandler: nil
            errorHandler: ^(NSError * _Nonnull error) {
                
                NSLog(@"%@", error);
            }];
}

@end
