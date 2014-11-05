//
//  FSCHarmonyAuthController.m
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-10-28.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import "FSCHarmonyAuthController.h"

#import "FSCHarmonyCommon.h"

#import "AFHTTPRequestOperationManager.h"

#import "XMPPFramework.h"
#import "XMPPIQ.h"

static NSString * const LOGITECH_AUTH_URL = @"https://svcs.myharmony.com/CompositeSecurityServices/Security.svc/json/GetUserAuthToken";
static NSString * const HARMONY_USERNAME = @"guest@connect.logitech.com/harmony";
static NSString * const HARMONY_PASSWORD = @"harmony";

@interface FSCHarmonyAuthController ()
{
    BOOL isXmppConnected;
}

@property (nonatomic, copy) NSString * logitechToken;
@property (nonatomic, copy) NSString * harmonyToken;
@property (nonatomic, strong) XMPPStream * xmppStream;
@property (nonatomic, copy) void(^xmppConnexionBlock)(id param);

@end

@implementation FSCHarmonyAuthController

#pragma mark - Singleton Methods

+ (FSCHarmonyAuthController *) sharedInstance
{
    static dispatch_once_t pred;
    static FSCHarmonyAuthController * _sharedInstance = nil;
    
    dispatch_once(&pred, ^{
        
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

#pragma mark - Class Method

- (void) loginWithUsername: (NSString *) username
                  password: (NSString *) password
                completion: (void (^)(NSString * token))completion
{
    AFHTTPRequestOperationManager * manager = [AFHTTPRequestOperationManager manager];

    [manager setRequestSerializer: [AFJSONRequestSerializer new]];
    
    NSDictionary * parameters = @{@"email": username,
                                  @"password": password};
    
    [manager POST: LOGITECH_AUTH_URL
       parameters: parameters
          success: ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSDictionary * result = [responseObject objectForKey: @"GetUserAuthTokenResult"];
        
        if (!result)
        {
            @throw [NSException exceptionWithName: FSCMalformedJSONException
                                           reason: [NSString stringWithFormat:
                                                    @"Could not find user auth token result keyed on 'GetUserAuthTokenResult' in JSON: %@",
                                                    responseObject]
                                         userInfo: nil];
        }
        
        NSString * token = [result objectForKey: @"UserAuthToken"];
        
        if (!token)
        {
            @throw [NSException exceptionWithName: FSCMalformedJSONException
                                           reason: [NSString stringWithFormat:
                                                    @"Could not find token keyed on 'UserAuthToken' in JSON: %@",
                                                    responseObject]
                                         userInfo: nil];
        }
        
        completion(token);
    }
          failure: ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        @throw [NSException exceptionWithName: FSCNetworkingFailureException
                                       reason: [NSString stringWithFormat:
                                                @"An error occurred in GetUserToken: %@",
                                                [error description]]
                                     userInfo: nil];
    }];
}

- (void) swapAuthToken: (NSString *) token
                    IP: (NSString *) IP
                  port: (NSUInteger) port
            completion: (void (^)(NSString * token))completion
{
    [self setLogitechToken: token];
    [self setXmppConnexionBlock: completion];
    
    [self setupXMPPStreamWithIP: IP
                           port: port];
    
    NSError * error;
    
    if (![self connectXMPPWithError: &error])
    {
        @throw [NSException exceptionWithName: FSCNetworkingFailureException
                                       reason: [NSString stringWithFormat:
                                                @"An error occurred while connecting to Harmony Hub to swap token: %@",
                                                [error description]]
                                     userInfo: nil];
    }
}

#pragma mark - XMPP Client

- (void) setupXMPPStreamWithIP: (NSString *) IP
                          port: (NSUInteger) port
{
    NSAssert([self xmppStream] == nil, @"Method setupXMPPStream invoked multiple times");
    
    [self setXmppStream: [[XMPPStream alloc] init]];
    
    [[self xmppStream] addDelegate: self
                     delegateQueue: dispatch_get_main_queue()];
    
    [[self xmppStream] setHostName: IP];
    [[self xmppStream] setHostPort: port];
}

- (BOOL) connectXMPPWithError: (NSError **) error
{
    BOOL result = NO;
    isXmppConnected = NO;
    
    if ([[self xmppStream] isDisconnected])
    {
        [[self xmppStream] setMyJID: [XMPPJID jidWithString: HARMONY_USERNAME]];
        
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
    
    if (![[self xmppStream] authenticateWithPassword: HARMONY_PASSWORD
                                               error: &error])
    {
        NSLog(@"*** ERROR while authenticating: %@", [error description]);
    }
}

- (void) xmppStreamDidAuthenticate: (XMPPStream *) sender
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    NSXMLElement * actionCmd = [[NSXMLElement alloc] initWithName: @"oa"
                                                            xmlns: @"connect.logitech.com"];
    [actionCmd addAttributeWithName: @"mime"
                        stringValue: @"vnd.logitech.connect/vnd.logitech.pair"];
    [actionCmd setStringValue: [NSString stringWithFormat:
                                @"token=%@:name=%@",
                                [self logitechToken],
                                @"harmony#iOS6.0.1#iPhone"]];
    
    XMPPIQ * iqCmd = [XMPPIQ iqWithType: @"get"
                                  child: actionCmd];
    
    NSLog(@"iqCmd: %@", iqCmd);
    
    [[self xmppStream] sendElement: iqCmd];
}

- (void) xmppStream:(XMPPStream *) sender
 didNotAuthenticate: (NSXMLElement *) error
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (BOOL) xmppStream: (XMPPStream *) sender
       didReceiveIQ: (XMPPIQ *) iq
{
    NSLog(@"%@: %@", NSStringFromSelector(_cmd), iq);
    
    NSXMLElement * oaResponse = [iq elementForName: @"oa"];
    
    if (oaResponse)
    {
        NSString * oaString = [oaResponse stringValue];
        
        if (oaString)
        {
            NSArray * oaAttributesAndValues = [oaString componentsSeparatedByString: @":"];
            
            for (NSString * anAttributeAndValue in oaAttributesAndValues)
            {
                NSArray * attributeAndValue = [anAttributeAndValue componentsSeparatedByString: @"="];
                
                if ([attributeAndValue count] == 2 &&
                    [attributeAndValue[0] isEqualToString: @"identity"])
                {
                    [self setHarmonyToken: attributeAndValue[1]];
                    
                    [[self xmppStream] disconnect];
                    [self setXmppStream: nil];
                    
                    break;
                }
            }
        }
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
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [self xmppConnexionBlock]([self harmonyToken]);
        
        [self setXmppConnexionBlock: nil];
    });
}

@end
