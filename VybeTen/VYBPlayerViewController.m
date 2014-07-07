//
//  VYBPlayerViewController.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 6..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBPlayerViewController.h"
#import "VYBCaptureViewController.h"
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
    
    UIButton *captureButton;
    
    UIImageView *pauseImageView;
    
    UILabel *locationLabel;
    UILabel *timeLabel;
    
    PFObject *freshVybe;
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
    
    // Hide status bar
    [self setNeedsStatusBarAppearanceUpdate];
    
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
    // Adding CAPTURE button
    CGRect frame = CGRectMake(self.view.bounds.size.height - 50, (self.view.bounds.size.width - 50)/2, 50, 50);
    captureButton = [[UIButton alloc] initWithFrame:frame];
    [captureButton setContentMode:UIViewContentModeCenter];
    [captureButton setImage:[UIImage imageNamed:@"button_player_capture.png"] forState:UIControlStateNormal];
    [captureButton addTarget:self action:@selector(captureVybe:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:captureButton];
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

    frame = CGRectMake(self.view.bounds.size.height/2 - 20, self.view.bounds.size.width/2 - 20, 40, 40);
    pauseImageView = [[UIImageView alloc] initWithFrame:frame];
    [pauseImageView setImage:[UIImage imageNamed:@"button_player_pause.png"]];
    [pauseImageView setContentMode:UIViewContentModeCenter];
    NSLog(@"pause imageview BEFORE: %@", NSStringFromCGRect(pauseImageView.frame));
    [self.view addSubview:pauseImageView];
    pauseImageView.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (freshVybe) {
        [PFCloud callFunctionInBackground:@"closestVybes" withParameters:@{@"location": freshVybe[kVYBVybeGeotag]} block:^(NSArray *vybes, NSError *error) {
            if (!error) {
                if (vybes && vybes.count > 0) {
                    self.vybePlaylist = vybes;
                    [self beginPlayingFrom:0];
                }
            } else {
                
            }
        }];
    }
    
    else {
        [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
            if (error || !geoPoint) {
                NSLog(@"Cannot retrive current location at this moment.");
            } else {
                [PFCloud callFunctionInBackground:@"closestVybes" withParameters:@{@"location": geoPoint} block:^(NSArray *vybes, NSError *error) {
                    if (!error) {
                        if (vybes && vybes.count > 0) {
                            self.vybePlaylist = vybes;
                            [self beginPlayingFrom:0];
                        }
                    } else {
                        
                    }
                }];

            }
        }];
    }
    
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
    locationLabel.text = [aVybe objectForKey:kVYBVybeLocationName];
    timeLabel.text = [VYBUtility localizedDateStringFrom:[aVybe objectForKey:kVYBVybeTimestampKey]];
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
    //TODO: Based on what the user was watching, attach some information regarding that when the user take the next vybe
    
    [self.currPlayer pause];
    
    VYBCaptureViewController *captureVC = [[VYBCaptureViewController alloc] init];
    captureVC.delegate = self;
    [self.navigationController pushViewController:captureVC animated:NO];
}

#pragma mark - VYBCaptureViewControllerDelegate

- (void)capturedVybe:(PFObject *)aVybe {
    freshVybe = aVybe;
}

#pragma mark - UIInterfaceOrientation

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (void)deviceOrientationChanged:(NSNotification *)note {

}

- (BOOL)prefersStatusBarHidden {
    return YES;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
