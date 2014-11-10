//
//  UIImage+Mask.m
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-11-10.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import "UIImage+Mask.h"

@implementation UIImage (Mask)

- (UIImage *) maskedImageWithColor: (UIColor *) color
{
    CGRect rect = CGRectMake(0, 0, [self size].width, [self size].height);
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, self.scale);
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    [self drawInRect: rect];
    
    CGContextSetFillColorWithColor(c, [color CGColor]);
    CGContextSetBlendMode(c, kCGBlendModeSourceAtop);
    CGContextFillRect(c, rect);
    
    UIImage * result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}

@end
