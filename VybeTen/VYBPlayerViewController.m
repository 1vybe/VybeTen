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
#import "VYBMyTribeStore.h"
#import "VYBConstants.h"

@implementation VYBPlayerViewController {
    NSInteger playIndex;
    
    UILabel *currentTribeLabel;
    UILabel *locationLabel;
    UILabel *usernameLabel;
    
    UIView *loadingView;
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
    
    // Adding LOCATION label
    CGRect frame = CGRectMake(self.view.bounds.size.height/2 - 100, 0, 200, 50);
    locationLabel = [[VYBLabel alloc] initWithFrame:frame];
    [locationLabel setTextColor:[UIColor whiteColor]];
    [locationLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:18.0]];
    [locationLabel setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:locationLabel];
    
    // Adding TRIBE label
    frame = CGRectMake(10, self.view.bounds.size.width - 50, 150, 50);
    currentTribeLabel = [[VYBLabel alloc] initWithFrame:frame];
    [currentTribeLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:18]];
    [currentTribeLabel setTextColor:[UIColor whiteColor]];
    [currentTribeLabel setText:[v tribeName]];
    [self.view addSubview:currentTribeLabel];

    [self setPlayer:[AVPlayer playerWithPlayerItem:self.currItem]];
    [self.playerView setPlayer:self.player];
    [self.playerView setVideoFillMode];
}

- (void)playFrom:(NSInteger)index {
    playIndex = index;
    [self playbackFrom:playIndex];
}

- (void)playerItemDidReachEnd {
    [self.player pause];
    playIndex--;
    [self playbackFrom:playIndex];
}

- (void)playbackFrom:(NSInteger)from {
    // Remove the playerItem that just finished playing
    [[NSNotificationCenter defaultCenter] removeObserver:self.currItem];
    if (from < [self.vybePlaylist count]) {
        VYBVybe *v = (VYBVybe *)[self.vybePlaylist objectAtIndex:from];
        [self.labelTime setText:[NSString stringWithFormat:@"%@ %@", [v dateString], [v timeString]]];
        /* TODO: change location accordingly to the vybe playing */
        [locationLabel setText:@"Old Port, Montreal"];
        NSURL *url = [[NSURL alloc] initFileURLWithPath:[v tribeVideoPath]];
        if ([v upStatus] == UPLOADED || [v upStatus] == UPLOADING || [v upStatus] == UPFRESH) {
            url = [[NSURL alloc] initFileURLWithPath:[v videoPath]];
        }
        else if ([v downStatus] != DOWNLOADED) {
            loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
            [loadingView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.5]];
            UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];
            [loadingLabel setText:@"L O A D I N G ..."];
            [loadingLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:24.0f]];
            [loadingLabel setTextAlignment:NSTextAlignmentCenter];
            [loadingLabel setTextColor:[UIColor whiteColor]];
            [loadingView addSubview:loadingLabel];
            loadingLabel.center = loadingView.center;
            [self.view addSubview:loadingView];
            [[VYBMyTribeStore sharedStore] downloadTribeVybeFor:v withCompletion:^(NSError *err) {
                if (err) {
                    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Network Temporarily Unavailable" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [av show];
                }
                NSLog(@"Vybe Downloaded - Loading Screen Removed");
                [loadingView removeFromSuperview];
                AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
                self.currItem = [AVPlayerItem playerItemWithAsset:asset];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
                [self.player replaceCurrentItemWithPlayerItem:self.currItem];
                [self.player play];
                /* TODO: This should set all the previous vybes as WATCHED */
            }];
            
            [v setWatched:YES];
            
            return;
        }
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
        self.currItem = [AVPlayerItem playerItemWithAsset:asset];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
        [self.player replaceCurrentItemWithPlayerItem:self.currItem];
        [self.player play];
        /* TODO: This should set all the previous vybes as WATCHED */
        [v setWatched:YES];
    }
}

- (void)playFromUnwatched {
    NSInteger i = [self.vybePlaylist count] - 1;
    playIndex = [self.vybePlaylist count] - 1;

    for (; i >= 0; i--) {
        VYBVybe *v = [self.vybePlaylist objectAtIndex:i];
        if (![v isWatched]) {
            playIndex = i;
            break;
        }
    }
    
    [self playbackFrom:playIndex];
    NSLog(@"Watching From %d", playIndex);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

/**
 * User Interactions
 **/

- (void)swipeLeft {
    [self.player pause];
    [loadingView removeFromSuperview];
    playIndex--;
    [self playbackFrom:playIndex];
}

- (void)swipeRight {
    [self.player pause];
    [loadingView removeFromSuperview];
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
