//
//  VYBPlayerViewController.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 6..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class VYBPlayerView;

@interface VYBPlayerViewController : UIViewController
@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerItem *currItem;
@property (nonatomic) VYBPlayerView *playerView;
@property (nonatomic) UILabel *labelTime;
@property (nonatomic) NSMutableArray *vybePlaylist;

@property (nonatomic, copy) void (^dismissBlock)(NSInteger row);

- (void)playFrom:(NSInteger)index;
- (void)playFromUnwatched;

@end
