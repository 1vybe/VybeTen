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
    [playerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
}

- (void)resetFrame {
    self.transform = CGAffineTransformIdentity;
    [self setBounds:[[UIScreen mainScreen] bounds]];
}

- (CGSize)intrinsicContentSize {
    CGSize size;
    if (_orientation == AVCaptureVideoOrientationLandscapeLeft || _orientation == AVCaptureVideoOrientationLandscapeRight) {
        size = CGSizeMake([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    } else {
        size = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    }
    return size;
}

- (void)setOrientation:(AVCaptureVideoOrientation)orientation {
    _orientation = orientation;

    //self.transform = CGAffineTransformIdentity;
    [self resetFrame];
    
    if (orientation == AVCaptureVideoOrientationLandscapeLeft || orientation == AVCaptureVideoOrientationLandscapeRight) {
        CGAffineTransform rotation = CGAffineTransformMakeRotation(M_PI_2);
        self.transform = rotation;
        
        CGRect newBounds = CGRectMake(0, 0,
                                      [[UIScreen mainScreen] bounds].size.height,
                                      [[UIScreen mainScreen] bounds].size.width);
        [self setBounds:newBounds];
    }
}


@end
