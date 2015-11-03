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

@implementation FSCHarmonyViewController

#pragma mark - Superclass Methods

- (void) viewDidLoad
{
    [self setHarmonyController: [FSCHarmonyController new]];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleFSCHarmonyControllerClientSetupBeganNotification:)
                                                 name: FSCHarmonyControllerClientSetupBeganNotification
                                               object: [self harmonyController]];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleFSCHarmonyControllerClientSetupEndedNotification:)
                                                 name: FSCHarmonyControllerClientSetupEndedNotification
                                               object: [self harmonyController]];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleFSCHarmonyControllerConfigurationChangedNotification:)
                                                 name: FSCHarmonyControllerConfigurationChangedNotification
                                               object: [self harmonyController]];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleFSCHarmonyControllerCurrentActivityChangedNotification:)
                                                 name: FSCHarmonyControllerCurrentActivityChangedNotification
                                               object: [self harmonyController]];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleFSCHarmonyControllerClientActionCompletedNotification:)
                                                 name: FSCHarmonyControllerClientActionCompletedNotification
                                               object: [self harmonyController]];
}

- (void) viewDidAppear: (BOOL) animated
{
    [super viewDidAppear: animated];
    
    if (![[self harmonyController] client])
    {
        [self performBlockingClientActionsWithBlock: nil
                          mainThreadCompletionBlock: nil];
    }
}

- (void) dealloc
{
    ALog(@"%@.%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark - Class Methods

- (NSArray *) activities
{
    return [[self harmonyController] activities];
}

- (void) harmonyConfigurationChanged
{
    [[self activityCollectionView] reloadData];
}

- (void) currentActivityChanged: (FSCActivity *) newActivity
{
    [self highlightCurrentActivity];
}

- (void) performBlockingClientActionsWithBlock: (void (^)(FSCHarmonyClient * client))actionsBlock
                     mainThreadCompletionBlock: (void (^)(void))completionBlock
{
    [self prepareForBlockingClientAction];
    
    [[self harmonyController] performClientActionsWithBlock: actionsBlock
                                  mainThreadCompletionBlock: completionBlock];
}

- (void) clientSetupBegan
{
    
}

- (void) clientSetupEnded
{
    
}

- (void) highlightCurrentActivity
{
    [[self activityCollectionView] reloadData];
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
    
    if ([[self harmonyController] harmonyConfiguration])
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
    
    if ([[activity activityIdentifier] isEqualToString: [[[self harmonyController] currentActivity] activityIdentifier]])
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

- (void) handleFSCHarmonyControllerClientSetupBeganNotification: (NSNotification *) note
{
    [self clientSetupBegan];
}

- (void) handleFSCHarmonyControllerClientSetupEndedNotification: (NSNotification *) note
{
    [self clientSetupEnded];
}

- (void) handleFSCHarmonyControllerConfigurationChangedNotification: (NSNotification *) note
{
    [self harmonyConfigurationChanged];
}

- (void) handleFSCHarmonyControllerCurrentActivityChangedNotification: (NSNotification *) note
{
    FSCActivity * newActivity = [note userInfo][FSCHarmonyClientCurrentActivityChangedNotificationActivityKey];
    
    [self currentActivityChanged: newActivity];
}

- (void) handleFSCHarmonyControllerClientActionCompletedNotification: (NSNotification *) note
{
    NSError * error = [note userInfo][FSCHarmonyControllerClientActionCompletedErrorKey];
    
    [self cleanupAfterBlockingClientActionWithError: error];
}

@end
