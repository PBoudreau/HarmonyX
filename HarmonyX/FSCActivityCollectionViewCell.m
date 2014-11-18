//
//  FSCActivityCollectionViewCell.m
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-11-09.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import "FSCActivityCollectionViewCell.h"

@interface FSCActivityCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *activityImageView;
@property (weak, nonatomic) IBOutlet UILabel *activityName;

@property (nonatomic, strong) FSCActivity * activity;

@end

@implementation FSCActivityCollectionViewCell

- (void) setActivity: (FSCActivity *) activity
       withMaskColor: (UIColor *) color
{
    _activity = activity;
    
    [[self activityName] setText: [_activity label]];
    [[self activityImageView] setImage: [_activity maskedImageWithColor: color]];
}

@end
