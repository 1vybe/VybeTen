//
//  VYBPlayerViewController.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 6..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "MBProgressHUD.h"
#import "GAITrackedViewController.h"

@class VYBPlayerView;
@class VYBPlayerControlViewController;
@interface VYBPlayerViewController : GAITrackedViewController <UIAlertViewDelegate, MBProgressHUDDelegate>

@property (nonatomic, weak) VYBPlayerControlViewController *playerController;
@property (nonatomic, weak) VYBPlayerView *currPlayerView;
@property (nonatomic) AVPlayer *currPlayer;
@property (nonatomic) AVPlayerItem *currItem;

- (void)playAsset:(AVAsset *)asset;

@end
