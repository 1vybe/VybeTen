//
//  VYBTribePlayerViewController.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 10..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBTribePlayerViewController.h"
#import "VYBMyTribeStore.h"
#import "VYBPlayerView.h"

@implementation VYBTribePlayerViewController {
    NSInteger playIndex;
}
@synthesize player = _player;
@synthesize playerView = _playerView;
@synthesize currItem = _currItem;
@synthesize labelTime, labelDate;
@synthesize tribeName = _tribeName;

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
    // Adding BACK button
    CGRect buttonMenuFrame = CGRectMake(0, self.view.bounds.size.width - 50, 50, 50);
    UIButton *buttonMenu = [[UIButton alloc] initWithFrame:buttonMenuFrame];
    UIImage *menuImage = [UIImage imageNamed:@"button_back.png"];
    [buttonMenu setContentMode:UIViewContentModeCenter];
    [buttonMenu setImage:menuImage forState:UIControlStateNormal];
    [buttonMenu addTarget:self action:@selector(goBack:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonMenu];
    // Adding CAPTURE button
    CGRect buttonCaptureFrame = CGRectMake(self.view.bounds.size.height - 50, self.view.bounds.size.width - 50, 50, 50);
    UIButton *buttonCapture = [[UIButton alloc] initWithFrame:buttonCaptureFrame];
    UIImage *captureImage = [UIImage imageNamed:@"button_vybe.png"];
    [buttonCapture setContentMode:UIViewContentModeCenter];
    [buttonCapture setImage:captureImage forState:UIControlStateNormal];
    [buttonCapture addTarget:self action:@selector(captureVybe:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonCapture];

    // Adding time label
    CGRect labelTimeFrame = CGRectMake(self.view.bounds.size.height/2 - 80, self.view.bounds.size.width - 48, 160, 48);
    labelTime = [[UILabel alloc] initWithFrame:labelTimeFrame];
    [labelTime setTextColor:[UIColor whiteColor]];
    [labelTime setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:labelTime];

    VYBVybe *v = [[[[VYBMyTribeStore sharedStore] myTribesVybes] objectForKey:self.tribeName] objectAtIndex:playIndex];
    [labelTime setText:[v howOld]];
    
    // Start playing videos downloaded from the server
    // Find a vybe to play and set up playerLayer
    NSString *videoPath = [v videoPath];
    NSURL *url = [[NSURL alloc] initFileURLWithPath:videoPath];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    self.currItem = [AVPlayerItem playerItemWithAsset:asset];
    // Registering the current playerItem to Notification center
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
    [self setPlayer:[AVPlayer playerWithPlayerItem:self.currItem]];
    [self.playerView setPlayer:self.player];
    [self.playerView setVideoFillMode];
    [self.player play];
}

- (void)playFrom:(NSInteger)from {
    playIndex = from;
}

- (void)playerItemDidReachEnd {
    playIndex--;
    [self playbackFrom:playIndex];
}

- (void)playbackFrom:(NSInteger)from {
    // Remove the playerItem that just finished playing
    [[NSNotificationCenter defaultCenter] removeObserver:self.currItem];
    if (from < [[[[VYBMyTribeStore sharedStore] myTribesVybes] objectForKey:self.tribeName] count]) {
        [UIView animateWithDuration:0.1 animations:^{
            self.playerView.alpha = 0.0f;
        }];
        VYBVybe *v = [[[[VYBMyTribeStore sharedStore] myTribesVybes] objectForKey:self.tribeName] objectAtIndex:from];
        [labelTime setText:[v howOld]];
        NSURL *url = [[NSURL alloc] initFileURLWithPath:[v videoPath]];
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
        self.currItem = [AVPlayerItem playerItemWithAsset:asset];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
        [self.player replaceCurrentItemWithPlayerItem:self.currItem];
        [self.player play];
        [UIView animateWithDuration:0.8 animations:^{
            self.playerView.alpha = 1.0f;
        }];
    }
}


/**
 * User Interactions
 **/

- (void)swipeLeft {
    playIndex--;
    [self playbackFrom:playIndex];
}

- (void)swipeRight {
    playIndex++;
    [self playbackFrom:playIndex];
}

- (void)captureVybe:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
