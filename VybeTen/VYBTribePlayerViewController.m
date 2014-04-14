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
#import "VYBLabel.h"
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

@implementation VYBTribePlayerViewController {
    NSInteger playIndex;
    
    UILabel *currentTribeLabel;
    UILabel *locationLabel;
    UILabel *usernameLabel;
    
    NSArray *peetas;
}
@synthesize player = _player;
@synthesize playerView = _playerView;
@synthesize currItem = _currItem;
@synthesize labelTime, labelDate;
@synthesize currTribe = _currTribe;

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
    
    peetas = [[NSArray alloc] initWithObjects:@"Florence, Italy", @"Madrid, Spain", @"Jakarta, Indonesia", @"Athens, Greece", nil];
    
    // Adding swipe gestures
    UISwipeGestureRecognizer *swipeLeft=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeLeft)];
    swipeLeft.direction=UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeLeft];
    UISwipeGestureRecognizer *swipeRight=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeRight)];
    swipeRight.direction=UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRight];
    
    // Adding TRIBE label
    CGRect frame = CGRectMake(10, self.view.bounds.size.width - 50, 150, 50);
    currentTribeLabel = [[VYBLabel alloc] initWithFrame:frame];
    [currentTribeLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:18]];
    [currentTribeLabel setTextColor:[UIColor whiteColor]];
    [currentTribeLabel setText:[self.currTribe tribeName]];
    [self.view addSubview:currentTribeLabel];
    
    // Adding LOCATION label
    frame = CGRectMake(self.view.bounds.size.height/2 - 100, 0, 200, 50);
    locationLabel = [[VYBLabel alloc] initWithFrame:frame];
    [locationLabel setTextColor:[UIColor whiteColor]];
    [locationLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:18.0]];
    [locationLabel setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:locationLabel];
    if ([[self.currTribe tribeName] isEqualToString:@"MTL-NEXT"]) {
        [locationLabel setText:@"Downtown, Montreal"];
    } else if ([[self.currTribe tribeName] isEqualToString:@"CITY-GAS"]) {
        [locationLabel setText:@"Griffintown, Montreal"];
    } else if ([[self.currTribe tribeName] isEqualToString:@"PEETAPLANET"]) {
        [locationLabel setText:[peetas objectAtIndex:(playIndex/10)]];
    }
    
    // Adding BACK button
    CGRect buttonMenuFrame = CGRectMake(0, 0, 50, 50);
    UIButton *buttonMenu = [[UIButton alloc] initWithFrame:buttonMenuFrame];
    UIImage *menuImage = [UIImage imageNamed:@"button_back_shadow.png"];
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
    CGRect labelTimeFrame = CGRectMake(self.view.bounds.size.height/2 - 80, self.view.bounds.size.width - 50, 160, 50);
    labelTime = [[VYBLabel alloc] initWithFrame:labelTimeFrame];
    [labelTime setTextColor:[UIColor whiteColor]];
    [labelTime setFont:[UIFont fontWithName:@"Montreal-Xlight" size:18.0]];
    [labelTime setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:labelTime];

    VYBVybe *v = [[self.currTribe vybes] objectAtIndex:playIndex];
    [labelTime setText:[v howOld]];
    
    // Start playing videos downloaded from the server
    // Find a vybe to play and set up playerLayer
    NSURL *url = [[NSURL alloc] initFileURLWithPath:[v tribeVideoPath]];
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
    if (from < [[self.currTribe vybes] count]) {
        VYBVybe *v = [[self.currTribe vybes] objectAtIndex:from];
        [labelTime setText:[v howOld]];
        if ([self.currTribe tribeName])
            [locationLabel setText:[peetas objectAtIndex:(from/10)]];
        NSURL *url = [[NSURL alloc] initFileURLWithPath:[v tribeVideoPath]];
        
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
        self.currItem = [AVPlayerItem playerItemWithAsset:asset];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
        [self.player replaceCurrentItemWithPlayerItem:self.currItem];
        [self.player play];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    id tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker) {
        NSString *value = [NSString stringWithFormat:@"TribePlayer[%@] Screen", [self.currTribe tribeName]];
        [tracker set:kGAIScreenName value:value];
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
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
