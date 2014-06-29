//
//  VYBPlayerViewController.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 6..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBPlayerViewController.h"
#import "VYBCaptureViewController.h"
#import "VYBTribeTimelineViewController.h"
#import "VYBUtility.h"
#import "VYBCache.h"
#import "VYBPlayerView.h"
#import "VYBLabel.h"
#import "VYBConstants.h"
#import "MBProgressHUD.h"
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

@implementation VYBPlayerViewController {
    NSInteger currVybeIndex;
    NSInteger downloadingVybeIndex;
    
    UIButton *dismissButton;
    UIButton *captureButton;
    UIButton *tribeTimelineButton;
    UIButton *usernameButton;
    
    UIImageView *pauseImageView;
    
    UILabel *currentTribeLabel;
    UILabel *locationLabel;
    UILabel *timeLabel;
    
}

@synthesize currPlayer = _currPlayer;
@synthesize currPlayerView = _currPlayerView;
@synthesize currItem = _currItem;

- (void)dealloc {

    
    NSLog(@"PlayerViewController released");

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
    CGRect frame = CGRectMake(self.view.bounds.size.height - 50, 0, 50, 50);
    dismissButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *dismissImage = [UIImage imageNamed:@"button_dismiss.png"];
    [dismissButton setContentMode:UIViewContentModeCenter];
    [dismissButton setImage:dismissImage forState:UIControlStateNormal];
    [dismissButton addTarget:self action:@selector(dismissButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:dismissButton];
    // Adding CAPTURE button
    frame = CGRectMake(self.view.bounds.size.height - 50, (self.view.bounds.size.width - 50)/2, 50, 50);
    captureButton = [[UIButton alloc] initWithFrame:frame];
    [captureButton setContentMode:UIViewContentModeCenter];
    [captureButton setImage:[UIImage imageNamed:@"button_player_capture.png"] forState:UIControlStateNormal];
    [captureButton addTarget:self action:@selector(captureVybe:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:captureButton];
    // Adding TRIBE button
    frame = CGRectMake(0, 0, 50, 50);
    tribeTimelineButton = [[UIButton alloc] initWithFrame:frame];
    [tribeTimelineButton setImage:[UIImage imageNamed:@"button_tribeTimeline.png"] forState:UIControlStateNormal];
    [tribeTimelineButton addTarget:self action:@selector(tribeTimelineButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:tribeTimelineButton];
    // Adding TRIBE label
    currentTribeLabel = [[VYBLabel alloc] initWithFrame:CGRectMake(-50, 50, 150, 40)];
    [currentTribeLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:16]];
    [currentTribeLabel setTextColor:[UIColor whiteColor]];
    [currentTribeLabel setTextAlignment:NSTextAlignmentCenter];
    [tribeTimelineButton addSubview:currentTribeLabel];
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

    // Adding USERNAME label
    frame = CGRectMake(0, self.view.bounds.size.width - 50, 150, 50);
    usernameButton = [[UIButton alloc] initWithFrame:frame];
    [usernameButton.titleLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:18]];
    [usernameButton.titleLabel setTextColor:[UIColor whiteColor]];
    [usernameButton addTarget:self action:@selector(usernameButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:usernameButton];
    
    frame = CGRectMake(self.view.bounds.size.height/2 - 20, self.view.bounds.size.width/2 - 20, 40, 40);
    pauseImageView = [[UIImageView alloc] initWithFrame:frame];
    [pauseImageView setImage:[UIImage imageNamed:@"button_player_pause.png"]];
    [pauseImageView setContentMode:UIViewContentModeCenter];
    NSLog(@"pause imageview BEFORE: %@", NSStringFromCGRect(pauseImageView.frame));
    [self.view addSubview:pauseImageView];
    pauseImageView.hidden = YES;
}

- (void)playVybe:(PFObject *)aVybe {
    if (!aVybe) {
        return;
    }
    PFObject *aTribe = aVybe[kVYBVybeTribeKey];
    PFQuery *query = [PFQuery queryWithClassName:kVYBVybeClassKey];
    [query whereKey:kVYBVybeTribeKey equalTo:aTribe];
    [query orderByAscending:kVYBVybeTimestampKey];
    [query includeKey:kVYBVybeTribeKey];
    [query includeKey:kVYBVybeUserKey];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.vybePlaylist = objects;
            // Find the right current index
            NSInteger i;
            currVybeIndex = 0;
            for (i = 0; i < self.vybePlaylist.count; i++) {
                PFObject *obj = (PFObject *)self.vybePlaylist[i];
                if ([aVybe.objectId isEqualToString:obj.objectId]) {
                    currVybeIndex = i;
                    break;
                }
            }
            [self beginPlayingFrom:currVybeIndex];
        }
    }];
}

- (void)beginPlayingFrom:(NSInteger)from {
    currVybeIndex = from;
    downloadingVybeIndex = currVybeIndex + 1;
    
    PFObject *currVybe = [self.vybePlaylist objectAtIndex:currVybeIndex];
   
    NSURL *cacheURL = (NSURL *)[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
    cacheURL = [cacheURL URLByAppendingPathComponent:[currVybe objectId]];
    cacheURL = [cacheURL URLByAppendingPathExtension:@"mov"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[cacheURL path]]) {
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:cacheURL options:nil];
        self.currItem = [AVPlayerItem playerItemWithAsset:asset];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
        [self.currPlayer replaceCurrentItemWithPlayerItem:self.currItem];
        [self.currPlayer play];
        [self syncUI:currVybe];
        [self prepareVybeAt:downloadingVybeIndex];
    } else {
        PFFile *vid = [currVybe objectForKey:kVYBVybeVideoKey];
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        //loadingView.hidden = NO;
        [vid getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            //loadingView.hidden = YES;
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            if (!error) {
                [data writeToURL:cacheURL atomically:YES];
                AVURLAsset *asset = [AVURLAsset URLAssetWithURL:cacheURL options:nil];
                self.currItem = [AVPlayerItem playerItemWithAsset:asset];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
                [self.currPlayer replaceCurrentItemWithPlayerItem:self.currItem];
                [self.currPlayer play];
                [self syncUI:currVybe];
                [self prepareVybeAt:downloadingVybeIndex];
            } else {
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Network Temporarily Unavailable" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [av show];
            }
        }];
    }
}

- (void)prepareVybeAt:(NSInteger)idx {
    downloadingVybeIndex = idx;
    if (downloadingVybeIndex == self.vybePlaylist.count) {
        return;
    }
    
    PFObject *aVybe = [self.vybePlaylist objectAtIndex:downloadingVybeIndex];
    NSURL *cacheURL = (NSURL *)[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
    cacheURL = [cacheURL URLByAppendingPathComponent:[aVybe objectId]];
    cacheURL = [cacheURL URLByAppendingPathExtension:@"mov"];

    if ([[NSFileManager defaultManager] fileExistsAtPath:[cacheURL path]]) {
        return;
    } else {
        PFFile *vid = [aVybe objectForKey:kVYBVybeVideoKey];
        [vid getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!error) {
                if (currVybeIndex == downloadingVybeIndex) {
                    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                    [data writeToURL:cacheURL atomically:YES];
                    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:cacheURL options:nil];
                    self.currItem = [AVPlayerItem playerItemWithAsset:asset];
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
                    [self.currPlayer replaceCurrentItemWithPlayerItem:self.currItem];
                    [self.currPlayer play];
                    [self syncUI:aVybe];
                    [self prepareVybeAt:downloadingVybeIndex + 1];
                }
            }
        }];
    }
}

- (void)playerItemDidReachEnd {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    if (currVybeIndex == self.vybePlaylist.count - 1) {
        // Reached the end show the ENDING screen
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
    [self.currPlayer pause];
    currVybeIndex++;
    [self beginPlayingFrom:currVybeIndex];
}

- (void)syncUI:(PFObject *)aVybe {
    currentTribeLabel.text = [[aVybe objectForKey:kVYBVybeTribeKey] objectForKey:kVYBTribeNameKey];
    locationLabel.text = [aVybe objectForKey:kVYBVybeLocationName];
    timeLabel.text = [VYBUtility localizedDateStringFrom:[aVybe objectForKey:kVYBVybeTimestampKey]];
    usernameButton.titleLabel.text = [[aVybe objectForKey:kVYBVybeUserKey] objectForKey:kVYBUserDisplayNameKey];
}


/**
 * User Interactions
 **/

- (void)swipeLeft {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    if (currVybeIndex == self.vybePlaylist.count - 1) {
        // Reached the end show the ENDING screen
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
    [self.currPlayer pause];
    currVybeIndex++;
    [self beginPlayingFrom:currVybeIndex];
}

- (void)swipeRight {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    if (currVybeIndex == 0) {
        // Reached the beginning show the BEGINNING screen
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
    [self.currPlayer pause];
    currVybeIndex--;
    [self beginPlayingFrom:currVybeIndex];
}

- (void)tapOnce {
    if (self.currPlayer.rate != 0) {
        [self.currPlayer pause];
        pauseImageView.hidden = NO;
    } else {
        pauseImageView.hidden = YES;
        [self.currPlayer play];
    }
}

- (void)captureVybe:(id)sender {
    PFObject *currVybe = self.vybePlaylist[currVybeIndex];
    [[VYBCache sharedCache] setSyncTribe:currVybe[kVYBVybeTribeKey] user:[PFUser currentUser]];
    
    if (self.currPlayer.rate != 0) {
        [self.currPlayer pause];
        pauseImageView.hidden = NO;
    }
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
    
    VYBCaptureViewController *captureVC = [[VYBCaptureViewController alloc] init];
    [self presentViewController:captureVC animated:NO completion:nil];
}

- (void)dismissButtonPressed:(id)sender {
    PFObject *currVybe = [self.vybePlaylist objectAtIndex:currVybeIndex];
    if (self.parentVC) {
        if ([self.parentVC respondsToSelector:@selector(setLastWatchedVybe:)]) {
            // If PlayerVC's parent view controller is TribeTimelineVC
            [self.parentVC performSelector:@selector(setLastWatchedVybe:) withObject:currVybe];
        }
    }
    
    self.currPlayer = nil;
    self.currPlayerView.player = nil;
    self.currPlayerView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
    self.currItem = nil;
    
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

- (void)tribeTimelineButtonPressed:(id)sender {
    // If PlayerVC is presented by TribeTImelineVC, just dismiss
    if ([self.parentVC class] == [VYBTribeTimelineViewController class]) {
        [self dismissButtonPressed:sender];
    }
    else {
        VYBTribeTimelineViewController *tribeTimelineVC = [[VYBTribeTimelineViewController alloc] init];
        PFObject *currVybe = [self.vybePlaylist objectAtIndex:currVybeIndex];
        [tribeTimelineVC setTribe:currVybe[kVYBVybeTribeKey]];
        [tribeTimelineVC setLastWatchedVybe:currVybe];

        self.currPlayer = nil;
        self.currPlayerView.player = nil;
        self.currPlayerView = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
        self.currItem = nil;
        
        [self.presentingViewController dismissViewControllerAnimated:NO completion:^{
            // parentVC is set to a navigation controller
            if ([self.parentVC respondsToSelector:@selector(pushViewController:animated:)]) {
                [self.parentVC pushViewController:tribeTimelineVC animated:NO];
            }
        }];
    }
}

- (void)usernameButtonPressed:(id)sender {
    
}

#pragma mark - UIInterfaceOrientation

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (void)deviceOrientationChanged:(NSNotification *)note {
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
