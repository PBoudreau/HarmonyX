//
//  FSCHarmonyAuthController.h
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-10-28.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FSCHarmonyAuthController : NSObject

+ (FSCHarmonyAuthController *) sharedInstance;

- (void) loginWithUsername: (NSString *) username
                  password: (NSString *) password
                completion: (void (^)(NSString * token))completion;

- (void) swapAuthToken: (NSString *) token
                    IP: (NSString *) IP
                  port: (NSUInteger) port
            completion: (void (^)(NSString * token))completion;

@end
