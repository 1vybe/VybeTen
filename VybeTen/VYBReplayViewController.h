//
//  VYBReplayViewController.h
//  VybeTen
//
//  Created by jinsuk on 7/11/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class VYBPlayerView;
@class VYBMyVybe;

@interface VYBReplayViewController : UIViewController
@property (nonatomic) AVPlayer *player;
@property (nonatomic) VYBPlayerView *playerView;
@property (nonatomic) AVPlayerItem *currItem;
@property (nonatomic) VYBMyVybe *currVybe;

@property (nonatomic) BOOL isPublic;

@end
