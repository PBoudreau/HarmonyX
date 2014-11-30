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
#import "UIImage+Mask.h"

static CGFloat const activityCellDim = 75.0;

static NSArray * viewsForStatePreservation = nil;

static NSString * const standardDefaultsKeyViewStatePreservationAlpha = @"viewStatePreservation-alpha-";

@interface TodayViewController () <NCWidgetProviding>
{
    BOOL playToggle;
}

@property (weak, nonatomic) IBOutlet UICollectionView *activityCollectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *activityCollectionViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *staticActivitiesView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *staticActivitiesViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *volumeView;
@property (weak, nonatomic) IBOutlet UIButton *volumeDownButton;
@property (weak, nonatomic) IBOutlet UIButton *volumeUpButton;

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
    
    for (UIView * aView in @[[self volumeDownButton],
                             [self volumeUpButton],
                             [self transportView]])
    {
        [[aView layer] setCornerRadius: 5.0];
        [[aView layer] setBorderWidth: 1.0];
        [[aView layer] setBorderColor: [[UIColor whiteColor] CGColor]];
    }
    
    playToggle = NO;
    
    [[self playPauseTapGesture] requireGestureRecognizerToFail: [self forwardDoubleTapGesture]];
    [[self playPauseTapGesture] requireGestureRecognizerToFail: [self backLongPressGesture]];
    
    UIImage * powerOffImage = [UIImage imageNamed: @"activity_powering_off"];
    UIImage * maskedPowerOffImage = [powerOffImage convertToInverseMaskWithColor: [self colorForActivityMask]];
    [[self powerOffIconImageView] setImage: maskedPowerOffImage];
    
    viewsForStatePreservation = @[@"staticActivitiesView",
                                  @"volumeView",
                                  @"transportView",
                                  @"powerOffView"];
    
    [self loadUIState];
    
    [self loadConfiguration];
    
    [self updateContentSize];
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
    
    [self saveUIState];
    
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
}

- (void) clientSetupBegan
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        [[self activityIndicatorView] startAnimating];
        [[self statusLabel] setText: @"Connecting..."];
    });
}

- (void) clientSetupEnded
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        [[self activityIndicatorView] stopAnimating];
        [[self statusLabel] setText: nil];
    });
}

- (void) handleClient: (FSCHarmonyClient *) client
currentActivityChanged: (FSCActivity *) newActivity
{
    [super handleClient: client
 currentActivityChanged: newActivity];
    
    [self updateUIForCurrentActivity: newActivity];
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
        else if ([error code] == FSCErrorCodeMissingSetup)
        {
            statusLabelText = @"Please use the app to load activities.";
        }
        else if ([error code] == FSCErrorCodeMissingCredentials)
        {
            statusLabelText = @"Please use the app to provide valid credentials and IP address.";
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

- (UIColor *) inverseColorForActivityMask
{
    return [UIColor blackColor];
}

- (UIColor *) backgroundColorForInverseActivityMask
{
    return [UIColor whiteColor];
}

#pragma mark - Class Methods

- (void) loadUIState
{
    NSUserDefaults * standardDefaults = [NSUserDefaults standardUserDefaults];
    [standardDefaults synchronize];
    
    [viewsForStatePreservation enumerateObjectsUsingBlock: ^(NSString * viewPropertyName, NSUInteger idx, BOOL *stop) {
        
        SEL selector = NSSelectorFromString(viewPropertyName);
        IMP imp = [self methodForSelector:selector];
        UIView * (*func)(id, SEL) = (void *)imp;
        UIView * view = func(self, selector);
        
        NSAssert(view,
                 @"Could not find a property with name '%@' on '%@",
                 view,
                 NSStringFromClass([self class]));
        
        NSNumber * alphaNum = [standardDefaults objectForKey: [NSString stringWithFormat:
                                                               @"%@%@",
                                                               standardDefaultsKeyViewStatePreservationAlpha,
                                                               viewPropertyName]];
        
        CGFloat newAlpha = 0.0;
        
        if (alphaNum)
        {
            newAlpha = [alphaNum floatValue];
        }
        
        [view setAlpha: newAlpha];
    }];
}

- (void) saveUIState
{
    NSUserDefaults * standardDefaults = [NSUserDefaults standardUserDefaults];
    
    [viewsForStatePreservation enumerateObjectsUsingBlock: ^(NSString * viewPropertyName, NSUInteger idx, BOOL *stop) {
        
        SEL selector = NSSelectorFromString(viewPropertyName);
        IMP imp = [self methodForSelector:selector];
        UIView * (*func)(id, SEL) = (void *)imp;
        UIView * view = func(self, selector);
        
        NSAssert(view,
                 @"Could not find a property with name '%@' on '%@",
                 view,
                 NSStringFromClass([self class]));
        
        [standardDefaults setObject: [NSNumber numberWithFloat: [view alpha]]
                             forKey: [NSString stringWithFormat:
                                      @"%@%@",
                                      standardDefaultsKeyViewStatePreservationAlpha,
                                      viewPropertyName]];
    }];
    
    [standardDefaults synchronize];
}

- (void) updateContentSize
{
    CGRect viewBounds = [[self view] bounds];
    
    CGFloat numCellsPerRow = viewBounds.size.width / activityCellDim;
    
    CGFloat numRows = 0;
    
    if ([self harmonyConfiguration])
    {
        numRows = ceilf(([[[self harmonyConfiguration] activity] count] - 1) / numCellsPerRow);
    }

    CGFloat collectionViewHeight = numRows * activityCellDim;
    
    [[self activityCollectionViewHeightConstraint] setConstant: collectionViewHeight];
    
    [[self staticActivitiesViewHeightConstraint] setConstant: ([[self staticActivitiesView] alpha] == 0.0) ? 0.0 : activityCellDim];
}

- (void) updateUIForCurrentActivity: (FSCActivity *) currentActivity
{
    FSCControlGroup * volumeControlGroup = [currentActivity volumeControlGroup];
    FSCControlGroup * transportBasicControlGroup = [currentActivity transportBasicControlGroup];
    FSCControlGroup * transportExtendedControlGroup = [currentActivity transportExtendedControlGroup];
    
    BOOL powerOffActivityHidden = [[[currentActivity label] lowercaseString] isEqualToString: @"poweroff"];
    
    if (!powerOffActivityHidden)
    {
        FSCActivity * powerOffActivity = [[[self harmonyConfiguration] activity] lastObject];
        
        if ([[[powerOffActivity label] lowercaseString] isEqualToString: @"poweroff"])
        {
            [[self powerOffIconImageView] setImage: [powerOffActivity maskedImageWithColor: [self colorForActivityMask]]];
            [[self powerOffLabel] setText: [powerOffActivity label]];
        }
        else
        {
            powerOffActivityHidden = YES;
        }
    }
    
    [[self view] layoutIfNeeded];
    
    [UIView animateWithDuration: 0.5
                     animations: ^{
                         
                         [[self staticActivitiesView] setAlpha: (volumeControlGroup ||
                                                                 transportBasicControlGroup ||
                                                                 transportExtendedControlGroup ||
                                                                 !powerOffActivityHidden) ? 1.0 : 0.0];
                         [[self volumeView] setAlpha: volumeControlGroup ? 1.0 : 0.0];
                         [[self transportView] setAlpha: (transportBasicControlGroup || transportExtendedControlGroup) ? 1.0 : 0.0];
                         [[self powerOffView] setAlpha: powerOffActivityHidden ? 0.0 : 1.0];
                     }
     completion: ^(BOOL finished) {
         
         [UIView animateWithDuration: 0.5
                          animations: ^{
                              
                              [self updateContentSize];
                              
                              [[self view] layoutIfNeeded];
                          }];
     }];
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
        
        playToggle = !playToggle;
        
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
