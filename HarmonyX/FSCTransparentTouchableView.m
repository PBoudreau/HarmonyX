//
//  FSCTransparentTouchableView.m
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-11-27.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import "FSCTransparentTouchableView.h"

// This class was created solely to support receiving touch handling on a view
// with clear background color.
@implementation FSCTransparentTouchableView

- (void) drawRect: (CGRect) rect
{
    // Intentionally left blank: if not implemented, touch events are not received.
}

@end
