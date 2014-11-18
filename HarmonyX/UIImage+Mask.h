//
//  UIImage+Mask.h
//  HarmonyX
//
//  Created by Philippe Boudreau on 2014-11-10.
//  Copyright (c) 2014 Fasterre. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Mask)

- (UIImage *) convertToInverseMaskWithColor: (UIColor *) color;

@end
