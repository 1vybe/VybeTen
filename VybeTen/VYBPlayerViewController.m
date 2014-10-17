//
//  VYBPlayerViewController.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 6..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBAppDelegate.h"
#import "VYBPlayerViewController.h"
#import "VYBPlayerControlViewController.h"
#import "VYBPlayerView.h"
#import "VYBTimerView.h"
#import "AVAsset+VideoOrientation.h"

@implementation VYBPlayerViewController {
    AVCaptureVideoOrientation lastOrientation;
    
    UIView *backgroundView;
    VYBTimerView *timerView;
}

@synthesize currPlayer = _currPlayer;
@synthesize currPlayerView = _currPlayerView;
@synthesize currItem = _currItem;


- (void)loadView {
    [super loadView];
    
    VYBPlayerView *playerView = [[VYBPlayerView alloc] init];
    [playerView setFrame:[[UIScreen mainScreen] bounds]];
    self.currPlayerView = playerView;
    
    self.currPlayer = [[AVPlayer alloc] init];
    [self.currPlayerView setPlayer:self.currPlayer];
    
    [self.view addSubview:playerView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)playAsset:(AVAsset *)asset {
    [self.currPlayerView setOrientation:[asset videoOrientation]];
    
    self.currItem = [AVPlayerItem playerItemWithAsset:asset];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
    [self.currPlayer replaceCurrentItemWithPlayerItem:self.currItem];
    [self.currPlayer play];
}

- (void)playerItemDidReachEnd {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
    if (self.playerController)
        [self.playerController playNextItem];
}

#pragma mark - DeviceOrientation

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - ()

- (BOOL)prefersStatusBarHidden {
    return YES;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
