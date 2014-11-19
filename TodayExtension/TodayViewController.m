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

static CGFloat const activityCellDim = 75.0;

@interface TodayViewController () <NCWidgetProviding>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *activityCollectionViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *staticActivitiesView;

@property (weak, nonatomic) IBOutlet UIView *powerOffView;
@property (weak, nonatomic) IBOutlet UIImageView *powerOffIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *powerOffLabel;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

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

- (FSCHarmonyClient *) connectedClient
{
    NSString * username;
    NSString * password;
    NSString * IPAddress;
    NSUInteger port;
    
    [FSCDataSharingController loadUsername: &username
                                  password: &password
                                 IPAddress: &IPAddress
                                      port: &port];
    
    FSCHarmonyClient * client = [FSCHarmonyClient clientWithMyHarmonyUsername: username
                                                            myHarmonyPassword: password
                                                          harmonyHubIPAddress: IPAddress
                                                               harmonyHubPort: port];

    return client;
}

- (IBAction) powerOffTapped: (id) sender
{
    [self performBlockingClientActionsWithBlock:^(FSCHarmonyClient *client) {
        
        [client turnOff];
    }
                      mainThreadCompletionBlock: nil];
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
    
    NSString * statusLabelText;
    
    if ([[[activity label] lowercaseString] isEqualToString: @"poweroff"])
    {
        statusLabelText = @"Powering off...";
    }
    else
    {
        statusLabelText = [NSString stringWithFormat:
                           @"Starting %@...",
                           [activity label]];
    }
    
    [[self statusLabel] setText: statusLabelText];
    
    [super collectionView: collectionView
 didSelectItemAtIndexPath: indexPath];
}

@end
