//
//  VYBPlayerView.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 4..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBPlayerView.h"

@implementation VYBPlayerView

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


@end
