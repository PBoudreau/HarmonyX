//
//  FSCDataSharingController.m
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-11-06.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import "FSCDataSharingController.h"

#import <SimpleKeychain/A0SimpleKeychain.h>

static NSString * const FSCDataSharingGroupName = @"group.fasterre.HarmonyXTodayExtensionSharingDefaults";
static NSString * const FSCDataSharingDefaultsKeyUsername = @"username";
static NSString * const FSCDataSharingDefaultsKeyIPAddress = @"ipaddress";
static NSString * const FSCDataSharingDefaultsKeyPort = @"port";
static NSString * const FSCDataSharingDefaultsKeyHarmonyConfiguration = @"harmonyConfiguration";
static NSString * const FSCDataSharingDefaultsKeyMyHarmonyToken = @"myHarmonyToken";
static NSString * const FSCDataSharingDefaultsKeyHarmonyHubToken = @"harmonyHubToken";

static NSString * const FSCTeamID = @"239SMQFQ7S";
static NSString * const FSCDataSharingKeychainGroupName = @"com.fasterre.HarmonyX";
static NSString * const FSCDataSharingKeychainService = @"com.fasterre.harmonyx";
static NSString * const FSCDataSharingKeychainKeyPassword = @"password";

@implementation FSCDataSharingController

+ (void) saveUsername: (NSString *) username
             password: (NSString *) password
            IPAddress: (NSString *) IPAddress
                 port: (NSUInteger) port
{
    NSUserDefaults * sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: FSCDataSharingGroupName];
    
    [sharedDefaults setObject: username
                       forKey: FSCDataSharingDefaultsKeyUsername];
    
    A0SimpleKeychain * keychain = [A0SimpleKeychain keychainWithService: FSCDataSharingKeychainService
                                                            accessGroup: [NSString stringWithFormat: @"%@.%@",
                                                                          FSCTeamID,
                                                                          FSCDataSharingKeychainGroupName]];
    BOOL result = [keychain setString: password
                               forKey: FSCDataSharingKeychainKeyPassword];
    
    if (!result)
    {
        NSLog(@"Could not save password to the keychain");
    }
    
    [sharedDefaults setObject: IPAddress
                       forKey: FSCDataSharingDefaultsKeyIPAddress];
    [sharedDefaults setObject: [NSNumber numberWithUnsignedInteger: port]
                       forKey: FSCDataSharingDefaultsKeyPort];
    
    [sharedDefaults synchronize];
}

+ (void) loadUsername: (NSString **) username
             password: (NSString **) password
            IPAddress: (NSString **) IPAddress
                 port: (NSUInteger*) port
{
    NSUserDefaults * sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: FSCDataSharingGroupName];
    
    [sharedDefaults synchronize];
    
    *username = [sharedDefaults stringForKey: FSCDataSharingDefaultsKeyUsername];
    
    A0SimpleKeychain * keychain = [A0SimpleKeychain keychainWithService: FSCDataSharingKeychainService
                                                            accessGroup: [NSString stringWithFormat: @"%@.%@",
                                                                          FSCTeamID,
                                                                          FSCDataSharingKeychainGroupName]];
    *password = [keychain stringForKey: FSCDataSharingKeychainKeyPassword];
    
    *IPAddress = [sharedDefaults stringForKey: FSCDataSharingDefaultsKeyIPAddress];
    
    NSString * portString = [[sharedDefaults objectForKey: FSCDataSharingDefaultsKeyPort] stringValue];
    
    if (!portString)
    {
        portString = @"5222";
    }
    
    *port = [portString integerValue];
}

+ (void) saveMyHarmonyToken: (NSString *) myHarmonyToken
{
    NSUserDefaults * sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: FSCDataSharingGroupName];
    
    [sharedDefaults setObject: myHarmonyToken
                       forKey: FSCDataSharingDefaultsKeyMyHarmonyToken];
    [sharedDefaults synchronize];
}

+ (NSString *) loadMyHarmonyToken
{
    NSUserDefaults * sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: FSCDataSharingGroupName];
    
    [sharedDefaults synchronize];
    
    return [sharedDefaults stringForKey: FSCDataSharingDefaultsKeyMyHarmonyToken];
}

+ (void) saveHarmonyHubToken: (NSString *) harmonyHubToken
{
    NSUserDefaults * sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: FSCDataSharingGroupName];
    
    [sharedDefaults setObject: harmonyHubToken
                       forKey: FSCDataSharingDefaultsKeyHarmonyHubToken];
    [sharedDefaults synchronize];
}

+ (NSString *) loadHarmonyHubToken
{
    NSUserDefaults * sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: FSCDataSharingGroupName];
    
    [sharedDefaults synchronize];
    
    return [sharedDefaults stringForKey: FSCDataSharingDefaultsKeyHarmonyHubToken];
}

+ (void) saveHarmonyConfiguration: (FSCHarmonyConfiguration *) configuration
{
    NSUserDefaults * sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: FSCDataSharingGroupName];
    
    NSData * encodedConfiguration = [NSKeyedArchiver archivedDataWithRootObject: configuration];
    
    [sharedDefaults setObject: encodedConfiguration
                       forKey: FSCDataSharingDefaultsKeyHarmonyConfiguration];
    [sharedDefaults synchronize];
}

+ (FSCHarmonyConfiguration *) loadHarmonyConfiguration
{
    NSUserDefaults * sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: FSCDataSharingGroupName];
    [sharedDefaults synchronize];
    
    NSData * encodedConfiguration = [sharedDefaults objectForKey: FSCDataSharingDefaultsKeyHarmonyConfiguration];
    
    FSCHarmonyConfiguration * configuration = nil;
    
    if (encodedConfiguration)
    {
        configuration = [NSKeyedUnarchiver unarchiveObjectWithData: encodedConfiguration];
    }
    
    return configuration;
}

@end
