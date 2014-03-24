//
//  VYBPlayerViewController.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 6..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBPlayerViewController.h"
#import "VYBPlayerView.h"
#import "VYBMyVybeStore.h"

@implementation VYBPlayerViewController {
    NSInteger playIndex;
}
@synthesize player = _player;
@synthesize playerView = _playerView;
@synthesize currItem = _currItem;
@synthesize labelTime = _labelTime;

- (void)loadView {
    VYBPlayerView *playerView = [[VYBPlayerView alloc] init];
    UIView *darkBackground = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [darkBackground setBackgroundColor:[UIColor blackColor]];
    self.view = darkBackground;
    [playerView setFrame:CGRectMake(0, 0, darkBackground.bounds.size.height, darkBackground.bounds.size.width)];
    self.playerView = playerView;
    [self.view addSubview:playerView];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Adding swipe gestures
    UISwipeGestureRecognizer *swipeLeft=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeLeft)];
    swipeLeft.direction=UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeLeft];
    UISwipeGestureRecognizer *swipeRight=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeRight)];
    swipeRight.direction=UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRight];
    /* NOTE: Origin for menu button is (0, 0) */
    // Adding menu button
    CGRect buttonMenuFrame = CGRectMake(6, self.view.bounds.size.width - 40, 34, 34);
    UIButton *buttonMenu = [[UIButton alloc] initWithFrame:buttonMenuFrame];
    UIImage *menuImage = [UIImage imageNamed:@"button_menu.png"];
    [buttonMenu setImage:menuImage forState:UIControlStateNormal];
    [buttonMenu addTarget:self action:@selector(goToMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonMenu];
    // Adding capture button
    CGRect buttonCaptureFrame = CGRectMake(self.view.bounds.size.height - 40, self.view.bounds.size.width - 40, 34, 34);
    UIButton *buttonCapture = [[UIButton alloc] initWithFrame:buttonCaptureFrame];
    UIImage *captureImage = [UIImage imageNamed:@"button_vybe.png"];
    [buttonCapture setImage:captureImage forState:UIControlStateNormal];
    [buttonCapture addTarget:self action:@selector(captureVybe) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonCapture];

    // Adding time label
    CGRect labelTimeFrame = CGRectMake(self.view.bounds.size.height/2 - 100, self.view.bounds.size.width - 48, 200, 48);
    self.labelTime = [[UILabel alloc] initWithFrame:labelTimeFrame];
    [self.labelTime setTextColor:[UIColor whiteColor]];
    [self.labelTime setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:self.labelTime];
    
    // Find a vybe to play and set up playerLayer
    VYBVybe *v = [[[VYBMyVybeStore sharedStore] myVybes] objectAtIndex:playIndex];
    [self.labelTime setText:[NSString stringWithFormat:@"%@ %@",[v dateString], [v timeString]]];
    NSURL *url = [[NSURL alloc] initFileURLWithPath:[v videoPath]];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    self.currItem = [AVPlayerItem playerItemWithAsset:asset];
    // Registering the current playerItem to Notification center
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
    [self setPlayer:[AVPlayer playerWithPlayerItem:self.currItem]];
    [self.playerView setPlayer:self.player];
    [self.playerView setVideoFillMode];
    [self.player play];
}

- (void)playFrom:(NSInteger)index {
    playIndex = index;
}

- (void)playerItemDidReachEnd {
    playIndex++;
    [self playbackFrom:playIndex];
 }

- (void)playbackFrom:(NSInteger)from {
    // Remove the playerItem that just finished playing
    [[NSNotificationCenter defaultCenter] removeObserver:self.currItem];
    if (from < [[[VYBMyVybeStore sharedStore] myVybes] count]) {
        // Fade-out effect
        [UIView animateWithDuration:0.1 animations:^{
            self.playerView.alpha = 0.0f;
        }];
        VYBVybe *v = [[[VYBMyVybeStore sharedStore] myVybes] objectAtIndex:from];
        [self.labelTime setText:[NSString stringWithFormat:@"%@ %@", [v dateString], [v timeString]]];
        NSURL *url = [[NSURL alloc] initFileURLWithPath:[v videoPath]];
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
        self.currItem = [AVPlayerItem playerItemWithAsset:asset];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
        [self.player replaceCurrentItemWithPlayerItem:self.currItem];
        [self.player play];
        // Fade-in effect
        [UIView animateWithDuration:0.8 animations:^{
            self.playerView.alpha = 1.0f;
        }];
    }
}

/**
 * User Interactions
 **/

- (void)swipeLeft {
    playIndex++;
    [self playbackFrom:playIndex];
}

- (void)swipeRight {
    playIndex--;
    [self playbackFrom:playIndex];
}

- (void)captureVybe {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)goToMenu {
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
