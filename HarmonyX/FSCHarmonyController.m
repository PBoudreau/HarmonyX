//
//  FSCHarmonyController.m
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-10-28.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import "FSCHarmonyController.h"

#import "FSCHarmonyAuthController.h"

@implementation FSCHarmonyController

#pragma mark - Singleton Methods

+ (FSCHarmonyController *) sharedInstance
{
    static dispatch_once_t pred;
    static FSCHarmonyController * _sharedInstance = nil;
    
    dispatch_once(&pred, ^{
        
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

#pragma mark - Class Method

- (void) loginToLogitechWithUsername: (NSString *) username
                            password: (NSString *) password
                               forIP: (NSString *) harmonyIP
                                port: (NSUInteger) port
                          completion: (void (^)(NSString * token))completion
{
    [[FSCHarmonyAuthController sharedInstance] loginWithUsername: username
                                                        password: password
                                                      completion: ^(NSString *token)
     {
         [[FSCHarmonyAuthController sharedInstance] swapAuthToken: token
                                                               IP: harmonyIP
                                                             port: port
                                                       completion: ^(NSString *token)
          {
              completion(token);
          }];
     }];
}

- (void) clientWithWithUsername: (NSString *) username
                       password: (NSString *) password
                          forIP: (NSString *) harmonyIP
                           port: (NSUInteger) port
                     completion: (void (^)(FSCHarmonyClientController * client))completion
{
    [self loginToLogitechWithUsername: username
                             password: password
                                forIP: harmonyIP
                                 port: port
                           completion: ^(NSString *token) {
                               
                               [[FSCHarmonyClientController sharedInstance] setSessionToken: token
                                                                                         IP: harmonyIP
                                                                                       port: port];
                               
                               [[FSCHarmonyClientController sharedInstance] connectWithCompletion: completion];
                           }];
}

@end
