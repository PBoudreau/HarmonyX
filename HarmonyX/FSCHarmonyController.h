//
//  FSCHarmonyController.h
//  HarmonyX
//
//  Created by Philippe Boudreau on 2015-11-02.
//  Copyright © 2015 Fasterre. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <FSCHarmonyConfigKit/FSCHarmonyConfigKit.h>

#import "FSCHarmonyClient.h"

static NSString * const FSCHarmonyControllerClientSetupBeganNotification = @"FSCHarmonyControllerClientSetupBeganNotification";
static NSString * const FSCHarmonyControllerClientSetupEndedNotification = @"FSCHarmonyControllerClientSetupEndedNotification";
static NSString * const FSCHarmonyControllerConfigurationChangedNotification = @"FSCHarmonyControllerConfigurationChangedNotification";
static NSString * const FSCHarmonyControllerCurrentActivityChangedNotification = @"FSCHarmonyControllerCurrentActivityChangedNotification";
static NSString * const FSCHarmonyControllerClientActionCompletedNotification = @"FSCHarmonyControllerClientActionCompletedNotification";
static NSString * const FSCHarmonyControllerClientActionCompletedErrorKey = @"FSCHarmonyControllerClientActionCompletedErrorKey";

@interface FSCHarmonyController : NSObject

@property (strong, nonatomic) FSCHarmonyClient * client;
@property (strong, nonatomic) FSCHarmonyConfiguration * harmonyConfiguration;
@property (strong, nonatomic) FSCActivity * currentActivity;

- (void) loadConfiguration;
- (NSArray *) activities;

- (void) performClientActionsWithBlock: (void (^)(FSCHarmonyClient * client))actionsBlock
             mainThreadCompletionBlock: (void (^)(void))completionBlock;


@end
