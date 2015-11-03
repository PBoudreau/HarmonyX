//
//  FSCHarmonyController.m
//  HarmonyX
//
//  Created by Philippe Boudreau on 2015-11-02.
//  Copyright © 2015 Fasterre. All rights reserved.
//

#import "FSCHarmonyController.h"

#import "FSCDataSharingController.h"

#import "FSCHarmonyCommon.h"

static NSString * const standardDefaultsKeyCurrentActivity = @"currentActivity";

@implementation FSCHarmonyController

#pragma mark - Class Methods

- (void) loadConfiguration
{
    [self setHarmonyConfiguration: [FSCDataSharingController loadHarmonyConfiguration]];
    
    [self loadCurrentActivity];
}

- (NSArray *) activities
{
    return [[self harmonyConfiguration] activity];
}

- (void) setHarmonyConfiguration: (FSCHarmonyConfiguration *) harmonyConfiguration
{
    _harmonyConfiguration = harmonyConfiguration;
    
    [[NSNotificationCenter defaultCenter] postNotificationName: FSCHarmonyControllerConfigurationChangedNotification
                                                        object: self];
}

- (void) loadCurrentActivity
{
    NSUserDefaults * standardDefaults = [NSUserDefaults standardUserDefaults];
    [standardDefaults synchronize];
    NSString * currentActivityIdentifier = [standardDefaults objectForKey: standardDefaultsKeyCurrentActivity];
    
    FSCActivity * currentActivity = [[self harmonyConfiguration] activityWithId: currentActivityIdentifier];
    
    [self setCurrentActivity: currentActivity];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: FSCHarmonyControllerCurrentActivityChangedNotification
                                                        object: self
                                                      userInfo: @{
                                                                  FSCHarmonyClientCurrentActivityChangedNotificationActivityKey: currentActivity
                                                                  }];
}

- (void) saveCurrentActivity
{
    NSUserDefaults * standardDefaults = [NSUserDefaults standardUserDefaults];
    [standardDefaults setObject: [[self currentActivity] activityIdentifier]
                         forKey: standardDefaultsKeyCurrentActivity];
    [standardDefaults synchronize];
}

- (void) performClientActionsWithBlock: (void (^)(FSCHarmonyClient * client))actionsBlock
             mainThreadCompletionBlock: (void (^)(void))completionBlock;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSError * error = nil;
        BOOL clientSetupEndedCalled = NO;
        
        @try
        {
            if (![self client])
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
                    [[NSNotificationCenter defaultCenter] postNotificationName: FSCHarmonyControllerClientSetupBeganNotification
                                                                        object: self];
                    
                    [self setClient: [FSCHarmonyClient clientWithMyHarmonyUsername: username
                                                                 myHarmonyPassword: password
                                                               harmonyHubIPAddress: IPAddress
                                                                    harmonyHubPort: port]];
                    
                    [[self client] setConfiguration: [self harmonyConfiguration]];
                    
                    [[NSNotificationCenter defaultCenter] addObserver: self
                                                             selector: @selector(handleFSCHarmonyClientCurrentActivityChangedNotification:)
                                                                 name: FSCHarmonyClientCurrentActivityChangedNotification
                                                               object: [self client]];
                    
                    [[self client] currentActivityFromConfiguration: [self harmonyConfiguration]];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName: FSCHarmonyControllerClientSetupEndedNotification
                                                                        object: self];
                    
                    clientSetupEndedCalled = YES;
                }
                else if (username ||
                         password ||
                         IPAddress)
                {
                    @throw [NSException exceptionWithName: FSCExceptionCredentials
                                                   reason: [NSString stringWithFormat:
                                                            NSLocalizedString(@"FSCHARMONYVIEWCONTROLLER-CONNECTION_ERROR-CREDENTIALS", nil),
                                                            username ? username : NSLocalizedString(@"FSCHARMONYVIEWCONTROLLER-CONNECTION_ERROR-CREDENTIALS-EMPYT", nil),
                                                            password ? @"******" : NSLocalizedString(@"FSCHARMONYVIEWCONTROLLER-CONNECTION_ERROR-CREDENTIALS-EMPYT", nil),
                                                            IPAddress ? IPAddress : NSLocalizedString(@"FSCHARMONYVIEWCONTROLLER-CONNECTION_ERROR-CREDENTIALS-EMPYT", nil)]
                                                 userInfo: nil];
                }
                else
                {
                    @throw [NSException exceptionWithName: FSCExceptionSetup
                                                   reason: NSLocalizedString(@"FSCHARMONYVIEWCONTROLLER-CONNECTION_ERROR-SETUP", nil)
                                                 userInfo: nil];
                }
            }
            else if (![[self client] isConnected])
            {
                [[self client] connect];
            }
            
            if (actionsBlock)
            {
                actionsBlock([self client]);
            }
        }
        @catch (NSException * exception)
        {
            NSString * errorDescription = [exception reason];
            NSInteger errorCode = FSCErrorCodeErrorPerformingClientAction;
            
            if ([[exception name] isEqualToString: FSCExceptionSetup] ||
                [[exception name] isEqualToString: FSCExceptionCredentials] ||
                [[exception name] isEqualToString: FSCExceptionMyHarmonyConnection])
            {
                errorDescription = NSLocalizedString(@"FSCHARMONYVIEWCONTROLLER-MY_HARMONY-CONNECTION_ERROR-CREDENTIALS", nil);
                
                if ([[exception name] isEqualToString: FSCExceptionSetup])
                {
                    errorCode = FSCErrorCodeMissingSetup;
                }
                else if ([[exception name] isEqualToString: FSCExceptionCredentials])
                {
                    errorCode = FSCErrorCodeMissingCredentials;
                }
            }
            else if ([[exception name] isEqualToString: FSCExceptionHarmonyHubConnection])
            {
                errorDescription = NSLocalizedString(@"FSCHARMONYVIEWCONTROLLER-MY_HARMONY-CONNECTION_ERROR-SETUP", nil);
            }
            
            NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                              errorDescription, NSLocalizedDescriptionKey,
                                              nil];
            
            NSError * originalError = nil;
            
            if ([exception userInfo] &&
                (originalError = [[exception userInfo] objectForKey: FSCErrorUserInfoKeyOriginalError]))
            {
                userInfo[FSCErrorUserInfoKeyOriginalError] = [originalError localizedDescription];
            }
            
            error = [NSError errorWithDomain: FSCErrorDomain
                                        code: errorCode
                                    userInfo: userInfo];
        }
        @finally
        {
            if (!clientSetupEndedCalled)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName: FSCHarmonyControllerClientSetupEndedNotification
                                                                    object: self];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (completionBlock)
            {
                completionBlock();
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName: FSCHarmonyControllerClientActionCompletedNotification
                                                                object: self
                                                              userInfo: error ? @{FSCHarmonyControllerClientActionCompletedErrorKey: error} : nil];
        });
    });
}

- (void) handleCurrentActivityChanged: (FSCActivity *) newActivity
{
    [self setCurrentActivity: newActivity];
    
    [self saveCurrentActivity];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: FSCHarmonyControllerCurrentActivityChangedNotification
                                                        object: self
                                                      userInfo: @{
                                                                  FSCHarmonyClientCurrentActivityChangedNotificationActivityKey: newActivity
                                                                  }];
}

#pragma mark - Notification Handling

- (void) handleFSCHarmonyClientCurrentActivityChangedNotification: (NSNotification *) note
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self handleCurrentActivityChanged: [[note userInfo] objectForKey: FSCHarmonyClientCurrentActivityChangedNotificationActivityKey]];
    });
}

@end
