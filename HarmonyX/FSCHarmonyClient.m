//
//  FSCHarmonyClient.m
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-11-06.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import "FSCHarmonyClient.h"

#import <AFNetworking/AFNetworking.h>
#import <XMPPFramework/XMPP.h>

#import "FSCHarmonyCommon.h"
#import "FSCDataSharingController.h"

#ifdef STATIC_ACTIVITY
static NSString * const STATIC_ACTIVITY_ID = @"5881221";
#endif

static NSString * const MY_HARMONY_AUTH_URL = @"https://svcs.myharmony.com/CompositeSecurityServices/Security.svc/json/GetUserAuthToken";

static NSString * const GENERAL_HARMONY_HUB_USERNAME = @"guest@connect.logitech.com/harmonyx";
static NSString * const GENERAL_HARMONY_HUB_PASSWORD = @"harmonyx";

static NSTimeInterval const TIMEOUT_DEFAULT = 10;

@interface FSCHarmonyClient ()
{
    BOOL didDisconnectWhileConnecting;
    BOOL isXMPPConnected;
    BOOL isXMPPAuthenticated;
    BOOL didXMPPFailAuthentication;
    BOOL validOAResponseReceived;
}

@property (nonatomic, strong) FSCActivity * currentActivity;

@property (nonatomic, strong) NSDate * creationTime;
@property (nonatomic, strong) NSTimer * heartbeatTimer;

@property (nonatomic, copy) NSString * myHarmonyUsername;
@property (nonatomic, copy) NSString * myHarmonyPassword;
@property (nonatomic, copy) NSString * harmonyHubIPAddress;
@property (nonatomic, assign) NSUInteger harmonyHubPort;

@property (nonatomic, copy) NSString * myHarmonyToken;
@property (nonatomic, copy) NSString * harmonyHubToken;

@property (nonatomic, strong) XMPPStream * xmppStream;

@property (nonatomic, strong) NSError * connectionError;
@property (nonatomic, strong) NSXMLElement * authenticationError;

@property (strong) NSDate * IQSendTimestamp;
@property (nonatomic, copy) NSXMLElement * OAResponse;
@property (atomic, copy) NSString * expectedOAResponseMime;
@property (nonatomic, assign) BOOL performProgressValidation;
@property (nonatomic, strong) id validOAResponse;

@property (atomic, strong) NSString * sendIQCmdLock;
@property (atomic, strong) NSString * receiveIQCmdLock;

@end

@implementation FSCHarmonyClient

#pragma mark - Class Methods

- (id) initWithMyHarmonyUsername: (NSString *) username
               myHarmonyPassword: (NSString *) password
             harmonyHubIPAddress: (NSString *) IPAddress
                  harmonyHubPort: (NSUInteger) port
{
    ALog(@"Creating client");
    
    if (self = [super init])
    {
        [self setTimeout: TIMEOUT_DEFAULT];
        [self setCreationTime: [NSDate date]];
        
        [self setMyHarmonyUsername: username];
        [self setMyHarmonyPassword: password];
        [self setHarmonyHubIPAddress: IPAddress];
        [self setHarmonyHubPort: port];
        
        [self setMyHarmonyToken: [FSCDataSharingController loadMyHarmonyToken]];
        [self setHarmonyHubToken: [FSCDataSharingController loadHarmonyHubToken]];
        
        didDisconnectWhileConnecting = NO;
        [self setConnectionError: nil];
        isXMPPConnected = NO;
        isXMPPAuthenticated = NO;
        didXMPPFailAuthentication = NO;
        validOAResponseReceived = NO;
        
        [self setPerformProgressValidation: NO];
        
        [self setSendIQCmdLock: @"sendIQCmdLock"];
        [self setReceiveIQCmdLock: @"receiveIQCmdLock"];
    }
    
    return self;
}

+ (id) clientWithMyHarmonyUsername: (NSString *) username
                 myHarmonyPassword: (NSString *) password
               harmonyHubIPAddress: (NSString *) IPAddress
                    harmonyHubPort: (NSUInteger) port
{
    FSCHarmonyClient * client = [[self alloc] initWithMyHarmonyUsername: username
                                                      myHarmonyPassword: password
                                                    harmonyHubIPAddress: IPAddress
                                                         harmonyHubPort: port];
    
    [client setupXMPPStream];
    
    [client connect];
    
    return client;
}

- (void) startHeartbeat
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self setHeartbeatTimer: [NSTimer scheduledTimerWithTimeInterval: 30
                                                                  target: self
                                                                selector: @selector(sendHeartbeat:)
                                                                userInfo: nil
                                                                 repeats: YES]];
    });
}

- (void) stopHeartbeatTimer
{
    [[self heartbeatTimer] invalidate];
    [self setHeartbeatTimer: nil];
}

- (long) timestamp
{
    return [[NSDate date] timeIntervalSinceDate: [self creationTime]];
}

- (void) setCurrentActivity: (FSCActivity *) currentActivity
{
    _currentActivity = currentActivity;
    
    [[NSNotificationCenter defaultCenter] postNotificationName: FSCHarmonyClientCurrentActivityChangedNotification
                                                        object: self
                                                      userInfo: @{FSCHarmonyClientCurrentActivityChangedNotificationActivityKey: currentActivity}];
}

- (void) dealloc
{
    ALog(@"%@.%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

#pragma mark - Initialization & Connection

- (void) connect
{
    [self connectToHarmonyHub];
    
    [self startHeartbeat];
}

- (BOOL) isConnected
{
    return ![[self xmppStream] isDisconnected];
}

- (void) connectToHarmonyHub
{
    didDisconnectWhileConnecting = NO;
    isXMPPConnected = NO;
    isXMPPAuthenticated = NO;
    didXMPPFailAuthentication = NO;
    validOAResponseReceived = NO;
    [self setConnectionError: nil];
    [self setAuthenticationError: nil];
    
    if (![self myHarmonyToken])
    {
        [self setMyHarmonyToken: [self requestMyHarmonyToken]];
        
        [FSCDataSharingController saveMyHarmonyToken: [self myHarmonyToken]];
    }
    
    if (![self harmonyHubToken])
    {
        [self connectAndAuthenticateXMPPStreamWithUsername: GENERAL_HARMONY_HUB_USERNAME
                                                  password: GENERAL_HARMONY_HUB_PASSWORD];
        
        [self setHarmonyHubToken: [self swapMyHarmonyTokenForHarmonyHubToken: [self myHarmonyToken]]];
        
        [self disconnect];
        
        [FSCDataSharingController saveHarmonyHubToken: [self harmonyHubToken]];
    }

    [self connectAndAuthenticateXMPPStreamWithUsername: [NSString stringWithFormat:
                                                         @"%@@connect.logitech.com/harmony",
                                                         [self harmonyHubToken]]
                                              password: [self harmonyHubToken]];
}

- (NSString *) requestMyHarmonyToken
{
    ALog(@"%@", NSStringFromSelector(_cmd));
    
    AFHTTPRequestOperationManager * manager = [AFHTTPRequestOperationManager manager];
    [manager setCompletionQueue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
    [manager setRequestSerializer: [AFJSONRequestSerializer new]];
    
    NSDictionary * parameters = @{@"email": [self myHarmonyUsername],
                                  @"password": [self myHarmonyPassword]};
    
    __block NSString * myHarmonyToken = nil;
    __block BOOL asyncOperationCompleted = NO;
    __block NSError * error = nil;
    
    [manager POST: MY_HARMONY_AUTH_URL
       parameters: parameters
          success: ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSDictionary * result = [responseObject objectForKey: @"GetUserAuthTokenResult"];
         
         if (!result)
         {
             error = [NSError errorWithDomain: FSCErrorDomain
                                         code: FSCErrorCodeUnexpectedMyHarmonyResponse
                                     userInfo: @{NSLocalizedDescriptionKey: [NSString stringWithFormat:
                                                                             NSLocalizedString(@"FSCHARMONYCLIENT-MY_HARMONY-RESPONSE_FORMAT-MISSING_GETUSERAUTHTOKENRESULT", nil),
                                                                             responseObject]}];
         }
         
         if (!error)
         {
             myHarmonyToken = [result objectForKey: @"UserAuthToken"];
             
             if (!myHarmonyToken)
             {
                 error = [NSError errorWithDomain: FSCErrorDomain
                                             code: FSCErrorCodeUnexpectedMyHarmonyResponse
                                         userInfo: @{NSLocalizedDescriptionKey: [NSString stringWithFormat:
                                                                                 NSLocalizedString(@"FSCHARMONYCLIENT-MY_HARMONY-RESPONSE_FORMAT-MISSING_USERAUTHTOKEN", nil),
                                                                                 responseObject]}];
             }
         }
         
         asyncOperationCompleted = YES;
     }
          failure: ^(AFHTTPRequestOperation *operation, NSError *myHarmonyError)
     {
         error = [NSError errorWithDomain: FSCErrorDomain
                                     code: FSCErrorCodeUnexpectedMyHarmonyResponse
                                 userInfo: @{NSLocalizedDescriptionKey: [NSString stringWithFormat:
                                                                         NSLocalizedString(@"FSCHARMONYCLIENT-MY_HARMONY-RESPONSE_FORMAT-ERROR_IN_GETUSERTOKEN", nil),
                                                                         [myHarmonyError localizedDescription]]}];
         
         asyncOperationCompleted = YES;
     }];
    
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        while (!asyncOperationCompleted)
        {
            [NSThread sleepForTimeInterval: 0.25];
        }
    });
    
    if (error)
    {
        @throw [NSException exceptionWithName: FSCExceptionMyHarmonyConnection
                                       reason: [NSString stringWithFormat:
                                                NSLocalizedString(@"FSCHARMONYCLIENT-MY_HARMONY-RESPONSE_FORMAT-ERROR_REQUESTING_MY_HARMONHY_TOKEN", nil),
                                                [error description]]
                                     userInfo: nil];
    }
    
    return myHarmonyToken;
}

- (void) setupXMPPStream
{
    NSAssert([self xmppStream] == nil, @"Method setupXMPPStream invoked multiple times");
    
    [self setXmppStream: [[XMPPStream alloc] init]];
    
    [[self xmppStream] addDelegate: self
                     delegateQueue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
    [[self xmppStream] setHostName: [self harmonyHubIPAddress]];
    [[self xmppStream] setHostPort: [self harmonyHubPort]];
}

- (void) connectAndAuthenticateXMPPStreamWithUsername: (NSString *) username
                                             password: (NSString *) password
{
    ALog(@"%@", NSStringFromSelector(_cmd));
    
    if ([[self xmppStream] isDisconnected])
    {
        [[self xmppStream] setMyJID: [XMPPJID jidWithString: username]];
        
        NSError * error = nil;
        
        if (![[self xmppStream] connectWithTimeout: [self timeout]
                                             error: &error])
        {
            @throw [NSException exceptionWithName: FSCExceptionHarmonyHubConnection
                                           reason: [NSString stringWithFormat:
                                                    NSLocalizedString(@"FSCHARMONYCLIENT-HARMONY_HUB-CONNECTION_ERROR-COULD_NOT_CONNECT", nil),
                                                    [error localizedDescription]]
                                         userInfo: nil];
        }
        
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
           
            while (!isXMPPConnected &&
                   !didDisconnectWhileConnecting)
            {
                [NSThread sleepForTimeInterval: 0.25];
            }
        });
        
        if (didDisconnectWhileConnecting)
        {
            didDisconnectWhileConnecting = NO;
            
            NSDictionary * userInfo = nil;
            NSString * errorDescription = NSLocalizedString(@"GENERAL-UNKNOWN_ERROR", nil);
            
            if ([self connectionError])
            {
                userInfo = @{FSCErrorUserInfoKeyOriginalError: [self connectionError]};
                errorDescription = [[self connectionError] localizedDescription];
            }
            
            @throw [NSException exceptionWithName: FSCExceptionHarmonyHubConnection
                                           reason: [NSString stringWithFormat:
                                                    NSLocalizedString(@"FSCHARMONYCLIENT-HARMONY_HUB-CONNECTION_ERROR-COULD_NOT_CONNECT", nil),
                                                    errorDescription]
                                         userInfo: userInfo];
        }
        
        if (![[self xmppStream] authenticateWithPassword: password
                                                   error: &error])
        {
            @throw [NSException exceptionWithName: FSCExceptionHarmonyHubConnection
                                           reason: [NSString stringWithFormat:
                                                    NSLocalizedString(@"FSCHARMONYCLIENT-HARMONY_HUB-CONNECTION_ERROR-COULD_NOT_AUTHENTICATE", nil),
                                                    [error localizedDescription]]
                                         userInfo: nil];
        }
        
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            
            while (!isXMPPAuthenticated &&
                   !didXMPPFailAuthentication)
            {
                [NSThread sleepForTimeInterval: 0.25];
            }
        });
        
        if (didXMPPFailAuthentication)
        {
            [self disconnect];
            
            @throw [NSException exceptionWithName: FSCExceptionHarmonyHubConnection
                                           reason: [NSString stringWithFormat:
                                                    NSLocalizedString(@"FSCHARMONYCLIENT-HARMONY_HUB-CONNECTION_ERROR-COULD_NOT_AUTHENTICATE", nil),
                                                    [self authenticationError]]
                                         userInfo: nil];
        }
    }
    else
    {
        @throw [NSException exceptionWithName: FSCExceptionHarmonyHubConnection
                                       reason: NSLocalizedString(@"FSCHARMONYCLIENT-HARMONY_HUB-CONNECTION_ERROR-XMPP_STREAM_ALREADY_CONNECTED", nil)
                                     userInfo: nil];
    }
}

- (NSString *) swapMyHarmonyTokenForHarmonyHubToken: (NSString *) myHarmonyToken
{
    ALog(@"%@", NSStringFromSelector(_cmd));
    
    NSXMLElement * actionCmd = [[NSXMLElement alloc] initWithName: @"oa"
                                                            xmlns: @"connect.logitech.com"];
    [actionCmd addAttributeWithName: @"mime"
                        stringValue: @"vnd.logitech.connect/vnd.logitech.pair"];
    [actionCmd setStringValue: [NSString stringWithFormat:
                                @"token=%@:name=%@",
                                myHarmonyToken,
                                @"harmony#iOS6.0.1#iPhone"]];
    
    XMPPIQ * IQCmd = [XMPPIQ iqWithType: @"get"
                                  child: actionCmd];
    
    DDXMLElement *OAResponse = [self sendIQCmdAndWaitForResponse: IQCmd
                                              withMimeValidation: YES];
    NSString * OAAttributesAndValuesString = [OAResponse stringValue];
    
    NSString * harmonyHubToken = nil;
    
    if (OAAttributesAndValuesString)
    {
        NSArray * OAAttributesAndValues = [OAAttributesAndValuesString componentsSeparatedByString: @":"];
        
        for (NSString * anAttributeAndValue in OAAttributesAndValues)
        {
            NSArray * attributeAndValue = [anAttributeAndValue componentsSeparatedByString: @"="];
            
            if ([attributeAndValue count] == 2 &&
                [attributeAndValue[0] isEqualToString: @"identity"])
            {
                harmonyHubToken = attributeAndValue[1];
                
                break;
            }
        }
    }
    
    if (!harmonyHubToken)
    {
        @throw [NSException exceptionWithName: FSCExceptionHarmonyHubConnection
                                       reason: [NSString stringWithFormat:
                                                NSLocalizedString(@"FSCHARMONYCLIENT-HARMONY_HUB-API-UNEXPECTED_RESPONSE-PAIR", nil),
                                                OAAttributesAndValuesString]
                                     userInfo: nil];
    }

    return harmonyHubToken;
}

- (NSXMLElement *) sendIQCmdAndWaitForResponse: (XMPPIQ *) IQCmd
                            withMimeValidation: (BOOL) performMimeValidation
{
    return [self sendIQCmdAndWaitForResponse: IQCmd
                          withMimeValidation: performMimeValidation
                      withProgressValidation: NO];
}

- (NSXMLElement *) sendIQCmdAndWaitForResponse: (XMPPIQ *) IQCmd
                            withMimeValidation: (BOOL) performMimeValidation
                        withProgressValidation: (BOOL) performProgressValidation
{
    NSXMLElement * OAResponse = nil;
    
    @synchronized([self sendIQCmdLock])
    {
        DLog(@"%@: %@", NSStringFromSelector(_cmd), IQCmd);
        
        validOAResponseReceived = NO;
        [self setOAResponse: nil];
        [self setExpectedOAResponseMime: nil];
        [self setPerformProgressValidation: performProgressValidation];

        NSXMLElement * oaElement = [IQCmd elementForName: @"oa"];
        
        NSAssert(oaElement,
                 @"Could not find 'oa' element in IQ Cmd '%@'",
                 IQCmd);
        
        DDXMLNode * mimeNode = [oaElement attributeForName: @"mime"];
        
        NSAssert(oaElement,
                 @"Could not find 'mime' attribute in IQ Cmd '%@'",
                 IQCmd);
        
        NSString * mime = [mimeNode stringValue];
        
        if (performMimeValidation)
        {
            [self setExpectedOAResponseMime: mime];
        }
        
        [self setIQSendTimestamp: [NSDate date]];
        __block BOOL timedOut = NO;
        
        [[self xmppStream] sendElement: IQCmd];
        
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            
            while (!validOAResponseReceived &&
                   !(timedOut = ([[NSDate date] timeIntervalSinceDate: [self IQSendTimestamp]] > [self timeout])))
            {
                [NSThread sleepForTimeInterval: 0.25];
            }
        });
        
        if (timedOut)
        {
            NSString * command = [[[[mime componentsSeparatedByString: @"/"] lastObject] componentsSeparatedByString: @"?"] lastObject];
            
            @throw [NSException exceptionWithName: FSCExceptionHarmonyHubIQCmdTimedOut
                                           reason: [NSString stringWithFormat:
                                                    NSLocalizedString(@"FSCHARMONYCLIENT-HARMONY_HUB-API-IQ_CMD_TIMED_OUT", nil),
                                                    command]
                                         userInfo: nil];
        }
        
        OAResponse = [self OAResponse];
        
        [self setPerformProgressValidation: NO];
        [self setExpectedOAResponseMime: nil];
        [self setOAResponse: nil];
    }
    
    return OAResponse;
}

#pragma mark - Operations

- (void) sendHeartbeat: (NSTimer *) timer
{
    if (![[self xmppStream] isConnected])
    {
        [timer invalidate];
        [self setHeartbeatTimer: nil];
    }
    else
    {
        DLog(@"Sending heartbeat");
        
        NSXMLElement * actionCmd = [[NSXMLElement alloc] initWithName: @"oa"
                                                                xmlns: @"connect.logitech.com"];
        [actionCmd addAttributeWithName: @"mime"
                            stringValue: @"vnd.logitech.connect/vnd.logitech.ping"];
        
        XMPPIQ * IQCmd = [XMPPIQ iqWithType: @"get"
                                      child: actionCmd];
        
        [self sendIQCmdAndWaitForResponse: IQCmd
                       withMimeValidation: YES];
    }
}

- (NSString *) appendTimestampToCommand: (NSString *) command
{
    return [NSString stringWithFormat:
            @"%@:timestamp=%ld",
            command,
            [self timestamp]];
}

- (FSCHarmonyConfiguration *) configurationWithRefresh: (BOOL) refresh
{
    if (![self configuration] ||
        refresh)
    {
        ALog(@"%@", NSStringFromSelector(_cmd));
        
        NSXMLElement * actionCmd = [[NSXMLElement alloc] initWithName: @"oa"
                                                                xmlns: @"connect.logitech.com"];
        [actionCmd addAttributeWithName: @"mime"
                            stringValue: @"vnd.logitech.harmony/vnd.logitech.harmony.engine?config"];
        
        XMPPIQ * iqCmd = [XMPPIQ iqWithType: @"get"
                                      child: actionCmd];
        
        DDXMLElement *OAResponse = [self sendIQCmdAndWaitForResponse: iqCmd
                                                  withMimeValidation: YES];
        NSString * OAString = [OAResponse stringValue];
        
        NSDictionary * configuration = nil;
        
        if (OAString)
        {
            NSData * OAStringData = [OAString dataUsingEncoding: NSUTF8StringEncoding];
            NSError * error = nil;
            
            id JSONObject =  [NSJSONSerialization JSONObjectWithData: OAStringData
                                                             options: kNilOptions
                                                               error: &error];
            
            if ([JSONObject isKindOfClass: [NSDictionary class]])
            {
                configuration = JSONObject;
            }
        }
        
        if (!configuration)
        {
            @throw [NSException exceptionWithName: FSCExceptionHarmonyHubConfiguration
                                           reason: [NSString stringWithFormat:
                                                    NSLocalizedString(@"FSCHARMONYCLIENT-HARMONY_HUB-API-UNEXPECTED_RESPONSE-CONFIG", nil),
                                                    OAString]
                                         userInfo: nil];
        }
        
        FSCHarmonyConfiguration * harmonyConfig = [FSCHarmonyConfiguration modelObjectWithDictionary: configuration];
        
        [self setConfiguration: harmonyConfig];
    }
    
    return [self configuration];
}

- (FSCActivity *) currentActivityFromConfiguration: (FSCHarmonyConfiguration *) configuration
{
    if (![self currentActivity])
    {
        ALog(@"%@", NSStringFromSelector(_cmd));
        
        if (!configuration)
        {
            configuration = [self configurationWithRefresh: NO];
        }
        else
        {
            [self setConfiguration: configuration];
        }
        
        NSString * currentActivityId = nil;
        
#ifdef STATIC_ACTIVITY
        currentActivityId = STATIC_ACTIVITY_ID;
        
        NSAssert([configuration activityWithId: currentActivityId],
                 @"Could not find an activity with ID %@",
                 currentActivityId);
#else
        NSXMLElement * actionCmd = [[NSXMLElement alloc] initWithName: @"oa"
                                                                xmlns: @"connect.logitech.com"];
        [actionCmd addAttributeWithName: @"mime"
                            stringValue: @"vnd.logitech.harmony/vnd.logitech.harmony.engine?getCurrentActivity"];
        
        XMPPIQ * IQCmd = [XMPPIQ iqWithType: @"get"
                                      child: actionCmd];
        
        DDXMLElement * OAResponse =[self sendIQCmdAndWaitForResponse: IQCmd
                                                  withMimeValidation: YES];
        NSString * OAString = [OAResponse stringValue];
        
        if (OAString)
        {
            NSArray * attributeAndvalue = [OAString componentsSeparatedByString: @"="];
            
            if ([attributeAndvalue count] == 2)
            {
                currentActivityId = attributeAndvalue[1];
            }
        }
        
        if (!currentActivityId)
        {
            @throw [NSException exceptionWithName: FSCExceptionHarmonyHubCurrentActivity
                                           reason: [NSString stringWithFormat:
                                                    NSLocalizedString(@"FSCHARMONYCLIENT-HARMONY_HUB-API-UNEXPECTED_RESPONSE-GET_CURRENT_ACTIVITY", nil),
                                                    OAString]
                                         userInfo: nil];
        }
#endif
        
        [self setCurrentActivity: [configuration activityWithId: currentActivityId]];
    }
    
    return [self currentActivity];
}

- (void) startActivityWithId: (NSString *) activityId
{
    ALog(@"%@ %@", NSStringFromSelector(_cmd), activityId);
    
    NSXMLElement * actionCmd = [[NSXMLElement alloc] initWithName: @"oa"
                                                            xmlns: @"connect.logitech.com"];
    [actionCmd addAttributeWithName: @"mime"
                        stringValue: @"harmony.engine?startactivity"];
    
    NSString * command = [NSString stringWithFormat:
                          @"activityId=%@",
                          activityId];
    
    // Adding timestamp seems to cause issues where a first activity will be able to start, but
    // subsequent activity starting will fail.
//    command = [self appendTimestampToCommand: command];
    
    [actionCmd setStringValue: command];
    
    XMPPIQ * IQCmd = [XMPPIQ iqWithType: @"get"
                                  child: actionCmd];
    
    [self sendIQCmdAndWaitForResponse: IQCmd
                   withMimeValidation: YES
               withProgressValidation: YES];
}

- (void) startActivity: (FSCActivity *) activity
{
    [self startActivityWithId: [activity activityIdentifier]];
    
    [self setCurrentActivity: activity];
}

- (void) executeFunction: (FSCFunction *) function
                withType: (FSCHarmonyClientFunctionType) type
{
    DLog(@"%@", NSStringFromSelector(_cmd));
    
    NSXMLElement * actionCmd = [[NSXMLElement alloc] initWithName: @"oa"
                                                            xmlns: @"connect.logitech.com"];
    [actionCmd addAttributeWithName: @"mime"
                        stringValue: @"vnd.logitech.harmony/vnd.logitech.harmony.engine?holdAction"];
    
    NSString * typeStr = (type == FSCHarmonyClientFunctionTypePress) ? @"press" : @"release";
    
    NSString * reformattedAction = [[function action] stringByReplacingOccurrencesOfString: @":"
                                                                                withString: @"::"];
    
    [actionCmd setStringValue: [NSString stringWithFormat:
                                @"action=%@:status=%@",
                                reformattedAction,
                                typeStr]];
    
    XMPPIQ * IQCmd = [XMPPIQ iqWithType: @"get"
                                  child: actionCmd];
    
    [self sendIQCmdAndWaitForResponse: IQCmd
                   withMimeValidation: NO];
}

- (void) turnOff
{
    ALog(@"%@", NSStringFromSelector(_cmd));
    
    [self startActivity: [[self configurationWithRefresh: NO] activityWithId: @"-1"]];
}

- (void) disconnect
{
    ALog(@"%@", NSStringFromSelector(_cmd));
    
    [self stopHeartbeatTimer];
    
    if (![[self xmppStream] isDisconnected])
    {
        [[self xmppStream] disconnect];
        
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            
            while (isXMPPConnected)
            {
                [NSThread sleepForTimeInterval: 0.25];
            }
        });
    }
}

#pragma mark XMPPStream Delegate

- (void) xmppStreamDidConnect: (XMPPStream *) sender
{
    ALog(@"%@", NSStringFromSelector(_cmd));
    
    isXMPPConnected = YES;
}

- (void) xmppStreamDidAuthenticate: (XMPPStream *) sender
{
    ALog(@"%@", NSStringFromSelector(_cmd));
    
    isXMPPAuthenticated = YES;
}

- (void) xmppStream:(XMPPStream *) sender
 didNotAuthenticate: (NSXMLElement *) error
{
    ALog(@"%@ %@", NSStringFromSelector(_cmd), error);
    
    didXMPPFailAuthentication = YES;
    
    [self setAuthenticationError: error];
}

- (BOOL) xmppStream: (XMPPStream *) sender
       didReceiveIQ: (XMPPIQ *) iq
{
    @synchronized([self receiveIQCmdLock])
    {
        DLog(@"%@: %@", NSStringFromSelector(_cmd), iq);
        
        BOOL validOAResponse = NO;
        
        if ([self expectedOAResponseMime])
        {
            NSXMLElement * oaResponse = [iq elementForName: @"oa"];
            
            if (oaResponse)
            {
                [self setOAResponse: oaResponse];
                
                DDXMLNode * mimeNode = [oaResponse attributeForName: @"mime"];
                
                if (mimeNode)
                {
                    NSString * mimeResponse = [mimeNode stringValue];
                    
                    validOAResponse = [[mimeResponse lowercaseString] isEqualToString: [[self expectedOAResponseMime] lowercaseString]];
                }
                
                if (validOAResponse &&
                    [self performProgressValidation])
                {
                    validOAResponse = NO;
                    
                    NSString * oaResponseStringValue = [oaResponse stringValue];
                    
                    if (oaResponseStringValue &&
                        ![oaResponseStringValue isEqualToString: @""])
                    {
                        NSString * doneCount = nil;
                        NSString * totalCount = nil;
                        
                        for (NSString * aParameter in [oaResponseStringValue componentsSeparatedByString: @":"])
                        {
                            NSArray * parameterKeyValue = [aParameter componentsSeparatedByString: @"="];
                            
                            if ([parameterKeyValue count] == 2)
                            {
                                if ([parameterKeyValue[0] isEqualToString: @"done"])
                                {
                                    doneCount = parameterKeyValue[1];
                                }
                                else if ([parameterKeyValue[0] isEqualToString: @"total"])
                                {
                                    totalCount = parameterKeyValue[1];
                                }
                            }
                        }
                        
                        if (doneCount &&
                            totalCount &&
                            [doneCount isEqualToString: totalCount])
                        {
                            validOAResponse = YES;
                        }
                    }
                }
                
                // If the response is considered valid so far, reset the IQSendTimestamp;
                // the hub is replyting that it is in the process of executing the IQ cmd.
                if (validOAResponse)
                {
                    [self setIQSendTimestamp: [NSDate date]];
                }
                
                DDXMLNode * errorCodeNode = [oaResponse attributeForName: @"errorcode"];
                
                if (errorCodeNode)
                {
                    NSString * errorCode = [errorCodeNode stringValue];
                    
                    validOAResponse = validOAResponse && [errorCode isEqualToString: @"200"];
                }
            }
        }
        else
        {
            validOAResponse = YES;
        }
        
        validOAResponseReceived = validOAResponse;
        
        // Returning NO would cause some errors to be received from Hub as well as duplicate
        // responses.
        return YES;
    }
}

static inline char itoh(int i) {
    if (i > 9) return 'A' + (i - 10);
    return '0' + i;
}

NSString * NSStringToHex(NSString * originalString)
{
    NSUInteger i, len;
    unsigned char *buf, *bytes;
 
    NSData * data = [originalString dataUsingEncoding: NSUTF8StringEncoding];
    
    len = data.length;
    bytes = (unsigned char*)data.bytes;
    buf = malloc(len*2);
    
    for (i=0; i<len; i++) {
        buf[i*2] = itoh((bytes[i] >> 4) & 0xF);
        buf[i*2+1] = itoh(bytes[i] & 0xF);
    }
    
    return [[NSString alloc] initWithBytesNoCopy:buf
                                          length:len*2
                                        encoding:NSASCIIStringEncoding
                                    freeWhenDone:YES];
}

- (void) xmppStream: (XMPPStream *) sender
    didReceiveError: (id) error
{
    ALog(@"%@", NSStringFromSelector(_cmd));
}

- (void) xmppStreamDidDisconnect: (XMPPStream *) sender
                       withError: (NSError *) error
{
    ALog(@"%@ %@", NSStringFromSelector(_cmd), [error localizedDescription]);
    
    [self stopHeartbeatTimer];
    
    if (!isXMPPConnected)
    {
        didDisconnectWhileConnecting = YES;
        [self setConnectionError: error];
    }
    
    isXMPPConnected = NO;
    isXMPPAuthenticated = NO;
}

#pragma mark - DEBUG

- (void) renewTokens
{
    [self disconnect];
    
    [self setMyHarmonyToken: nil];
    [self setHarmonyHubToken: nil];
    
    [FSCDataSharingController saveMyHarmonyToken: nil];
    [FSCDataSharingController saveHarmonyHubToken: nil];
    
    [self connect];
}

@end
