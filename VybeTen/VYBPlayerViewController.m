    //
//  VYBPlayerViewController.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 6..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBAppDelegate.h"
#import "VYBPlayerViewController.h"
#import "VYBCaptureViewController.h"
#import "VYBLogInViewController.h"
#import "VYBUtility.h"
#import "VYBCache.h"
#import "VYBPlayerView.h"
#import "VYBTimerView.h"
#import "VYBLabel.h"
#import "VYBConstants.h"
#import "MBProgressHUD.h"
#import <GAI.h>
#import <GAITracker.h>
#import <GAIFields.h>
#import <GAIDictionaryBuilder.h>

@implementation VYBPlayerViewController {
    NSInteger pageIndex;
    
    NSInteger currVybeIndex;
    NSInteger downloadingVybeIndex;
    
    UIButton *captureButton;
    
    UIImageView *pauseImageView;
    
    UILabel *locationLabel;
    UILabel *timeLabel;
    
    VYBTimerView *timerView;
    
    PFObject *freshVybe;
}

@synthesize currPlayer = _currPlayer;
@synthesize currPlayerView = _currPlayerView;
@synthesize currItem = _currItem;


+ (VYBPlayerViewController *)playerViewControllerForPageIndex:(NSInteger)idx {
    if (idx >= 0 && idx < 2) {
        return [[self alloc] initWithPageIndex:idx];
    }
    return nil;
}

- (id)initWithPageIndex:(NSInteger)idx {
    self = [super init];
    if (self) {
        pageIndex = idx;
    }
    return self;
}

- (NSInteger)pageIndex {
    return pageIndex;
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

    UITapGestureRecognizer *tapOnce = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnce)];
    tapOnce.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapOnce];
    
#if DEBUG
    // Add DELETE gesture
    UITapGestureRecognizer *tapTwice = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapTwice)];
    tapTwice.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:tapTwice];
    
    // Add Logout gesture
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressedDetected:)];
    longPress.minimumPressDuration = 1;
    longPress.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:longPress];
    
    
#endif
    
    // Adding TIME label
    CGRect frame = CGRectMake(self.view.bounds.size.height/2 - 100, self.view.bounds.size.width - 70, 200, 70);
    timeLabel = [[VYBLabel alloc] initWithFrame:frame];
    [timeLabel setTextColor:[UIColor whiteColor]];
    [timeLabel setFont:[UIFont fontWithName:@"AvenirLTStd-Book.otf" size:18.0]];
    [timeLabel setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:timeLabel];
    // Adding LOCATION label
    frame = CGRectMake(self.view.bounds.size.height/2 - 150, 0, 300, 50);
    locationLabel = [[VYBLabel alloc] initWithFrame:frame];
    [locationLabel setTextColor:[UIColor whiteColor]];
    [locationLabel setFont:[UIFont fontWithName:@"AvenirLTStd-Book" size:18.0]];
    [locationLabel setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:locationLabel];
    
    // Adding CAPTURE button
    
    frame = CGRectMake(self.view.bounds.size.height - 70, self.view.bounds.size.width - 70, 70, 70);
    captureButton = [[UIButton alloc] initWithFrame:frame];
    [captureButton setImage:[UIImage imageNamed:@"button_capture.png"] forState:UIControlStateNormal];
    [pauseImageView setContentMode:UIViewContentModeCenter];
    [captureButton addTarget:self action:@selector(captureButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:captureButton];
    
    
    frame = CGRectMake(self.view.bounds.size.height/2 - 20, self.view.bounds.size.width/2 - 20, 40, 40);
    pauseImageView = [[UIImageView alloc] initWithFrame:frame];
    [pauseImageView setImage:[UIImage imageNamed:@"button_player_pause.png"]];
    [pauseImageView setContentMode:UIViewContentModeCenter];
    //NSLog(@"pause imageview BEFORE: %@", NSStringFromCGRect(pauseImageView.frame));
    [self.view addSubview:pauseImageView];
    pauseImageView.hidden = YES;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSString *functionName = @"default_algorithm";
    
    if (!self.isPublicMode) {
        functionName = @"get_tribe_vybes";
    }

    self.screenName = @"Player Screen";
    
    // Google Anaylytics shit
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName
                                       value:@"Player Screen"];
        [[GAI sharedInstance].defaultTracker
     send:[[GAIDictionaryBuilder createAppView] build]];
    
/*
#if DEBUG
    if (self.debugMode == 1) {
        functionName = @"algorithm1";
    }
    if (self.debugMode == 2) {
        functionName = @"algorithm2";
    }
    if (self.debugMode == 3) {
        functionName = @"algorithm3";
    }
#endif
*/
    NSLog(@"endpoint function name is %@", functionName);
    if (freshVybe) {
        [PFCloud callFunctionInBackground:functionName withParameters:@{@"location": freshVybe[kVYBVybeGeotag]} block:^(NSArray *vybes, NSError *error) {
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
                [PFCloud callFunctionInBackground:functionName withParameters:@{@"location": geoPoint} block:^(NSArray *vybes, NSError *error) {
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
        [self.currPlayer pause];
    });
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
    if (currVybeIndex == self.vybePlaylist.count - 1) {
        return;
    } else {
        [self.currPlayer pause];
        currVybeIndex++;
        [self beginPlayingFrom:currVybeIndex];
    }
}

- (void)syncUI:(PFObject *)aVybe {
    if ([aVybe objectForKey:kVYBVybeGeotag]) {
        PFGeoPoint *geo = [aVybe objectForKey:kVYBVybeGeotag];
        [VYBUtility reverseGeoCode:geo withCompletion:^(NSArray *placemarks, NSError *error) {
            if (!error) {
                NSString *location = [VYBUtility convertPlacemarkToLocation:placemarks[0]];
                locationLabel.text = location;
                NSLog(@"Location Set");
                [locationLabel setNeedsDisplay];
            }
        }];
    } else {
        locationLabel.text = @"";
    }
    timeLabel.text = [VYBUtility reverseTime:[aVybe objectForKey:kVYBVybeTimestampKey]];
}


/**
 * User Interactions
 **/

- (void)captureButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}


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
    if (self.currPlayer.rate == 0.0) {
        [self.currPlayer play];
    }
    else {
        [self.currPlayer pause];
    }
}

#if DEBUG

- (void)tapTwice:(id)sender {
    NSString *deleteVybeFunction = @"delete_vybe";
    PFObject *currVybe = [self.vybePlaylist objectAtIndex:currVybeIndex];

    [PFCloud callFunctionInBackground:deleteVybeFunction withParameters:@{@"vybeID": currVybe.objectId} block:^(id object, NSError *error) {
        if (error) {
            
        } else {
            
        }
    }];
}

- (void)longPressDetected:(id)sender {
    UIAlertView *logOutAlert = [[UIAlertView alloc] initWithTitle:nil message:@"You are logging out" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    [logOutAlert show];
}

#endif


#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSLog(@"Logging out");
        [PFUser logOut];
        VYBLogInViewController *loginVC = [[VYBLogInViewController alloc] init];
        [self presentViewController:loginVC animated:NO completion:nil];
    } else {
        NSLog(@"Logging out cancelled");
    }
}

#pragma mark - VYBCaptureViewControllerDelegate

- (void)setFreshVybe:(PFObject *)aVybe {
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
