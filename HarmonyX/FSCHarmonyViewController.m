//
//  FSCHarmonyViewController.m
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-11-10.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import "FSCHarmonyViewController.h"

#import "FSCHarmonyCommon.h"

#import "FSCActivityCollectionViewCell.h"

#import "FSCDataSharingController.h"

static NSString * const standardDefaultsKeyCurrentActivity = @"currentActivity";

@interface FSCHarmonyViewController ()

@property (nonatomic, strong) FSCActivity * currentActivity;

@end

@implementation FSCHarmonyViewController

#pragma mark - Superclass Methods

- (void) viewDidAppear: (BOOL) animated
{
    [super viewDidAppear: animated];
    
    if (![self client])
    {
        [self performBlockingClientActionsWithBlock: nil
                          mainThreadCompletionBlock: nil];
    }
}

- (void) dealloc
{
    NSLog(@"%@.%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark - Class Methods

- (void) loadConfiguration
{
    [self setHarmonyConfiguration: [FSCDataSharingController loadHarmonyConfiguration]];
    
    [self loadCurrentActivity];
}

- (NSArray *) activities
{
    return [[self harmonyConfiguration] activity];
}

- (void) setHarmonyConfiguration: (FSCHarmonyConfiguration *) harmonyConfiguration
{
    _harmonyConfiguration = harmonyConfiguration;
    
    [[self activityCollectionView] reloadData];
}

- (void) loadCurrentActivity
{
    NSUserDefaults * standardDefaults = [NSUserDefaults standardUserDefaults];
    [standardDefaults synchronize];
    NSString * currentActivityIdentifier = [standardDefaults objectForKey: standardDefaultsKeyCurrentActivity];
    
    FSCActivity * currentActivity = [[self harmonyConfiguration] activityWithId: currentActivityIdentifier];
    
    [self setCurrentActivity: currentActivity];
    
    [self highlightCurrentActivity];
}

- (void) saveCurrentActivity
{
    NSUserDefaults * standardDefaults = [NSUserDefaults standardUserDefaults];
    [standardDefaults setObject: [[self currentActivity] activityIdentifier]
                         forKey: standardDefaultsKeyCurrentActivity];
    [standardDefaults synchronize];
}


- (void) performBlockingClientActionsWithBlock: (void (^)(FSCHarmonyClient * client))actionsBlock
                     mainThreadCompletionBlock: (void (^)(void))completionBlock
{
    [self prepareForBlockingClientAction];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSError * error = nil;
        BOOL clientSetupEndedCalled = NO;
        
        @try
        {
            if (![self client])
            {
                NSString * username;
                NSString * password;
                NSString * IPAddress;
                NSUInteger port;
                
                [FSCDataSharingController loadUsername: &username
                                              password: &password
                                             IPAddress: &IPAddress
                                                  port: &port];
                
                if (username &&
                    password &&
                    IPAddress)
                {
                    [self clientSetupBegan];
                    
                    [self setClient: [FSCHarmonyClient clientWithMyHarmonyUsername: username
                                                                 myHarmonyPassword: password
                                                               harmonyHubIPAddress: IPAddress
                                                                    harmonyHubPort: port]];
                    
                    [[self client] setConfiguration: [self harmonyConfiguration]];
                    
                    [[NSNotificationCenter defaultCenter] addObserver: self
                                                             selector: @selector(handleFSCHarmonyClientCurrentActivityChangedNotification:)
                                                                 name: FSCHarmonyClientCurrentActivityChangedNotification
                                                               object: [self client]];
                    
                    [[self client] currentActivityFromConfiguration: [self harmonyConfiguration]];
                    
                    [self clientSetupEnded];
                    clientSetupEndedCalled = YES;
                }
                else if (username ||
                         password ||
                         IPAddress)
                {
                    @throw [NSException exceptionWithName: FSCExceptionCredentials
                                                   reason: [NSString stringWithFormat:
                                                            NSLocalizedString(@"FSCHARMONYVIEWCONTROLLER-CONNECTION_ERROR-CREDENTIALS", nil),
                                                            username ? username : NSLocalizedString(@"FSCHARMONYVIEWCONTROLLER-CONNECTION_ERROR-CREDENTIALS-EMPYT", nil),
                                                            password ? @"******" : NSLocalizedString(@"FSCHARMONYVIEWCONTROLLER-CONNECTION_ERROR-CREDENTIALS-EMPYT", nil),
                                                            IPAddress ? IPAddress : NSLocalizedString(@"FSCHARMONYVIEWCONTROLLER-CONNECTION_ERROR-CREDENTIALS-EMPYT", nil)]
                                                 userInfo: nil];
                }
                else
                {
                    @throw [NSException exceptionWithName: FSCExceptionSetup
                                                   reason: NSLocalizedString(@"FSCHARMONYVIEWCONTROLLER-CONNECTION_ERROR-SETUP", nil)
                                                 userInfo: nil];
                }
            }
            else if (![[self client] isConnected])
            {
                [[self client] connect];
            }
            
            if (actionsBlock)
            {
                actionsBlock([self client]);
            }
        }
        @catch (NSException * exception)
        {
            NSString * errorDescription = [exception reason];
            NSInteger errorCode = FSCErrorCodeErrorPerformingClientAction;
            
            if ([[exception name] isEqualToString: FSCExceptionSetup] ||
                [[exception name] isEqualToString: FSCExceptionCredentials] ||
                [[exception name] isEqualToString: FSCExceptionMyHarmonyConnection])
            {
                errorDescription = @"Could not connect to My Harmony with the provided credentials.\n\nPlease verify that your username and password are correct.";
                
                if ([[exception name] isEqualToString: FSCExceptionSetup])
                {
                    errorCode = FSCErrorCodeMissingSetup;
                }
                else if ([[exception name] isEqualToString: FSCExceptionCredentials])
                {
                    errorCode = FSCErrorCodeMissingCredentials;
                }
            }
            else if ([[exception name] isEqualToString: FSCExceptionHarmonyHubConnection])
            {
                errorDescription = @"Could not connect to Harmony Hub with the provided IP address and port.";
            }
            
            NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                              errorDescription, NSLocalizedDescriptionKey,
                                              nil];
            
            NSError * originalError = nil;
            
            if ([exception userInfo] &&
                (originalError = [[exception userInfo] objectForKey: FSCErrorUserInfoKeyOriginalError]))
            {
                userInfo[FSCErrorUserInfoKeyOriginalError] = [originalError localizedDescription];
            }
            
            error = [NSError errorWithDomain: FSCErrorDomain
                                        code: errorCode
                                    userInfo: userInfo];
        }
        @finally
        {
            if (!clientSetupEndedCalled)
            {
                [self clientSetupEnded];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (completionBlock)
            {
                completionBlock();
            }
            
            [self cleanupAfterBlockingClientActionWithError: error];
        });
    });
}

- (void) clientSetupBegan
{
    
}

- (void) clientSetupEnded
{
    
}

- (void) handleClient: (FSCHarmonyClient *) client
currentActivityChanged: (FSCActivity *) newActivity
{
    [self setCurrentActivity: newActivity];
    
    [self saveCurrentActivity];
    
    [self highlightCurrentActivity];
}

- (void) highlightCurrentActivity
{
    [[self activities] enumerateObjectsUsingBlock:^(FSCActivity * anActivity, NSUInteger idx, BOOL *stop) {
        
        if ([[anActivity activityIdentifier] isEqualToString: [[self currentActivity] activityIdentifier]])
        {
            [[self activityCollectionView] reloadItemsAtIndexPaths: @[[NSIndexPath indexPathForItem: idx
                                                                                          inSection: 0]]];
        }
    }];
}

- (void) prepareForBlockingClientAction
{
    
}

- (void) cleanupAfterBlockingClientActionWithError: (NSError *) error
{
    
}

#pragma mark - UICollectionViewDatasource

- (NSInteger) collectionView: (UICollectionView *) collectionView
      numberOfItemsInSection: (NSInteger) section
{
    NSInteger count = 0;
    
    if ([self harmonyConfiguration])
    {
        count = [[self activities] count];
    }
    
    return count;
}

- (UICollectionViewCell *) collectionView: (UICollectionView *) collectionView
                   cellForItemAtIndexPath: (NSIndexPath *) indexPath
{
    FSCActivityCollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier: FSCActtivityCellIdentifier
                                                                                     forIndexPath: indexPath];
    
    FSCActivity * activity = [self activities][[indexPath item]];
    
    if ([[activity activityIdentifier] isEqualToString: [[self currentActivity] activityIdentifier]])
    {
        [cell setActivity: activity
            withMaskColor: [self inverseColorForActivityMask]
          backgroundColor: [self backgroundColorForInverseActivityMask]];
    }
    else
    {
        [cell setActivity: activity
            withMaskColor: [self colorForActivityMask]
          backgroundColor: [self backgroundColorForActivityMask]];
    }
    
    return cell;
}

- (UIColor *) colorForActivityMask
{
    return [UIColor blackColor];
}

- (UIColor *) backgroundColorForActivityMask
{
    return [UIColor clearColor];
}

- (UIColor *) inverseColorForActivityMask
{
    return [UIColor whiteColor];
}

- (UIColor *) backgroundColorForInverseActivityMask
{
    return [UIColor blackColor];
}

#pragma mark - UICollectionViewDelegate

- (void) collectionView:(UICollectionView *) collectionView
didSelectItemAtIndexPath: (NSIndexPath *) indexPath
{
    FSCActivity * activity = [self activities][[indexPath item]];
    
    [self performBlockingClientActionsWithBlock:^(FSCHarmonyClient *client) {
        
        [client startActivity: activity];
    }
                      mainThreadCompletionBlock: nil];
}

#pragma mark - Notification Handling

- (void) handleFSCHarmonyClientCurrentActivityChangedNotification: (NSNotification *) note
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self handleClient: [note object]
    currentActivityChanged: [[note userInfo] objectForKey: FSCHarmonyClientCurrentActivityChangedNotificationActivityKey]];
    });
}

@end
