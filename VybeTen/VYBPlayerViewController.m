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
#import "VYBConstants.h"

@implementation VYBPlayerViewController {
    NSInteger playIndex;
    
    UIButton *backButton;
    UIButton *captureButton;
    
    UILabel *currentTribeLabel;
    UILabel *locationLabel;
    UILabel *usernameLabel;
    
    UIView *loadingView;
    UILabel *loadingLabel;
}

@synthesize currPlayer = _currPlayer;
@synthesize prevPlayer = _prevPlayer;
@synthesize nextPlayer = _nextPlayer;
@synthesize currPlayerView = _currPlayerView;
@synthesize prevPlayerView = _prevPlayerView;
@synthesize nextPlayerView = _nextPlayerView;
@synthesize currItem = _currItem;
@synthesize labelTime = _labelTime;
@synthesize dismissBlock;

- (void)loadView {
    UIView *darkBackground = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [darkBackground setBackgroundColor:[UIColor blackColor]];
    self.view = darkBackground;
    
    VYBPlayerView *playerView1 = [[VYBPlayerView alloc] init];
    VYBPlayerView *playerView2 = [[VYBPlayerView alloc] init];
    VYBPlayerView *playerView3 = [[VYBPlayerView alloc] init];

    [playerView1 setFrame:CGRectMake(0, 0, darkBackground.bounds.size.height, darkBackground.bounds.size.width)];
    [playerView2 setFrame:CGRectMake(0, 0, darkBackground.bounds.size.height, darkBackground.bounds.size.width)];
    [playerView3 setFrame:CGRectMake(0, 0, darkBackground.bounds.size.height, darkBackground.bounds.size.width)];

    self.prevPlayerView = playerView1; 
    self.currPlayerView = playerView2;
    self.nextPlayerView = playerView3;
    
    self.currPlayer = [[AVPlayer alloc] init];
    self.prevPlayer = [[AVPlayer alloc] init];
    self.nextPlayer = [[AVPlayer alloc] init];
    
    [self.prevPlayer addObserver:self forKeyPath:@"status" options:0 context:nil];
    [self.nextPlayer addObserver:self forKeyPath:@"status" options:0 context:nil];
    
    [self.currPlayerView setPlayer:self.currPlayer];
    [self.prevPlayerView setPlayer:self.prevPlayer];
    [self.nextPlayerView setPlayer:self.nextPlayer];

    [self.view addSubview:self.currPlayerView];
    //[self.view addSubview:self.prevPlayerView];
    //[self.view addSubview:self.nextPlayerView];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.prevPlayer && [keyPath isEqualToString:@"status"]) {
        if (self.prevPlayer.status == AVPlayerStatusReadyToPlay) {
            NSLog(@"prevPlayer READY");
        } else if (self.prevPlayer.status == AVPlayerStatusFailed) {
            NSLog(@"prevPlayer WEIRD");
        } else {
            NSLog(@"prevPlayer STATUS");
        }
    }
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

    // Add tap gesture
    UITapGestureRecognizer *tapOnce = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnce)];
    tapOnce.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapOnce];

    /* NOTE: Origin for menu button is (0, 0) */
    // Adding BACK button
    CGRect buttonBackFrame = CGRectMake(0, 0, 50, 50);
    backButton = [[UIButton alloc] initWithFrame:buttonBackFrame];
    UIImage *backImage = [UIImage imageNamed:@"button_back_shadow.png"];
    [backButton setContentMode:UIViewContentModeCenter];
    [backButton setImage:backImage forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(goBack:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];
    // Adding capture button
    CGRect buttonCaptureFrame = CGRectMake(self.view.bounds.size.height - 50, self.view.bounds.size.width - 50, 50, 50);
    captureButton = [[UIButton alloc] initWithFrame:buttonCaptureFrame];
    UIImage *captureImage = [UIImage imageNamed:@"button_vybe.png"];
    [captureButton setContentMode:UIViewContentModeCenter];
    [captureButton setImage:captureImage forState:UIControlStateNormal];
    [captureButton addTarget:self action:@selector(captureVybe:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:captureButton];

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
    [self.view addSubview:currentTribeLabel];
    
    // LOADING screen
    loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    [loadingView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.5]];
    loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];
    [loadingLabel setText:@"L O A D I N G ..."];
    [loadingLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:24.0f]];
    [loadingLabel setTextAlignment:NSTextAlignmentCenter];
    [loadingLabel setTextColor:[UIColor whiteColor]];
    [loadingView addSubview:loadingLabel];
    loadingLabel.center = loadingView.center;
    [self.view addSubview:loadingView];
    loadingView.hidden = YES;
    
}

- (void)playFrom:(NSInteger)index {
    playIndex = index;
    PFObject *currVybe = [self.vybePlaylist objectAtIndex:index];
    PFFile *vid = [currVybe objectForKey:kVYBVybeVideoKey];
    loadingView.hidden = NO;
    [vid getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        loadingView.hidden = YES;
        if (!error) {
            //self.currItem = [AVPlayerItem playerItemWithAsset: ];

        } else {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Network Temporarily Unavailable" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [av show];
        }
    }];
    //[self setUpPlayersAt:playIndex];
}

- (void)playerItemDidReachEnd {
    [self.currPlayer pause];
    playIndex--;
    //[self setUpPlayersAt:playIndex];
}

/*
- (void)setUpPlayersAt:(NSInteger)from {
    // Remove the playerItem that just finished playing
    [[NSNotificationCenter defaultCenter] removeObserver:self.currItem];
    if (from < [self.vybePlaylist count]) {
        
        VYBVybe *currV, *prevV, *nextV;
        currV = (VYBVybe *)[self.vybePlaylist objectAtIndex:from];
        prevV = (from == [self.vybePlaylist count] - 1) ? nil : (VYBVybe *)[self.vybePlaylist objectAtIndex:from + 1];
        nextV = (from == 0) ? nil : (VYBVybe *)[self.vybePlaylist objectAtIndex:from - 1];
        
        [self.labelTime setText:[NSString stringWithFormat:@"%@ %@", [currV dateString], [currV timeString]]];

        [locationLabel setText:@"Old Port, Montreal"];
        NSURL *currUrl = [[NSURL alloc] initFileURLWithPath:[currV tribeVideoPath]];
        NSURL *prevUrl, *nextUrl;
        if ([currV upStatus] == UPLOADED || [currV upStatus] == UPLOADING || [currV upStatus] == UPFRESH) {
            AVMutableComposition *composition = [AVMutableComposition composition];
            
            currUrl = [[NSURL alloc] initFileURLWithPath:[currV videoPath]];
            prevUrl = [[NSURL alloc] initFileURLWithPath:[prevV videoPath]];
            nextUrl = [[NSURL alloc] initFileURLWithPath:[nextV videoPath]];
        }
        else if ([currV downStatus] != DOWNLOADED) {
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
            [[VYBMyTribeStore sharedStore] downloadTribeVybeFor:currV withCompletion:^(NSError *err) {
                if (err) {
                    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Network Temporarily Unavailable" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [av show];
                }
                NSLog(@"Vybe Downloaded - Loading Screen Removed");
                [loadingView removeFromSuperview];
                AVURLAsset *currAsset = [AVURLAsset URLAssetWithURL:currUrl options:nil];
                self.currItem = [AVPlayerItem playerItemWithAsset:currAsset];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
                [self.currPlayer replaceCurrentItemWithPlayerItem:self.currItem];
                [self.currPlayer play];
            }];
            
            [currV setWatched:YES];
            
            return;
        }
        AVURLAsset *currAsset = [AVURLAsset URLAssetWithURL:currUrl options:nil];
        AVURLAsset *prevAsset = [AVURLAsset URLAssetWithURL:prevUrl options:nil];
        AVURLAsset *nextAsset = [AVURLAsset URLAssetWithURL:nextUrl options:nil];

        self.currItem = [AVPlayerItem playerItemWithAsset:currAsset];
        AVPlayerItem *prevItem = [AVPlayerItem playerItemWithAsset:prevAsset];
        AVPlayerItem *nextItem = [AVPlayerItem playerItemWithAsset:nextAsset];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
        [self.currPlayer replaceCurrentItemWithPlayerItem:self.currItem];
        [self.prevPlayer replaceCurrentItemWithPlayerItem:prevItem];
        [self.nextPlayer replaceCurrentItemWithPlayerItem:nextItem];
        
        [self.currPlayer play];
        
        //NSLog(@"prev: %@",[self.prevPlayer status]);
        //NSLog(@"next: %@", [self.nextPlayer status]);
        // TODO: This should set all the previous vybes as WATCHED
        [currV setWatched:YES];
    }
}
*/

- (void)playFromUnwatched {
    /*
    NSInteger i = [self.vybePlaylist count] - 1;
    playIndex = [self.vybePlaylist count] - 1;

    for (; i >= 0; i--) {
        VYBVybe *v = [self.vybePlaylist objectAtIndex:i];
        if (![v isWatched]) {
            playIndex = i;
            break;
        }
    }
    
    [self setUpPlayersAt:playIndex];
    NSLog(@"Watching From %ld", (long)playIndex);
    */
}


/**
 * User Interactions
 **/

- (void)swipeLeft {
    [self.currPlayer pause];
    [loadingView removeFromSuperview];
    playIndex--;
    //[self setUpPlayersAt:playIndex];
}

- (void)swipeRight {
    [self.currPlayer pause];
    [loadingView removeFromSuperview];
    playIndex++;
    //[self setUpPlayersAt:playIndex];
}

- (void)tapOnce {
    if (self.currPlayer.rate != 0) {
        [self.currPlayer pause];
    } else {
        [self.currPlayer play];
    }
}

- (void)captureVybe:(id)sender {

}

- (void)goBack:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
