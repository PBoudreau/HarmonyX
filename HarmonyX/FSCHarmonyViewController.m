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

@implementation FSCHarmonyViewController

#pragma mark - Class Methods

- (void) loadConfiguration
{
    [self setHarmonyConfiguration: [FSCDataSharingController loadHarmonyConfiguration]];
}

- (void) setHarmonyConfiguration: (FSCHarmonyConfiguration *) harmonyConfiguration
{
    _harmonyConfiguration = harmonyConfiguration;
    
    [[self activityCollectionView] reloadData];
}

- (void) performBlockingClientActionsWithBlock: (void (^)(FSCHarmonyClient * client))actionsBlock
                     mainThreadCompletionBlock: (void (^)(void))completionBlock
{
    [self prepareForBlockingClientAction];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        FSCHarmonyClient * client = nil;
        NSError * error = nil;
        
        @try
        {
            NSString * username;
            NSString * password;
            NSString * IPAddress;
            NSUInteger port;
            
            [FSCDataSharingController loadUsername: &username
                                          password: &password
                                         IPAddress: &IPAddress
                                              port: &port];
            
            client = [FSCHarmonyClient clientWithMyHarmonyUsername: username
                                                 myHarmonyPassword: password
                                               harmonyHubIPAddress: IPAddress
                                                    harmonyHubPort: port];
            
            actionsBlock(client);
        }
        @catch (NSException * exception)
        {
            NSString * errorDescription = [exception reason];
            
            if ([[exception name] isEqualToString: FSCExceptionMyHarmonyConnection])
            {
                errorDescription = @"Could not connect to My Harmony with the provided credentials.\n\nPlease verify that your username and password are correct.";
            }
            else if ([[exception name] isEqualToString: FSCExceptionHarmonyHubConnection])
            {
                errorDescription = @"Could not connect to Harmony Hub with the provided IP address and port.";
            }
            
            error = [NSError errorWithDomain: FSCErrorDomain
                                        code: FSCErrorCodeErrorPerformingClientAction
                                    userInfo: @{NSLocalizedDescriptionKey: errorDescription}];
        }
        @finally
        {
            if (client)
            {
                [client disconnect];
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

- (void) prepareForBlockingClientAction
{
    
}

- (void) cleanupAfterBlockingClientActionWithError: (NSError *) error
{
    NSLog(@"%@: %@", NSStringFromSelector(_cmd), error);
}

#pragma mark - UICollectionViewDatasource

- (NSInteger) collectionView: (UICollectionView *) collectionView
      numberOfItemsInSection: (NSInteger) section
{
    NSInteger count = 0;
    
    if ([self harmonyConfiguration])
    {
        count = [[[self harmonyConfiguration] activity] count];
    }
    
    return count;
}

- (UICollectionViewCell *) collectionView: (UICollectionView *) collectionView
                   cellForItemAtIndexPath: (NSIndexPath *) indexPath
{
    FSCActivityCollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier: FSCActtivityCellIdentifier
                                                                                     forIndexPath: indexPath];
    
    FSCActivity * activity = [[self harmonyConfiguration] activity][[indexPath item]];
    
    [cell setActivity: activity
        withMaskColor: [self colorForActivityMask]];
    
    return cell;
}

- (UIColor *) colorForActivityMask
{
    return [UIColor whiteColor];
}

#pragma mark - UICollectionViewDelegate

- (void) collectionView:(UICollectionView *) collectionView
didSelectItemAtIndexPath: (NSIndexPath *) indexPath
{
    FSCActivity * activity = [[self harmonyConfiguration] activity][[indexPath item]];
    
    [self performBlockingClientActionsWithBlock:^(FSCHarmonyClient *client) {
        
        [client startActivity: activity];
    }
                      mainThreadCompletionBlock: nil];
}

@end
