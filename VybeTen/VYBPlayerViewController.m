//
//  VYBPlayerViewController.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 6..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBPlayerViewController.h"
#import "VYBPlayerView.h"
#import "VYBLabel.h"
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"
#import "VYBVybe.h"
#import "VYBConstants.h"

@implementation VYBPlayerViewController {
    NSInteger playIndex;
    
    UILabel *currentTribeLabel;
    UILabel *locationLabel;
    UILabel *usernameLabel;
}

@synthesize player = _player;
@synthesize playerView = _playerView;
@synthesize currItem = _currItem;
@synthesize labelTime = _labelTime;
@synthesize dismissBlock;

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
    CGRect buttonBackFrame = CGRectMake(0, 0, 50, 50);
    UIButton *buttonBack = [[UIButton alloc] initWithFrame:buttonBackFrame];
    UIImage *backImage = [UIImage imageNamed:@"button_back_shadow.png"];
    [buttonBack setContentMode:UIViewContentModeCenter];
    [buttonBack setImage:backImage forState:UIControlStateNormal];
    [buttonBack addTarget:self action:@selector(goBack:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonBack];
    // Adding capture button
    CGRect buttonCaptureFrame = CGRectMake(self.view.bounds.size.height - 50, self.view.bounds.size.width - 50, 50, 50);
    UIButton *buttonCapture = [[UIButton alloc] initWithFrame:buttonCaptureFrame];
    UIImage *captureImage = [UIImage imageNamed:@"button_vybe.png"];
    [buttonCapture setContentMode:UIViewContentModeCenter];
    [buttonCapture setImage:captureImage forState:UIControlStateNormal];
    [buttonCapture addTarget:self action:@selector(captureVybe:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonCapture];


    VYBVybe *v = (VYBVybe *)[self.vybePlaylist objectAtIndex:playIndex];

    // Adding TIME label
    CGRect labelTimeFrame = CGRectMake(self.view.bounds.size.height/2 - 100, self.view.bounds.size.width - 48, 200, 48);
    self.labelTime = [[VYBLabel alloc] initWithFrame:labelTimeFrame];
    [self.labelTime setTextColor:[UIColor whiteColor]];
    [self.labelTime setFont:[UIFont fontWithName:@"Montreal-Xlight" size:18.0]];
    [self.labelTime setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:self.labelTime];
    [self.labelTime setText:[NSString stringWithFormat:@"%@ %@",[v dateString], [v timeString]]];
    
    // Adding LOCATION label
    CGRect frame = CGRectMake(self.view.bounds.size.height/2 - 100, 0, 200, 50);
    locationLabel = [[VYBLabel alloc] initWithFrame:frame];
    [locationLabel setTextColor:[UIColor whiteColor]];
    [locationLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:18.0]];
    [locationLabel setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:locationLabel];
    [locationLabel setText:@"Old Port, Montreal"];
    
    // Adding TRIBE label
    frame = CGRectMake(10, self.view.bounds.size.width - 50, 150, 50);
    currentTribeLabel = [[VYBLabel alloc] initWithFrame:frame];
    [currentTribeLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:18]];
    [currentTribeLabel setTextColor:[UIColor whiteColor]];
    [currentTribeLabel setText:[v tribeName]];
    [self.view addSubview:currentTribeLabel];

    // Set up playerLayer
    NSURL *url = [[NSURL alloc] initFileURLWithPath:[v tribeVideoPath]];
    if ([v upStatus] == UPLOADED || [v upStatus] == UPLOADING) {
        url = [[NSURL alloc] initFileURLWithPath:[v videoPath]];
    }
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSLog(@"Let's play asset: %@", [v tribeVideoPath]);
    NSLog(@"asset URL: %@", url);

    self.currItem = [AVPlayerItem playerItemWithAsset:asset];
    // Registering the current playerItem to Notification center
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
    [self setPlayer:[AVPlayer playerWithPlayerItem:self.currItem]];
    [self.playerView setPlayer:self.player];
    [self.playerView setVideoFillMode];
    [self.player play];
    [v setWatched:YES];
}

- (void)playFrom:(NSInteger)index {
    playIndex = index;
}

- (void)playerItemDidReachEnd {
    playIndex--;
    [self playbackFrom:playIndex];
 }

- (void)playbackFrom:(NSInteger)from {
    // Remove the playerItem that just finished playing
    [[NSNotificationCenter defaultCenter] removeObserver:self.currItem];
    if (from < [self.vybePlaylist count]) {
        VYBVybe *v = (VYBVybe *)[self.vybePlaylist objectAtIndex:from];
        [self.labelTime setText:[NSString stringWithFormat:@"%@ %@", [v dateString], [v timeString]]];
        NSURL *url = [[NSURL alloc] initFileURLWithPath:[v tribeVideoPath]];
        if ([v upStatus] == UPLOADED || [v upStatus] == UPLOADING) {
            url = [[NSURL alloc] initFileURLWithPath:[v videoPath]];
        }
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
        self.currItem = [AVPlayerItem playerItemWithAsset:asset];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
        [self.player replaceCurrentItemWithPlayerItem:self.currItem];
        [self.player play];
        [v setWatched:YES];
    }
}

- (void)playFromUnwatched {
    NSInteger i = [self.vybePlaylist count] - 1;
    for (; i >= 0; i--) {
        VYBVybe *v = [self.vybePlaylist objectAtIndex:i];
        if (![v isWatched]) {
            playIndex = i;
            return;
        }
    }
    playIndex = [self.vybePlaylist count] - 1;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker) {
        [tracker set:kGAIScreenName value:@"VybePlayer Screen"];
        [tracker send:[[GAIDictionaryBuilder createAppView] build]];
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
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
