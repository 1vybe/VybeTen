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
@synthesize labelTime, labelDate;

- (void)loadView {
    NSLog(@"loading view for the first time");
    VYBPlayerView *playerView = [[VYBPlayerView alloc] init];
    self.view = playerView;
    [self.view setFrame:CGRectMake(0, 0, 320, 480)];
    self.playerView = playerView;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    //[self.view setBackgroundColor:[UIColor redColor]];
    // Adding swipe gestures
    UISwipeGestureRecognizer * swipeleft=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeLeft)];
    swipeleft.direction=UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeleft];
    UISwipeGestureRecognizer * swiperight=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeRight)];
    swiperight.direction=UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swiperight];
    /* NOTE: Origin for menu button is (0, 0) */
    // Adding menu button
    CGRect buttonMenuFrame = CGRectMake(0, 0, 48, 48);
    UIButton *buttonMenu = [[UIButton alloc] initWithFrame:buttonMenuFrame];
    UIImage *menuImage = [UIImage imageNamed:@"menu.png"];
    [buttonMenu setImage:menuImage forState:UIControlStateNormal];
    [buttonMenu addTarget:self action:@selector(goToMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonMenu];
    // Adding capture button
    CGRect buttonCaptureFrame = CGRectMake(self.view.bounds.size.height - 48, 0, 48, 48);
    UIButton *buttonCapture = [[UIButton alloc] initWithFrame:buttonCaptureFrame];
    UIImage *captureImage = [UIImage imageNamed:@"capture.png"];
    [buttonCapture setImage:captureImage forState:UIControlStateNormal];
    [buttonCapture addTarget:self action:@selector(captureVybe) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonCapture];
    // Adding date label
    CGRect labelDateFrame = CGRectMake(self.view.bounds.size.height/2 - 60, self.view.bounds.size.width - 48, 120, 48);
    labelDate = [[UILabel alloc] initWithFrame:labelDateFrame];
    [labelDate setTextColor:[UIColor whiteColor]];
    [self.view addSubview:labelDate];
    // Adding time label
    CGRect labelTimeFrame = CGRectMake(self.view.bounds.size.height - 100, self.view.bounds.size.width - 48, 100, 48);
    labelTime = [[UILabel alloc] initWithFrame:labelTimeFrame];
    [labelTime setTextColor:[UIColor whiteColor]];
    [self.view addSubview:labelTime];
    
    // Find a vybe to play and set up playerLayer
    VYBVybe *v = [[[VYBMyVybeStore sharedStore] myVybes] objectAtIndex:playIndex];
    [labelDate setText:[v dateString]];
    [labelTime setText:[v timeString]];
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
        VYBVybe *v = [[[VYBMyVybeStore sharedStore] myVybes] objectAtIndex:from];
        [labelDate setText:[v dateString]];
        [labelTime setText:[v timeString]];
        NSURL *url = [[NSURL alloc] initFileURLWithPath:[v videoPath]];
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
        self.currItem = [AVPlayerItem playerItemWithAsset:asset];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
        [self.player replaceCurrentItemWithPlayerItem:self.currItem];
        [self.player play];
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
    NSLog(@"player menu");
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
