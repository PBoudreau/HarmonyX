//
//  TodayViewController.m
//  TodayExtension
//
//  Created by Philippe Boudreau on 2014-11-05.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

#import "FSCDataSharingController.h"
#import "FSCControlGroup.h"

static CGFloat const activityCellDim = 75.0;

@interface TodayViewController () <NCWidgetProviding>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *activityCollectionViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *staticActivitiesView;

@property (weak, nonatomic) IBOutlet UIView *volumeView;

@property (weak, nonatomic) IBOutlet UIView *powerOffView;
@property (weak, nonatomic) IBOutlet UIImageView *powerOffIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *powerOffLabel;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;

@end

@implementation TodayViewController

#pragma mark - Superclass Methods

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    [self loadConfiguration];
}

- (UIEdgeInsets) widgetMarginInsetsForProposedMarginInsets: (UIEdgeInsets) defaultMarginInsets
{
    return UIEdgeInsetsZero;
}

- (void) setHarmonyConfiguration: (FSCHarmonyConfiguration *) harmonyConfiguration
{
    [super setHarmonyConfiguration: harmonyConfiguration];

    NSString * statusLabelText = @"";
    
    if (![self harmonyConfiguration])
    {
        statusLabelText = @"Please use the app to load activities.";
    }
    
    [[self statusLabel] setText: statusLabelText];
    
    [self updatePreferredContentSize];
    
    FSCActivity * powerOffActivity = [[[self harmonyConfiguration] activity] lastObject];
    
    if ([[[powerOffActivity label] lowercaseString] isEqualToString: @"poweroff"])
    {
        [[self powerOffView] setHidden: NO];
        [[self powerOffIconImageView] setImage: [powerOffActivity maskedImageWithColor: [self colorForActivityMask]]];
        [[self powerOffLabel] setText: [powerOffActivity label]];
    }
    else
    {
        [[self powerOffView] setHidden: YES];
    }
}

- (void) clientSetupBegan
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        [[self activityIndicatorView] startAnimating];
    });
}

- (void) clientSetupEnded
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        [[self activityIndicatorView] stopAnimating];
    });
}

- (void) handleClient: (FSCHarmonyClient *) client
currentActivityChanged: (FSCActivity *) newActivity
{
    [self updateUIForCurrentActivity];
}

- (void) prepareForBlockingClientAction
{
    [super prepareForBlockingClientAction];
    
    [[self view] setUserInteractionEnabled: NO];
}

- (void) cleanupAfterBlockingClientActionWithError: (NSError *) error
{
    [super cleanupAfterBlockingClientActionWithError: error];
    
    NSString * statusLabelText = nil;
    
    if (error)
    {
        statusLabelText = [error localizedDescription];
    }
    
    [[self statusLabel] setText: statusLabelText];
    
    [[self view] setUserInteractionEnabled: YES];
}

- (UIColor *) colorForActivityMask
{
    return [UIColor whiteColor];
}

#pragma mark - Class Methods

- (void) updatePreferredContentSize
{
    CGRect viewBounds = [[self view] bounds];
    
    CGFloat numCellsPerRow = viewBounds.size.width / activityCellDim;
    
    CGFloat numRows = 0;
    
    if ([self harmonyConfiguration])
    {
        numRows = ceilf(([[[self harmonyConfiguration] activity] count] - 1) / numCellsPerRow);
    }

    CGFloat collectionViewHeight = numRows * [[self activityCollectionView] bounds].size.height;
    
    CGFloat extensionHeight = collectionViewHeight + [[self statusLabel] bounds].size.height;
    
    if (collectionViewHeight > 0.0)
    {
        extensionHeight += [[self staticActivitiesView] bounds].size.height;
    }
    
    [self setPreferredContentSize: CGSizeMake(0.0, extensionHeight)];
    
    [[self activityCollectionViewHeightConstraint] setConstant: collectionViewHeight];
    
    [[self staticActivitiesView] setHidden: (collectionViewHeight == 0.0)];
}

- (void) updateUIForCurrentActivity
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        FSCActivity * currentActivity = [[self client] currentActivityFromConfiguration: [self harmonyConfiguration]];
        
        FSCControlGroup * volumeControlGroup = [currentActivity volumeControlGroup];
        
        [UIView animateWithDuration: 0.5
                         animations: ^{
                             
                             [[self volumeView] setAlpha: volumeControlGroup ? 1.0 : 0.0];
                         }];
    });
}

- (IBAction) powerOffTapped: (id) sender
{
    [[self statusLabel] setText: @"Powering off..."];
    
    [self performBlockingClientActionsWithBlock:^(FSCHarmonyClient *client) {
        
        [client turnOff];
    }
                      mainThreadCompletionBlock: nil];
}

- (void) executeFunction: (FSCFunction * (^)(FSCActivity * currentActivity))functionBlock
{
    [self performBlockingClientActionsWithBlock: ^(FSCHarmonyClient *client) {
        
        FSCActivity * currentActivity = [client currentActivityFromConfiguration: [self harmonyConfiguration]];
        
        FSCFunction * function = functionBlock(currentActivity);
        
        if (function)
        {
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                [[self statusLabel] setText: [NSString stringWithFormat:
                                              @"%@...",
                                              [function label]]];
            });
            
            [client executeFunction: function
                           withType: FSCHarmonyClientFunctionTypePress];
        }
    }
     mainThreadCompletionBlock: nil];
}

- (IBAction) volumeDownTapped: (id) sender
{
    [self executeFunction: ^FSCFunction *(FSCActivity *currentActivity) {
        
        return [[currentActivity volumeControlGroup] volumeDownFunction];
    }];
}

- (IBAction) volumeUpTapped: (id) sender
{
    [self executeFunction: ^FSCFunction *(FSCActivity *currentActivity) {
        
        return [[currentActivity volumeControlGroup] volumeUpFunction];
    }];
}

#pragma mark - UICollectionViewDatasource

- (NSInteger) collectionView: (UICollectionView *) collectionView
      numberOfItemsInSection: (NSInteger) section
{
    return [super collectionView: collectionView
          numberOfItemsInSection: section] - 1;
}

#pragma mark - UICollectionViewDelegate

- (void) collectionView:(UICollectionView *) collectionView
didSelectItemAtIndexPath: (NSIndexPath *) indexPath
{
    FSCActivity * activity = [[self harmonyConfiguration] activity][[indexPath item]];
    
    [[self statusLabel] setText: [NSString stringWithFormat:
                                  @"Starting %@...",
                                  [activity label]]];
    
    [super collectionView: collectionView
 didSelectItemAtIndexPath: indexPath];
}

@end
