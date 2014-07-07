//
//  VYBPlayerViewController.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 6..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "VYBCaptureViewController.h"

@class VYBPlayerView;

@interface VYBPlayerViewController : UIViewController <VYBCaptureViewControllerDelegate>
@property (nonatomic, strong) id parentVC;

@property (nonatomic) AVPlayer *currPlayer;
@property (nonatomic) VYBPlayerView *currPlayerView;
@property (nonatomic) AVPlayerItem *currItem;
@property (nonatomic,strong) NSArray *vybePlaylist;
@property (nonatomic) NSInteger debugMode;

+ (VYBPlayerViewController *)playerViewControllerForPageIndex:(NSInteger)idx;
- (NSInteger)pageIndex;
- (void)beginPlayingFrom:(NSInteger)from;

@end
