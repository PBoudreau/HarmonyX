//
//  FSCDataSharingController.h
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-11-06.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FSCHarmonyConfiguration.h"

@interface FSCDataSharingController : NSObject

+ (void) saveUsername: (NSString *) username
             password: (NSString *) password
            IPAddress: (NSString *) IPAddress
                 port: (NSUInteger) port;

+ (void) loadUsername: (NSString **) username
             password: (NSString **) password
            IPAddress: (NSString **) IPAddress
                 port: (NSUInteger*) port;

+ (void) saveMyHarmonyToken: (NSString *) myHarmonyToken;
+ (NSString *) loadMyHarmonyToken;

+ (void) saveHarmonyHubToken: (NSString *) harmonyHubToken;
+ (NSString *) loadHarmonyHubToken;

+ (void) saveHarmonyConfiguration: (FSCHarmonyConfiguration *) configuration;

+ (FSCHarmonyConfiguration *) loadHarmonyConfiguration;

@end
