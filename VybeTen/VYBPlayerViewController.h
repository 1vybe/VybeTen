//
//  VYBPlayerViewController.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 6..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "GAITrackedViewController.h"
#import "VYBCaptureViewController.h"

@class VYBPlayerView;

@interface VYBPlayerViewController : GAITrackedViewController <VYBCaptureViewControllerDelegate>
@property (nonatomic, strong) id parentVC;

@property (nonatomic) AVPlayer *currPlayer;
@property (nonatomic) VYBPlayerView *currPlayerView;
@property (nonatomic) AVPlayerItem *currItem;
@property (nonatomic,strong) NSArray *vybePlaylist;
@property (nonatomic) NSInteger debugMode;
@property (nonatomic) BOOL isPublicMode;

+ (VYBPlayerViewController *)playerViewControllerForPageIndex:(NSInteger)idx;
- (NSInteger)pageIndex;
- (void)setFreshVybe:(PFObject *)aVybe;
- (void)beginPlayingFrom:(NSInteger)from;

@end
