//
//  AppDelegate.m
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-10-28.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import "AppDelegate.h"

#import "FSCHarmonyWatchProxy.h"

@interface AppDelegate ()

@property (strong, nonatomic) FSCHarmonyWatchProxy * harmonyWatchProxy;

@end

@implementation AppDelegate


- (BOOL) application: (UIApplication *)application
didFinishLaunchingWithOptions: (NSDictionary *) launchOptions
{
    [self setHarmonyWatchProxy: [FSCHarmonyWatchProxy new]];
    
    return YES;
}

@end
