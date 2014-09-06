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

@interface VYBPlayerViewController : GAITrackedViewController <UIAlertViewDelegate, MBProgressHUDDelegate>
@property (nonatomic, weak) id presentingVC;

@property (nonatomic) AVPlayer *currPlayer;
@property (nonatomic) VYBPlayerView *currPlayerView;
@property (nonatomic) AVPlayerItem *currItem;
@property (nonatomic, copy) NSArray *vybePlaylist;
@property (nonatomic) NSInteger debugMode;
@property (nonatomic) NSInteger currVybeIndex;
@property (nonatomic) PFObject *currRegion;
@property (nonatomic) PFObject *currUser;

+ (VYBPlayerViewController *)playerViewControllerForPageIndex:(NSInteger)idx;
- (NSInteger)pageIndex;
- (void)beginPlayingFrom:(NSInteger)from;

@end
