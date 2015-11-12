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
#import "FSCHarmonyCommon.h"

@interface FSCHarmonyWatchProxy () <WCSessionDelegate>

@property (strong, nonatomic) FSCHarmonyController * harmonyController;

@end

@implementation FSCHarmonyWatchProxy

- (instancetype) init
{
    if (self = [super init])
    {
        ALog(@"Initializing Watch Proxy");
        
        if ([WCSession isSupported])
        {
            ALog(@"Watch Connectivity Session is supported");
            
            [self setHarmonyController: [FSCHarmonyController new]];
            
            [[NSNotificationCenter defaultCenter] addObserver: self
                                                     selector: @selector(handleFSCHarmonyControllerConfigurationChangedNotification:)
                                                         name: FSCHarmonyControllerConfigurationChangedNotification
                                                       object: [self harmonyController]];
            
            [[NSNotificationCenter defaultCenter] addObserver: self
                                                     selector: @selector(handleFSCHarmonyControllerCurrentActivityChangedNotification:)
                                                         name: FSCHarmonyControllerCurrentActivityChangedNotification
                                                       object: [self harmonyController]];
            
            ALog(@"Activating Watch Connectivity Session");
            WCSession * session = [WCSession defaultSession];
            
            [session setDelegate: self];
            [session activateSession];
        }
        else
        {
            ALog(@"Watch Connectivity Session is NOT supported");
        }
    }
    
    return self;
}

- (void) dealloc
{
    ALog(@"%@", NSStringFromSelector(_cmd));
}

#pragma mark - Class Methods



#pragma mark - WCSessionDelegate

- (void) session: (WCSession *) session
didReceiveMessage: (NSDictionary <NSString *, id> *) message
    replyHandler: (void (^) (NSDictionary <NSString *,id> * _Nonnull)) replyHandler
{
    NSString * command = message[@"command"];
  
    ALog(@"Watch Proxy received command '%@'", command);
    
    if (command &&
        [command isKindOfClass: [NSString class]])
    {
        if ([command isEqualToString: @"getHarmonyState"])
        {
            [[self harmonyController] loadConfiguration];
            
            FSCHarmonyConfiguration * configuration  = [[self harmonyController] harmonyConfiguration];
            FSCActivity * currentActivity  = [[self harmonyController] currentActivity];
            
            NSMutableDictionary * replyContent = [NSMutableDictionary new];
            
            if (configuration)
            {
                replyContent[@"configuration"] = [configuration dictionaryRepresentation];
            }
            
            if (currentActivity)
            {
                replyContent[@"currentActivity"] = [currentActivity dictionaryRepresentation];
            }
            
            replyHandler(replyContent);
        }
        else if ([command isEqualToString: @"refreshHarmonyState"])
        {
            [[self harmonyController] reloadConfigurationAndCurrentActivity];
            
            replyHandler(@{});
        }
        else if ([command isEqualToString: @"connect"])
        {
            if (![[self harmonyController] client])
            {
                ALog(@"No client instance, creating");
                
                [[self harmonyController] performClientActionsWithBlock: nil
                                              mainThreadCompletionBlock: nil];
            }
            else
            {
                ALog(@"Client instance exists, connecting");
                
                [[[self harmonyController] client] connect];
            }
            
            replyHandler(@{});
        }
        else if ([command isEqualToString: @"disconnect"])
        {
            ALog(@"Disconnect controller: %@; client: %@", self.harmonyController, self.harmonyController.client);
            
            [[[self harmonyController] client] disconnect];
            
            replyHandler(@{});
        }
        else if ([command isEqualToString: @"startActivity"])
        {
            NSDictionary * activityDict = message[@"activity"];
            FSCActivity * activity = [FSCActivity modelObjectWithDictionary: activityDict];
            
            if (activity)
            {
                [[self harmonyController] performClientActionsWithBlock: ^(FSCHarmonyClient *client) {
                    
                    [client startActivity: activity];
                }
                                              mainThreadCompletionBlock: nil];
            }
            
            replyHandler(@{});
        }
    }
}

#pragma mark - Notification Handling


- (void) handleFSCHarmonyControllerConfigurationChangedNotification: (NSNotification *) note
{
    ALog(@"Watch Proxy notified of Harmony configuration change");
    
    FSCHarmonyConfiguration * configuration = [[self harmonyController] harmonyConfiguration];
    FSCActivity * activity = [[self harmonyController] currentActivity];
    
    if (configuration &&
        activity)
    {
        WCSession * session = [WCSession defaultSession];
        
        [session sendMessage: @{
                                @"command": @"configurationChanged",
                                @"configuration": [configuration dictionaryRepresentation],
                                @"activity": [activity dictionaryRepresentation]
                                }
                replyHandler: nil
                errorHandler: ^(NSError * _Nonnull error) {
                    
                    ALog(@"Error notifying watch of configuration change: %@", error);
                }];
    }
}

- (void) handleFSCHarmonyControllerCurrentActivityChangedNotification: (NSNotification *) note
{
    ALog(@"Watch Proxy notified of Harmony activity change");
    
    FSCHarmonyConfiguration * configuration = [[self harmonyController] harmonyConfiguration];
    FSCActivity * activity = [note userInfo][FSCHarmonyClientCurrentActivityChangedNotificationActivityKey];
    
    if (configuration &&
        activity)
    {
        WCSession * session = [WCSession defaultSession];
        
        [session sendMessage: @{
                                @"command": @"currentActivityChanged",
                                @"configuration": [configuration dictionaryRepresentation],
                                @"activity": [activity dictionaryRepresentation]
                                }
                replyHandler: nil
                errorHandler: ^(NSError * _Nonnull error) {
                    
                    ALog(@"Error notifying watch of activity change: %@", error);
                }];
    }
}

@end
