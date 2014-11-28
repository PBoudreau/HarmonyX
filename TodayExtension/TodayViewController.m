//
//  TodayViewController.m
//  TodayExtension
//
//  Created by Philippe Boudreau on 2014-11-05.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

#import "FSCHarmonyCommon.h"
#import "FSCDataSharingController.h"
#import "FSCControlGroup.h"

static CGFloat const activityCellDim = 75.0;

@interface TodayViewController () <NCWidgetProviding>
{
    BOOL playToggle;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *activityCollectionViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *staticActivitiesView;

@property (weak, nonatomic) IBOutlet UIView *volumeView;

@property (weak, nonatomic) IBOutlet UIView *transportView;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *playPauseTapGesture;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *forwardDoubleTapGesture;
@property (strong, nonatomic) IBOutlet UILongPressGestureRecognizer *backLongPressGesture;

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
    
    playToggle = NO;
    
    [[self playPauseTapGesture] requireGestureRecognizerToFail: [self forwardDoubleTapGesture]];
    [[self playPauseTapGesture] requireGestureRecognizerToFail: [self backLongPressGesture]];
    
    [[self volumeView] setAlpha: 0.0];
    [[self transportView] setAlpha: 0.0];
    
    [self loadConfiguration];
}

- (void) viewDidAppear: (BOOL) animated
{
    [super viewDidAppear: animated];
    
    if ([self client])
    {
        [[self client] connect];
    }
}

- (void) viewDidDisappear: (BOOL) animated
{
    [super viewDidDisappear: animated];
    
    if ([self client])
    {
        [[self client] disconnect];
    }
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
        NSString * originalError = nil;
        
        if ([error userInfo] &&
            (originalError = [[error userInfo] objectForKey: FSCErrorUserInfoKeyOriginalError]) &&
            ([originalError isEqualToString: FSCErrorHarmonyXMPPNetworkUnreachable] ||
             [originalError isEqualToString: FSCErrorHarmonyXMPPConnectionRefused]))
        {
            [[self activityIndicatorView] stopAnimating];
            [self setHarmonyConfiguration: nil];
         
            if ([originalError isEqualToString: FSCErrorHarmonyXMPPNetworkUnreachable])
            {
                statusLabelText = @"No network connectivity available.";
            }
            else
            {
                statusLabelText = @"No Harmony Hub found on network.";
            }
        }
        else
        {
            statusLabelText = [error localizedDescription];
        }
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
        FSCControlGroup * transportBasicControlGroup = [currentActivity transportBasicControlGroup];
        FSCControlGroup * transportExtendedControlGroup = [currentActivity transportExtendedControlGroup];
        
        [UIView animateWithDuration: 0.5
                         animations: ^{
                             
                             [[self volumeView] setAlpha: volumeControlGroup ? 1.0 : 0.0];
                             [[self transportView] setAlpha: (transportBasicControlGroup || transportExtendedControlGroup) ? 1.0 : 0.0];
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

- (IBAction) playPauseTapped: (id) sender
{
    [self executeFunction: ^FSCFunction *(FSCActivity *currentActivity) {
        
        FSCControlGroup * controlGroup = [currentActivity transportBasicControlGroup];
        
        FSCFunction * function = playToggle ? [controlGroup playFunction] : [controlGroup pauseFunction];
        
        return function;
    }];
}

- (IBAction) forwardTapped: (id) sender
{
    [self executeFunction: ^FSCFunction *(FSCActivity *currentActivity) {
        
        return [[currentActivity transportExtendedControlGroup] skipForwardFunction];
    }];
}

- (IBAction) backwardTapped: (UILongPressGestureRecognizer *) sender
{
    if ([sender state] == UIGestureRecognizerStateEnded)
    {
        [self executeFunction: ^FSCFunction *(FSCActivity *currentActivity) {
            
            return [[currentActivity transportExtendedControlGroup] skipBackwardFunction];
        }];
    }
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
