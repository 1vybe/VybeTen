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
@property (nonatomic) AVPlayer *currPlayer;
@property (nonatomic) VYBPlayerView *currPlayerView;
@property (nonatomic) AVPlayerItem *currItem;

@property (nonatomic) UILabel *labelTime;
@property (nonatomic, strong) NSArray *vybePlaylist;


@property (nonatomic) PFObject *vybe;


//@property (nonatomic, copy) void (^dismissBlock)(NSInteger row);

- (void)playFrom:(NSInteger)from;
- (void)playVybe:(PFObject *)aVybe;

@end
