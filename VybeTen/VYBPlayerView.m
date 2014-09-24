//
//  VYBPlayerView.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 4..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBPlayerView.h"

@implementation VYBPlayerView {
    AVCaptureVideoOrientation _orientation;
}
+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer *)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
    [self setVideoFillMode];
}

- (void)setVideoFillMode {
    AVPlayerLayer *playerLayer = (AVPlayerLayer *)[self layer];
    [playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
}

- (void)resetFrame {
    self.transform = CGAffineTransformIdentity;
    [self setBounds:[[UIScreen mainScreen] bounds]];
}

- (CGSize)intrinsicContentSize {
    CGSize size;

    if (_orientation == AVCaptureVideoOrientationLandscapeLeft || _orientation == AVCaptureVideoOrientationLandscapeRight) {
        size = CGSizeMake([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
        NSLog(@"landscape intrinsic size");
    } else {
        size = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        NSLog(@"portrait intrinsic size");
    }
    return size;
}

- (void)setOrientation:(AVCaptureVideoOrientation)orientation {
    _orientation = orientation;
    NSLog(@"orientation set");

    self.transform = CGAffineTransformIdentity;

    if (orientation == AVCaptureVideoOrientationLandscapeLeft || orientation == AVCaptureVideoOrientationLandscapeRight) {
        CGAffineTransform rotation = CGAffineTransformMakeRotation(M_PI_2);
        self.transform = rotation;
    }
}


@end
