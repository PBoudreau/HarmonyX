//
//  FSCHarmonyViewController.h
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-11-10.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FSCHarmonyClient.h"
#import "FSCHarmonyConfiguration.h"

@interface FSCHarmonyViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@end

@interface FSCHarmonyViewController ()

@property (weak, nonatomic) IBOutlet UICollectionView *activityCollectionView;

@property (strong, nonatomic) FSCHarmonyClient * client;
@property (strong, nonatomic) FSCHarmonyConfiguration * harmonyConfiguration;

- (void) loadConfiguration;
- (NSArray *) activities;

- (void) performBlockingClientActionsWithBlock: (void (^)(FSCHarmonyClient * client))actionsBlock
                     mainThreadCompletionBlock: (void (^)(void))completionBlock;
- (void) prepareForBlockingClientAction;
- (void) clientSetupBegan;
- (void) clientSetupEnded;
- (void) cleanupAfterBlockingClientActionWithError: (NSError *) error;

- (UIColor *) colorForActivityMask;
- (UIColor *) backgroundColorForActivityMask;
- (UIColor *) inverseColorForActivityMask;
- (UIColor *) backgroundColorForInverseActivityMask;

- (void) handleCurrentActivityChanged: (FSCActivity *) newActivity;

@end