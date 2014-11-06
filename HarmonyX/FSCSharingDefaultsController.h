//
//  FSCSharingDefaultsController.h
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-11-06.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString * const FSCTodayExtensionSharingDefaultsGroupName = @"group.fasterre.HarmonyXTodayExtensionSharingDefaults";
static NSString * const FSCTodayExtensionSharingDefaultsKeyUsername = @"username";
static NSString * const FSCTodayExtensionSharingDefaultsKeyIPAddress = @"ipaddress";
static NSString * const FSCTodayExtensionSharingDefaultsKeyPort = @"port";

@interface FSCSharingDefaultsController : NSObject

+ (void) saveUsername: (NSString *) username
             password: (NSString *) password
            IPAddress: (NSString *) IPAddress
                 port: (NSUInteger) port;

+ (void) loadUsername: (NSString **) username
             password: (NSString **) password
            IPAddress: (NSString **) IPAddress
                 port: (NSUInteger*) port;

@end
