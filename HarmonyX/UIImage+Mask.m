//
//  UIImage+Mask.m
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-11-10.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import "UIImage+Mask.h"

@implementation UIImage (Mask)

- (UIImage *) convertToInverseMaskWithColor: (UIColor *) color
{
    CGRect rect = CGRectMake(0, 0, [self size].width, [self size].height);
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, self.scale);
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    // Draw a background in the appropriate color (for mask)
    CGContextSetFillColorWithColor(c, [color CGColor]);
    CGContextFillRect(c, rect);
    
    // Apply the source image's alpha
    [self drawInRect: rect
           blendMode: kCGBlendModeDestinationOut
               alpha: 1.0f];
    
    UIImage * result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}

@end
