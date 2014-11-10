//
//  FSCHarmonyClient.h
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-11-06.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FSCHarmonyConfiguration.h"
#import "FSCActivity.h"

@interface FSCHarmonyClient : NSObject

+ (id) clientWithMyHarmonyUsername: (NSString *) username
                 myHarmonyPassword: (NSString *) password
               harmonyHubIPAddress: (NSString *) IPAddress
                    harmonyHubPort: (NSUInteger) port;

- (FSCHarmonyConfiguration *) configuration;

- (NSString *) currentActivity;

- (void) startActivityWithId: (NSString *) activityId;
- (void) startActivity: (FSCActivity *) activity;

- (void) turnOff;

- (void) disconnect;

@end
