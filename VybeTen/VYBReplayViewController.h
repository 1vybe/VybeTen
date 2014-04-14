//
//  VYBReplayViewController.h
//  VybeTen
//
//  Created by jinsuk on 3/9/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AWSS3/AWSS3.h>

@class VYBPlayerView;
@class VYBVybe;

@interface VYBReplayViewController : UIViewController
@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerItem *playerItem;
@property (nonatomic) VYBPlayerView *playerView;
@property (nonatomic) UIButton *buttonSave;
@property (nonatomic) UIButton *buttonDiscard;
@property (nonatomic) UIButton *buttonCancel;
@property (nonatomic) UIImageView *instruction;
@property (nonatomic) VYBVybe *vybe;
@property (nonatomic) NSURL *replayURL;
@property (nonatomic) UIButton *syncButton;
@property (nonatomic) UILabel *syncLabel;

- (void)saveVybe;
- (void)discardVybe;
- (void)playVideo;

@end
