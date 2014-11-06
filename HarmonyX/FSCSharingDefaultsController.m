//
//  FSCSharingDefaultsController.m
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-11-06.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import "FSCSharingDefaultsController.h"

@implementation FSCSharingDefaultsController

+ (void) saveUsername: (NSString *) username
             password: (NSString *) password
            IPAddress: (NSString *) IPAddress
                 port: (NSUInteger) port
{
    NSUserDefaults * sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: FSCTodayExtensionSharingDefaultsGroupName];
    
    [sharedDefaults setObject: username
                       forKey: FSCTodayExtensionSharingDefaultsKeyUsername];
    [sharedDefaults setObject: IPAddress
                       forKey: FSCTodayExtensionSharingDefaultsKeyIPAddress];
    [sharedDefaults setObject: [NSNumber numberWithUnsignedInteger: port]
                       forKey: FSCTodayExtensionSharingDefaultsKeyPort];
    
    [sharedDefaults synchronize];
}

+ (void) loadUsername: (NSString **) username
             password: (NSString **) password
            IPAddress: (NSString **) IPAddress
                 port: (NSUInteger*) port
{
    NSUserDefaults * sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: FSCTodayExtensionSharingDefaultsGroupName];
    
    [sharedDefaults synchronize];
    
    *username = [sharedDefaults stringForKey: FSCTodayExtensionSharingDefaultsKeyUsername];
    *IPAddress = [sharedDefaults stringForKey: FSCTodayExtensionSharingDefaultsKeyIPAddress];
    
    NSString * portString = [[sharedDefaults objectForKey: FSCTodayExtensionSharingDefaultsKeyPort] stringValue];
    
    if (!portString)
    {
        portString = @"5222";
    }
    
    *port = [portString integerValue];
}

@end
