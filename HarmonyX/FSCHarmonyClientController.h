//
//  FSCHarmonyClientController.h
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-10-28.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FSCHarmonyClientController : NSObject

+ (FSCHarmonyClientController *) sharedInstance;

- (void) setSessionToken: (NSString *) token
                      IP: (NSString *) IP
                    port: (NSUInteger) port;

- (void) connectWithCompletion: (void (^)(FSCHarmonyClientController * client))completion;

- (void) configWithCompletion: (void (^)(id result))completion;

- (void) currentActivityWithCompletion: (void (^)(NSString * activityId))completion;

- (void) startActivity: (NSString *) activityId
        withCompletion: (void (^)(id result))completion;

- (void) turnOffWithCompletion: (void (^)(id result))completion;

- (void) disconnect;

@end
