//
//  VYBPlayerViewController.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 6..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBPlayerViewController.h"
#import "VYBUtility.h"
#import "VYBPlayerView.h"
#import "VYBLabel.h"
#import "VYBConstants.h"
#import "MBProgressHUD.h"
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

@implementation VYBPlayerViewController {
    NSInteger playIndex;
    
    UIButton *dismissButton;
    UIButton *captureButton;
    UIButton *tribeTimelineButton;
    
    UILabel *currentTribeLabel;
    UILabel *locationLabel;
    UILabel *usernameLabel;
    UILabel *timeLabel;
    
    UIView *loadingView;
    UILabel *loadingLabel;
    
}

@synthesize currPlayer = _currPlayer;
@synthesize currPlayerView = _currPlayerView;
@synthesize currItem = _currItem;
//@synthesize dismissBlock;

- (void)dealloc {
    NSLog(@"Playerview dealloc");
}

- (void)loadView {
    UIView *darkBackground = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [darkBackground setBackgroundColor:[UIColor blackColor]];
    self.view = darkBackground;
    
    VYBPlayerView *playerView = [[VYBPlayerView alloc] init];

    [playerView setFrame:CGRectMake(0, 0, darkBackground.bounds.size.height, darkBackground.bounds.size.width)];

    self.currPlayerView = playerView;
    
    self.currPlayer = [[AVPlayer alloc] init];
    
    [self.currPlayerView setPlayer:self.currPlayer];

    [self.view addSubview:self.currPlayerView];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // responds to device orientation change
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
    
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
    // Adding DISMISS button
    CGRect frame = CGRectMake(0, 0, 50, 50);
    dismissButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *dismissImage = [UIImage imageNamed:@"button_dismiss.png"];
    [dismissButton setContentMode:UIViewContentModeCenter];
    [dismissButton setImage:dismissImage forState:UIControlStateNormal];
    [dismissButton addTarget:self action:@selector(dismissButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:dismissButton];
    // Adding CAPTURE button
    frame = CGRectMake(self.view.bounds.size.height - 50, self.view.bounds.size.width - 50, 50, 50);
    captureButton = [[UIButton alloc] initWithFrame:frame];
    [captureButton setContentMode:UIViewContentModeCenter];
    [captureButton setImage:[UIImage imageNamed:@"button_vybe.png"] forState:UIControlStateNormal];
    [captureButton addTarget:self action:@selector(captureVybe:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:captureButton];
    frame = CGRectMake(self.view.bounds.size.height - 50, 0, 50, 50);
    tribeTimelineButton = [[UIButton alloc] initWithFrame:frame];
    [tribeTimelineButton setImage:[UIImage imageNamed:@"button_tribeTimeline.png"] forState:UIControlStateNormal];
    [tribeTimelineButton addTarget:self action:@selector(tribeTimelineButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:tribeTimelineButton];
    // Adding TIME label
    frame = CGRectMake(self.view.bounds.size.height/2 - 100, self.view.bounds.size.width - 48, 200, 48);
    timeLabel = [[VYBLabel alloc] initWithFrame:frame];
    [timeLabel setTextColor:[UIColor whiteColor]];
    [timeLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:18.0]];
    [timeLabel setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:timeLabel];
    // Adding LOCATION label
    frame = CGRectMake(self.view.bounds.size.height/2 - 150, 0, 300, 50);
    locationLabel = [[VYBLabel alloc] initWithFrame:frame];
    [locationLabel setTextColor:[UIColor whiteColor]];
    [locationLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:18.0]];
    [locationLabel setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:locationLabel];
    // Adding TRIBE label
    frame = CGRectMake(self.view.bounds.size.height - 150, 50, 150, 50);
    currentTribeLabel = [[VYBLabel alloc] initWithFrame:frame];
    [currentTribeLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:18]];
    [currentTribeLabel setTextColor:[UIColor whiteColor]];
    [currentTribeLabel setTextAlignment:NSTextAlignmentRight];
    [self.view addSubview:currentTribeLabel];
    // Adding USERNAME label
    frame = CGRectMake(0, self.view.bounds.size.width - 50, 150, 50);
    usernameLabel = [[VYBLabel alloc] initWithFrame:frame];
    [usernameLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:18]];
    [usernameLabel setTextColor:[UIColor whiteColor]];
    [self.view addSubview:usernameLabel];
    
    // LOADING screen
    [self setUpLoadingScreen];
}

- (void)playVybeAt:(NSInteger)from {
    PFObject *aVybe = [self.vybePlaylist objectAtIndex:from];
    // change Labels accordingly
    [self syncUI:aVybe];
    
    NSURL *cacheURL = (NSURL *)[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
    cacheURL = [cacheURL URLByAppendingPathComponent:[aVybe objectId]];
    cacheURL = [cacheURL URLByAppendingPathExtension:@"mov"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[cacheURL path]]) {
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:cacheURL options:nil];
        self.currItem = [AVPlayerItem playerItemWithAsset:asset];
        [self.currPlayer replaceCurrentItemWithPlayerItem:self.currItem];
        //[self.currPlayer play];
    } else {
        PFFile *vid = [aVybe objectForKey:kVYBVybeVideoKey];
        loadingView.hidden = NO;
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [vid getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            loadingView.hidden = YES;
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            if (!error) {
                [data writeToURL:cacheURL atomically:YES];
                AVURLAsset *asset = [AVURLAsset URLAssetWithURL:cacheURL options:nil];
                self.currItem = [AVPlayerItem playerItemWithAsset:asset];
                [self.currPlayer replaceCurrentItemWithPlayerItem:self.currItem];
                //[self.currPlayer play];
            } else {
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Network Temporarily Unavailable" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [av show];
            }
        }];
    }
}

- (void)playVybe:(PFObject *)aVybe {
    NSURL *cacheURL = (NSURL *)[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
    cacheURL = [cacheURL URLByAppendingPathComponent:[aVybe objectId]];
    cacheURL = [cacheURL URLByAppendingPathExtension:@"mov"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[cacheURL path]]) {
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:cacheURL options:nil];
        self.currItem = [AVPlayerItem playerItemWithAsset:asset];
        [self.currPlayer replaceCurrentItemWithPlayerItem:self.currItem];
        [self.currPlayer play];
    } else {
        PFFile *vid = [aVybe objectForKey:kVYBVybeVideoKey];
        loadingView.hidden = NO;
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [vid getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            loadingView.hidden = YES;
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            if (!error) {
                [data writeToURL:cacheURL atomically:YES];
                AVURLAsset *asset = [AVURLAsset URLAssetWithURL:cacheURL options:nil];
                self.currItem = [AVPlayerItem playerItemWithAsset:asset];
                [self.currPlayer replaceCurrentItemWithPlayerItem:self.currItem];
                [self.currPlayer play];
            } else {
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Network Temporarily Unavailable" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [av show];
            }
        }];
    }   
}

- (void)playerItemDidReachEnd {
    [self.currPlayer pause];
    playIndex--;
    //[self setUpPlayersAt:playIndex];
}

- (void)setUpLoadingScreen {
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

- (void)syncUI:(PFObject *)aVybe {
    currentTribeLabel.text = [[aVybe objectForKey:kVYBVybeTribeKey] objectForKey:kVYBTribeNameKey];
    locationLabel.text = [aVybe objectForKey:kVYBVybeLocationName];
    timeLabel.text = [VYBUtility localizedDateStringFrom:[aVybe objectForKey:kVYBVybeTimestampKey]];
    usernameLabel.text = [[aVybe objectForKey:kVYBVybeUserKey] objectForKey:kVYBUserDisplayNameKey];
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

- (void)dismissButtonPressed:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

- (void)tribeTimelineButtonPressed:(id)sender {

}

#pragma mark - UIInterfaceOrientation

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (void)deviceOrientationChanged:(NSNotification *)note {
    [self tapOnce];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
