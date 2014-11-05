//
//  FSCHarmonyController.h
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-10-28.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FSCHarmonyClientController.h"

@interface FSCHarmonyController : NSObject

+ (FSCHarmonyController *) sharedInstance;

- (void) loginToLogitechWithUsername: (NSString *) username
                            password: (NSString *) password
                               forIP: (NSString *) harmonyIP
                                port: (NSUInteger) port
                          completion: (void (^)(NSString * token))completion;

- (void) clientWithWithUsername: (NSString *) username
                       password: (NSString *) password
                          forIP: (NSString *) harmonyIP
                           port: (NSUInteger) port
                     completion: (void (^)(FSCHarmonyClientController * client))completion;

@end
