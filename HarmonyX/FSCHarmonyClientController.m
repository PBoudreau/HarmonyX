//
//  FSCHarmonyClientController.m
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-10-28.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import "FSCHarmonyClientController.h"

#import "FSCHarmonyCommon.h"

#import <XMPPFramework/XMPP.h>

@interface FSCHarmonyClientController ()
{
    BOOL isXmppConnected;
}

@property (nonatomic, copy) NSString * token;
@property (nonatomic, copy) NSString * IP;
@property (nonatomic, assign) NSUInteger port;

@property (nonatomic, strong) XMPPStream * xmppStream;
@property (nonatomic, copy) void(^xmppConnexionBlock)(FSCHarmonyClientController * client);
@property (nonatomic, copy) void(^xmppOperationBlock)(id result);

@end

@implementation FSCHarmonyClientController

#pragma mark - Singleton Methods

+ (FSCHarmonyClientController *) sharedInstance
{
    static dispatch_once_t pred;
    static FSCHarmonyClientController * _sharedInstance = nil;
    
    dispatch_once(&pred, ^{
        
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

#pragma mark - Class Methods

- (void) setSessionToken: (NSString *) token
                      IP: (NSString *) IP
                    port: (NSUInteger) port
{
    [self setToken: token];
    [self setIP: IP];
    [self setPort: port];
    
    isXmppConnected = NO;
}

- (void) connectWithCompletion: (void (^)(FSCHarmonyClientController * client))completion
{
    [self setXmppConnexionBlock: completion];
    
    [self setupXMPPStream];
    
    NSError * error;
    
    if (![self connectXMPPWithError: &error])
    {
        @throw [NSException exceptionWithName: FSCNetworkingFailureException
                                       reason: [NSString stringWithFormat:
                                                @"An error occurred while connecting to Harmony Hub: %@",
                                                [error description]]
                                     userInfo: nil];
    }
}

- (void) configWithCompletion: (void (^)(id result))completion
{
    [self setXmppOperationBlock: completion];
    
    NSXMLElement * actionCmd = [[NSXMLElement alloc] initWithName: @"oa"
                                                            xmlns: @"connect.logitech.com"];
    [actionCmd addAttributeWithName: @"mime"
                        stringValue: @"vnd.logitech.harmony/vnd.logitech.harmony.engine?config"];
    
    XMPPIQ * iqCmd = [XMPPIQ iqWithType: @"get"
                                  child: actionCmd];
    
    NSLog(@"iqCmd: %@", iqCmd);
    
    [[self xmppStream] sendElement: iqCmd];
}

- (void) currentActivityWithCompletion: (void (^)(NSString * activityId))completion
{
    void(^extractCurrentActivity)(id result) = ^(id result) {
        
        NSString * stringValue = [(NSXMLElement *) result stringValue];
        NSArray * attributeAndvalue = [stringValue componentsSeparatedByString: @"="];
        NSString * currentActivity = nil;
        
        if ([attributeAndvalue count] == 2)
        {
            currentActivity = attributeAndvalue[1];
        }
        
        completion(currentActivity);
    };
    
    [self setXmppOperationBlock: extractCurrentActivity];
    
    NSXMLElement * actionCmd = [[NSXMLElement alloc] initWithName: @"oa"
                                                            xmlns: @"connect.logitech.com"];
    [actionCmd addAttributeWithName: @"mime"
                        stringValue: @"vnd.logitech.harmony/vnd.logitech.harmony.engine?getCurrentActivity"];
    
    XMPPIQ * iqCmd = [XMPPIQ iqWithType: @"get"
                                  child: actionCmd];
    
    NSLog(@"iqCmd: %@", iqCmd);
    
    [[self xmppStream] sendElement: iqCmd];
}

- (void) startActivity: (NSString *) activityId
        withCompletion: (void (^)(id result))completion
{
    [self setXmppOperationBlock: completion];
    
    NSXMLElement * actionCmd = [[NSXMLElement alloc] initWithName: @"oa"
                                                            xmlns: @"connect.logitech.com"];
    [actionCmd addAttributeWithName: @"mime"
                        stringValue: @"harmony.engine?startactivity"];
    [actionCmd setStringValue: [NSString stringWithFormat:
                                @"activityId=%@:timestamp=0",
                                activityId]];
    
    XMPPIQ * iqCmd = [XMPPIQ iqWithType: @"get"
                                  child: actionCmd];
    
    NSLog(@"iqCmd: %@", iqCmd);
    
    [[self xmppStream] sendElement: iqCmd];
}

- (void) turnOffWithCompletion: (void (^)(id result))completion
{
    [self currentActivityWithCompletion: ^(NSString * activityId) {
        
        if (![activityId isEqualToString: @"-1"])
        {
            [self startActivity: @"-1"
                 withCompletion: completion];
        }
    }];
}

- (void) disconnect
{
    [[self xmppStream] disconnect];
    [self setXmppStream: nil];
}

#pragma mark - XMPP Client

- (void) setupXMPPStream
{
    NSAssert([self xmppStream] == nil, @"Method setupXMPPStream invoked multiple times");
    
    [self setXmppStream: [[XMPPStream alloc] init]];
    
    [[self xmppStream] addDelegate: self
                     delegateQueue: dispatch_get_main_queue()];
    
    [[self xmppStream] setHostName: [self IP]];
    [[self xmppStream] setHostPort: [self port]];
}

- (BOOL) connectXMPPWithError: (NSError **) error
{
    BOOL result = NO;
    isXmppConnected = NO;
    
    if ([[self xmppStream] isDisconnected])
    {
        [[self xmppStream] setMyJID: [XMPPJID jidWithString: [NSString stringWithFormat:
                                                              @"%@@connect.logitech.com/harmony",
                                                              [self token]]]];
        
        result = [[self xmppStream] connectWithTimeout: XMPPStreamTimeoutNone
                                                 error: error];
    }
    
    return result;
}

#pragma mark XMPPStream Delegate

- (void) xmppStreamDidConnect: (XMPPStream *) sender
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    isXmppConnected = YES;
    
    NSError * error = nil;
    
    if (![[self xmppStream] authenticateWithPassword: [self token]
                                               error: &error])
    {
        NSLog(@"*** ERROR while authenticating: %@", [error description]);
    }
}

- (void) xmppStreamDidAuthenticate: (XMPPStream *) sender
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    [self xmppConnexionBlock](self);
    
    [self setXmppConnexionBlock: nil];
}

- (void) xmppStream:(XMPPStream *) sender
 didNotAuthenticate: (NSXMLElement *) error
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (BOOL) xmppStream: (XMPPStream *) sender
       didReceiveIQ: (XMPPIQ *) iq
{
//    NSLog(@"%@: %@", NSStringFromSelector(_cmd), iq);
    
    NSXMLElement * oaResponse = [iq elementForName: @"oa"];
    
    if (oaResponse &&
        [self xmppOperationBlock])
    {
        [self xmppOperationBlock](oaResponse);
        
        [self setXmppOperationBlock: nil];
    }
    
    return NO;
}


- (void) xmppStream: (XMPPStream *) sender
    didReceiveError: (id) error
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void) xmppStreamDidDisconnect: (XMPPStream *) sender
                       withError: (NSError *) error
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    if (!isXmppConnected)
    {
        NSLog(@"*** ERROR - unable to connect to harmony. : Check xmppStream.hostName - %@", [error description]);
    }
}

@end
