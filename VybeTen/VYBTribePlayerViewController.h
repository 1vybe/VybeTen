//
//  VYBTribePlayerViewController.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 10..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class VYBPlayerView;

@interface VYBTribePlayerViewController : UIViewController
@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerItem *currItem;
@property (nonatomic) VYBPlayerView *playerView;
@property (nonatomic) UILabel *labelDate;
@property (nonatomic) UILabel *labelTime;

- (void)playFrom:(NSInteger)from;
- (void)captureVybe;
- (void)goToMenu;

@end
