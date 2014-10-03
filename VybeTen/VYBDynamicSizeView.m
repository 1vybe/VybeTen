//
//  VYBDynamicSizeView.m
//  VybeTen
//
//  Created by jinsuk on 9/24/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBDynamicSizeView.h"
#import <AVFoundation/AVFoundation.h>

@implementation VYBDynamicSizeView {
    NSInteger _orientation;
}

- (CGSize)intrinsicContentSize {
    CGSize size;
    if (UIDeviceOrientationIsLandscape(_orientation)) {
        size = CGSizeMake([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    } else {
        size = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    }
    return size;
}

- (void)setOrientation:(UIDeviceOrientation)orientation {
    _orientation = orientation;
    
    self.transform = CGAffineTransformIdentity;
    
    if (UIDeviceOrientationIsLandscape(orientation)) {
        CGAffineTransform rotation = CGAffineTransformMakeRotation(M_PI_2);
        self.transform = rotation;
    }
}


@end
