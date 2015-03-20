//
//  VYBPlayerView.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 4..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface VYBPlayerView : UIView
@property (nonatomic) AVPlayer *player;
- (void)setVideoFillMode;
- (void)setOrientation:(AVCaptureVideoOrientation)orientation;
- (void)resetFrame;
@end
