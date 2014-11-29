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

@end

@implementation FSCActivityCollectionViewCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    [[self layer] setCornerRadius: 5.0];
}

- (void) setActivity: (FSCActivity *) activity
       withMaskColor: (UIColor *) maskColor
     backgroundColor: (UIColor *) backgroundColor
{
    _activity = activity;
    
    [[self activityName] setText: [_activity label]];
    [[self activityImageView] setImage: [_activity maskedImageWithColor: maskColor]];
    
    [self setBackgroundColor: backgroundColor];
    [[self activityName] setTextColor: maskColor];
}

@end
