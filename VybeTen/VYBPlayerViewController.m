//
//  VYBPlayerViewController.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 6..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBAppDelegate.h"
#import "VYBDebugViewController.h"
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
    NSInteger pageIndex;
    
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
    UISwipeGestureRecognizer *swipeDown=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeDown)];
    swipeDown.direction=UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeDown];


#if DEBUG
    // Add tap gesture
    UITapGestureRecognizer *tapTwice = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapTwice)];
    tapTwice.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:tapTwice];
#endif
    
    // Adding TIME label
    CGRect frame = CGRectMake(self.view.bounds.size.height/2 - 100, self.view.bounds.size.width - 48, 200, 48);
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
    //NSLog(@"pause imageview BEFORE: %@", NSStringFromCGRect(pauseImageView.frame));
    [self.view addSubview:pauseImageView];
    pauseImageView.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSString *functionName = @"recentNearbyVybes";
    
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
    
    NSLog(@"function is %@", functionName);
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
    [self.currPlayer pause];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
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
        [self.navigationController popViewControllerAnimated:NO];
    } else {
        [self.currPlayer pause];
        currVybeIndex++;
        [self beginPlayingFrom:currVybeIndex];
    }
}

- (void)syncUI:(PFObject *)aVybe {
    locationLabel.text = [aVybe objectForKey:kVYBVybeLocationName];
    timeLabel.text = [VYBUtility localizedDateStringFrom:[aVybe objectForKey:kVYBVybeTimestampKey]];
}


/**
 * User Interactions
 **/

- (void)swipeDown {
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

#if DEBUG
- (void)tapTwice {
    VYBDebugViewController *debugVC = [[VYBDebugViewController alloc] init];
    debugVC.delegate = self;
    [self presentViewController:debugVC animated:NO completion:nil];
}
#endif

- (void)moveToCaptureScreen {
    //TODO: Based on what the user was watching, attach some information regarding that when the user take the next vybe
    
    //[self.currPlayer pause];
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];

    id appDelegate = (VYBAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate swipeToCaptureScreen];
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
