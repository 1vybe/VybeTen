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
#import "VYBUserStore.h"
#import <GAI.h>
#import <GAITracker.h>
#import <GAIFields.h>
#import <GAIDictionaryBuilder.h>

@interface VYBPlayerViewController ()

@property (nonatomic, strong) VYBLabel *usernameLabel;
@property (nonatomic, strong) UIButton *dismissButton;
@property (nonatomic, strong) VYBLabel *privateCountLabel;
@property (nonatomic, strong) UIButton *privateViewButton;
@property (nonatomic, strong) UILabel *locationLabel;
@property (nonatomic, strong) UILabel *timeLabel;

@end

@implementation VYBPlayerViewController {
    NSInteger pageIndex;
    
    NSInteger downloadingVybeIndex;
    
    UIView *backgroundView;
    UIButton *captureButton;
    UIImageView *pauseImageView;

    
    VYBTimerView *timerView;
    
    
}
@synthesize currVybeIndex;
@synthesize currPlayer = _currPlayer;
@synthesize currPlayerView = _currPlayerView;
@synthesize currItem = _currItem;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBAppDelegateApplicationDidReceiveRemoteNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBAppDelegateApplicationDidBecomeActive object:nil];

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
    backgroundView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view = backgroundView;
    
    VYBPlayerView *playerView = [[VYBPlayerView alloc] init];

    [playerView setFrame:[[UIScreen mainScreen] bounds]];
    NSLog(@"[PLAYER] UIScreen mainScreen bounds: %@", NSStringFromCGRect([[UIScreen mainScreen] bounds]));

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
    
    // AppDelegate Notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteNotificationReceived:) name:VYBAppDelegateApplicationDidReceiveRemoteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActiveNotificationReceived:) name:VYBAppDelegateApplicationDidBecomeActive object:nil];
    
    // responds to device orientation change
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceRotated:) name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
    
    // Adding swipe gestures
    UISwipeGestureRecognizer *swipeLeft=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeLeft)];
    swipeLeft.direction=UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeLeft];
    UISwipeGestureRecognizer *swipeRight=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeRight)];
    swipeRight.direction=UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRight];

    // PAUSE gesture
    UITapGestureRecognizer *tapOnce = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnce)];
    tapOnce.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapOnce];
    
    // Add DELETE gesture
    UITapGestureRecognizer *tapTwice = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapTwice)];
    tapTwice.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:tapTwice];
    
#if DEBUG
    // Add Logout gesture
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressDetected:)];
    longPress.numberOfTapsRequired = 1;
    longPress.minimumPressDuration = 1;
    [self.view addGestureRecognizer:longPress];
#endif
    
    // Adding TIME label
    CGRect frame = CGRectMake(self.view.bounds.size.width/2 - 50, self.view.bounds.size.height - 70, 140, 70);
    self.timeLabel = [[VYBLabel alloc] initWithFrame:frame];
    [self.timeLabel setTextColor:[UIColor whiteColor]];
    [self.timeLabel setFont:[UIFont fontWithName:@"AvenirLTStd-Book.otf" size:18.0]];
    [self.timeLabel setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:self.timeLabel];
    // Adding LOCATION label
    frame = CGRectMake(self.view.bounds.size.width/2 - 100, 0, 200, 70);
    self.locationLabel = [[VYBLabel alloc] initWithFrame:frame];
    [self.locationLabel setTextColor:[UIColor whiteColor]];
    [self.locationLabel setFont:[UIFont fontWithName:@"AvenirLTStd-Book" size:18.0]];
    [self.locationLabel setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:self.locationLabel];
    
    // Adding CAPTURE button
    frame = CGRectMake(self.view.bounds.size.width - 70, self.view.bounds.size.height - 70, 70, 70);
    captureButton = [[UIButton alloc] initWithFrame:frame];
    [captureButton setImage:[UIImage imageNamed:@"button_capture.png"] forState:UIControlStateNormal];
    [pauseImageView setContentMode:UIViewContentModeCenter];
    [captureButton addTarget:self action:@selector(captureButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    //[self.view addSubview:captureButton];
    
    frame = CGRectMake(self.view.bounds.size.width/2 - 50, self.view.bounds.size.height/2 - 50, 100, 100);
    pauseImageView = [[UIImageView alloc] initWithFrame:frame];
    [pauseImageView setImage:[UIImage imageNamed:@"button_player_pause.png"]];
    [pauseImageView setContentMode:UIViewContentModeCenter];
    //[self.view addSubview:pauseImageView];
    pauseImageView.hidden = YES;
    
    frame = CGRectMake(0, 0, 70, 70);
    self.dismissButton = [[UIButton alloc] initWithFrame:frame];
    [self.dismissButton setImage:[UIImage imageNamed:@"button_x.png"] forState:UIControlStateNormal];
    [self.dismissButton setContentMode:UIViewContentModeCenter];
    [self.dismissButton addTarget:self action:@selector(dismissButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.dismissButton];
    
    // Adding PRIVATE view button
    frame = CGRectMake(self.view.bounds.size.height - 70, 0, 70, 70);
    self.privateViewButton = [[UIButton alloc] initWithFrame:frame];
    [self.privateViewButton setImage:[UIImage imageNamed:@"button_private_view.png"] forState:UIControlStateNormal];
    [self.privateViewButton setImage:[UIImage imageNamed:@"button_private_view_new.png"] forState:UIControlStateSelected];
    [self.privateViewButton addTarget:self action:@selector(privateViewButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.privateViewButton setContentMode:UIViewContentModeLeft];
    //[self.view addSubview:self.privateViewButton];
    
    // Adding PRIVATE count label
    frame = CGRectMake(self.view.bounds.size.height - 70, 0, 70, 70);
    self.privateCountLabel = [[VYBLabel alloc] initWithFrame:frame];
    [self.privateCountLabel setTextAlignment:NSTextAlignmentCenter];
    [self.privateCountLabel setFont:[UIFont fontWithName:@"AvenirLTStd-Book.otf" size:20.0]];
    [self.privateCountLabel setTextColor:[UIColor whiteColor]];
    self.privateCountLabel.userInteractionEnabled = NO;
    //[self.view addSubview:self.privateCountLabel];
    
    // Adding USERNAME label
    frame = CGRectMake(10, self.view.bounds.size.height - 70, 80, 70);
    self.usernameLabel = [[VYBLabel alloc] initWithFrame:frame];
    self.usernameLabel.font = [UIFont fontWithName:@"AvenirLTStd-Book.otf" size:18.0];
    self.usernameLabel.textAlignment = NSTextAlignmentLeft;
    self.usernameLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:self.usernameLabel];
    
    if ([[VYBUserStore sharedStore] newPrivateVybeCount] > 0) {
        [self.privateViewButton setSelected:YES];
        [self.privateCountLabel setText:[NSString stringWithFormat:@"%d", (int)[[VYBUserStore sharedStore] newPrivateVybeCount]]];
    } else {
        [self.privateViewButton setSelected:NO];
        [self.privateCountLabel setText:@""];
    }
    
    /*
    if ( [[PFUser currentUser] objectForKey:@"tribe"] ) {
        PFObject *myTribe = [[PFUser currentUser] objectForKey:@"tribe"];
        [myTribe fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error) {
                PFRelation *members = [object relationForKey:kVYBTribeMembersKey];
                PFQuery *countQuery = [PFQuery queryWithClassName:kVYBVybeClassKey];
                [countQuery whereKey:kVYBVybeUserKey matchesQuery:[members query]];
                [countQuery whereKey:kVYBVybeUserKey notEqualTo:[PFUser currentUser]];
                [countQuery whereKey:kVYBVybeTimestampKey greaterThan:[[VYBUserStore sharedStore] lastWatchedVybeTimeStamp]];
                [countQuery whereKey:kVYBVybeTypePublicKey equalTo:[NSNumber numberWithBool:NO]];
                [countQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                    if (!error) {
                        if (number > 0) {
                            [self.privateViewButton setSelected:YES];
                            [self.privateCountLabel setText:[NSString stringWithFormat:@"%d", number]];
                            [[VYBUserStore sharedStore] setNewPrivateVybeCount:number];
                        }
                    }
                }];
            }
        }];
    }
    */
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [backgroundView setBackgroundColor:[UIColor orangeColor]];

    [self loadVybes];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
        [self.currPlayer pause];
    });
}

- (void)loadVybes {
    if (self.currRegion) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];

        NSString *functionName = @"get_region_vybes";
        [PFCloud callFunctionInBackground:functionName withParameters:@{@"regionID": self.currRegion.objectId} block:^(NSArray *vybes, NSError *error) {
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            if (!error) {
                if (vybes && vybes.count > 0) {
                    self.vybePlaylist = vybes;
                    [self beginPlayingFrom:0];
                } else {
                    [[VYBUserStore sharedStore] setNewPrivateVybeCount:0];
                    PFInstallation *currentInstall = [PFInstallation currentInstallation];
                    currentInstall.badge = 0;
                    [currentInstall saveEventually];
                    
                    self.vybePlaylist = nil;
                }
            } else {
            }
        }];
    }
    else if (self.currUser) {
        if (self.vybePlaylist.count > 0) {
            [self beginPlayingFrom:currVybeIndex];
        }
    } else {
        NSString *functionName = @"default_algorithm";
        PFGeoPoint *geoPoint = [PFGeoPoint geoPoint];
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];

        [PFCloud callFunctionInBackground:functionName withParameters:@{@"location": geoPoint} block:^(NSArray *vybes, NSError *error) {
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            if (!error) {
                if (vybes && vybes.count > 0) {
                    self.vybePlaylist = vybes;
                    [self beginPlayingFrom:0];
                } else {
                    [[VYBUserStore sharedStore] setNewPrivateVybeCount:0];
                    PFInstallation *currentInstall = [PFInstallation currentInstallation];
                    currentInstall.badge = 0;
                    [currentInstall saveEventually];
                    
                    self.vybePlaylist = nil;
                }
            } else {
            }
        }];

    }
}

- (void)beginPlayingFrom:(NSInteger)from {
    currVybeIndex = from;
    downloadingVybeIndex = currVybeIndex + 1;
    
    PFObject *currVybe = [self.vybePlaylist objectAtIndex:currVybeIndex];
   
    if ([[[VYBUserStore sharedStore] lastWatchedVybeTimeStamp] compare:currVybe[kVYBVybeTimestampKey]] == NSOrderedAscending) {
        [[VYBUserStore sharedStore] setLastWatchedVybeTimeStamp:currVybe[kVYBVybeTimestampKey]];
        
        NSInteger newCount = [[VYBUserStore sharedStore] newPrivateVybeCount] - 1;
        if (newCount < 0)
            newCount = 0;
        [[VYBUserStore sharedStore] setNewPrivateVybeCount:newCount];
        
        if (newCount > 0) {
            [self.privateViewButton setSelected:YES];
            [self.privateCountLabel setText:[NSString stringWithFormat:@"%d", (int)newCount]];
        } else {
            [self.privateViewButton setSelected:NO];
            [self.privateCountLabel setText:@""];
        }

        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        currentInstallation.badge = [[VYBUserStore sharedStore] newPrivateVybeCount];
        [currentInstallation saveEventually];
    }
    
    NSURL *cacheURL = (NSURL *)[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
    cacheURL = [cacheURL URLByAppendingPathComponent:[currVybe objectId]];
    cacheURL = [cacheURL URLByAppendingPathExtension:@"mov"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[cacheURL path]]) {
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:cacheURL options:nil];
        CGAffineTransform firstTransform = asset.preferredTransform;
        
        if(firstTransform.a == 0 && firstTransform.b == 1.0 && firstTransform.c == -1.0 && firstTransform.d == 0)
        {
            NSLog(@"orientation RIGHT");
        }
        if(firstTransform.a == 0 && firstTransform.b == -1.0 && firstTransform.c == 1.0 && firstTransform.d == 0)
        {
            NSLog(@"orientation LEFT");
        }
        if(firstTransform.a == 1.0 && firstTransform.b == 0 && firstTransform.c == 0 && firstTransform.d == 1.0)
        {
            NSLog(@"orientation UP");
        }
        if(firstTransform.a == -1.0 && firstTransform.b == 0 && firstTransform.c == 0 && firstTransform.d == -1.0)
        {
            NSLog(@"orientation DOWN");
        }
        self.currItem = [AVPlayerItem playerItemWithAsset:asset];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
        [self.currPlayer replaceCurrentItemWithPlayerItem:self.currItem];
        [self.currPlayer play];
        [self syncUI:currVybe];
        [self prepareVybeAt:downloadingVybeIndex];
    } else {
        PFFile *vid = [currVybe objectForKey:kVYBVybeVideoKey];
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [vid getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            if (!error) {
                [data writeToURL:cacheURL atomically:YES];
                AVURLAsset *asset = [AVURLAsset URLAssetWithURL:cacheURL options:nil];
                CGAffineTransform firstTransform = asset.preferredTransform;
                
                if(firstTransform.a == 0 && firstTransform.b == 1.0 && firstTransform.c == -1.0 && firstTransform.d == 0)
                {
                    NSLog(@"orientation RIGHT");
                }
                if(firstTransform.a == 0 && firstTransform.b == -1.0 && firstTransform.c == 1.0 && firstTransform.d == 0)
                {
                    NSLog(@"orientation LEFT");
                }
                if(firstTransform.a == 1.0 && firstTransform.b == 0 && firstTransform.c == 0 && firstTransform.d == 1.0)
                {
                    NSLog(@"orientation UP");
                }
                if(firstTransform.a == -1.0 && firstTransform.b == 0 && firstTransform.c == 0 && firstTransform.d == -1.0)
                {
                    NSLog(@"orientation DOWN");
                }
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
    self.locationLabel.text = @"";
    self.usernameLabel.text = @"";

    if ([aVybe objectForKey:kVYBVybeGeotag]) {
        PFGeoPoint *geo = [aVybe objectForKey:kVYBVybeGeotag];
        [VYBUtility reverseGeoCode:geo withCompletion:^(NSArray *placemarks, NSError *error) {
            if (!error) {
                NSString *location = [VYBUtility convertPlacemarkToLocation:placemarks[0]];
                self.locationLabel.text = location;
                [self.locationLabel setNeedsDisplay];
            }
        }];
    }
    
    if ([aVybe objectForKey:kVYBVybeUserKey]) {
        PFUser *aUser = [aVybe objectForKey:kVYBVybeUserKey];
        [aUser fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error) {
                self.usernameLabel.text = [object objectForKey:kVYBUserUsernameKey];
            }
        }];
    }
    
    self.timeLabel.text = [VYBUtility reverseTime:[aVybe objectForKey:kVYBVybeTimestampKey]];
}


/**
 * User Interactions
 **/

- (void)captureButtonPressed:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)privateViewButtonPressed:(id)sender {
    [self loadVybes];
}

- (void)dismissButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)swipeLeft {
    //[MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    if (!self.vybePlaylist) {
        return;
    }
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
    //[MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    if (!self.vybePlaylist) {
        return;
    }
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

- (void)tapTwice {
    if (self.currPlayer.rate != 0.0) {
        [self.currPlayer pause];
    }
    UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"This vybe will be gone." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"DELETE", nil];
    [deleteAlert show];
}

- (void)tapThree {
    UIAlertView *logOutAlert = [[UIAlertView alloc] initWithTitle:nil message:@"You are logging out" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    [logOutAlert show];
}

#if DEBUG
- (void)longPressDetected:(id)sender {
    UIAlertView *logOutAlert = [[UIAlertView alloc] initWithTitle:nil message:@"You are logging out" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    [logOutAlert show];
}
#endif

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        if (alertView.title) {
            PFObject *currVybe = [self.vybePlaylist objectAtIndex:currVybeIndex];
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [currVybe deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                if (!error) {
                    [VYBUtility showToastWithImage:[UIImage imageNamed:@"button_check.png"] title:@"Deleted"];
                } else {
                    [VYBUtility showToastWithImage:[UIImage imageNamed:@"button_x.png"] title:@"Failed"];
                }
            }];
        } else {
            NSLog(@"Logging out");
            
            // clear cache
            [[VYBCache sharedCache] clear];
            
            // Unsubscribe from push notifications by removing the user association from the current installation.
            [[PFInstallation currentInstallation] removeObjectForKey:@"user"];
            [[PFInstallation currentInstallation] saveInBackground];
            
            // Clear all caches
            [PFQuery clearAllCachedResults];

            [PFUser logOut];
            VYBLogInViewController *loginVC = [[VYBLogInViewController alloc] init];
            [self presentViewController:loginVC animated:NO completion:nil];
        }
    }
}


#pragma mark - VYBAppDelegateNotification

- (void)remoteNotificationReceived:(id)sender {
    if ([[VYBUserStore sharedStore] newPrivateVybeCount] > 0) {
        [self.privateViewButton setSelected:YES];
        [self.privateCountLabel setText:[NSString stringWithFormat:@"%d", (int)[[VYBUserStore sharedStore] newPrivateVybeCount]]];
    }
}

- (void)applicationDidBecomeActiveNotificationReceived:(id)sender {
    if ( [[PFUser currentUser] objectForKey:@"tribe"] ) {
        PFObject *myTribe = [[PFUser currentUser] objectForKey:@"tribe"];
        [myTribe fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error) {
                PFRelation *members = [object relationForKey:kVYBTribeMembersKey];
                PFQuery *countQuery = [PFQuery queryWithClassName:kVYBVybeClassKey];
                [countQuery whereKey:kVYBVybeUserKey matchesQuery:[members query]];
                [countQuery whereKey:kVYBVybeUserKey notEqualTo:[PFUser currentUser]];
                [countQuery whereKey:kVYBVybeTimestampKey greaterThan:[[VYBUserStore sharedStore] lastWatchedVybeTimeStamp]];
                [countQuery whereKey:kVYBVybeTypePublicKey equalTo:[NSNumber numberWithBool:NO]];
                [countQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                    if (!error) {
                        if (number > 0) {
                            [self.privateViewButton setSelected:YES];
                            [self.privateCountLabel setText:[NSString stringWithFormat:@"%d", number]];
                            [[VYBUserStore sharedStore] setNewPrivateVybeCount:number];
                        }
                    }
                }];
            }
        }];
    }
}


#pragma mark - DeviceOrientation

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)deviceRotated:(NSNotification *)notification {
    UIDeviceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
    double rotation = 0;
    switch (currentOrientation) {
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationUnknown:
            return;
        case UIDeviceOrientationPortrait:
            rotation = 0;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            rotation = -M_PI;
            break;
        case UIDeviceOrientationLandscapeLeft:
            rotation = M_PI_2;
            break;
        case UIDeviceOrientationLandscapeRight:
            rotation = -M_PI_2;
            break;
    }
    
    CGAffineTransform transform = CGAffineTransformMakeRotation(rotation);
    [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.dismissButton.transform = transform;
        self.locationLabel.transform = transform;
        self.timeLabel.transform = transform;
        self.usernameLabel.transform = transform;
    } completion:nil];
    
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [[VYBUserStore sharedStore] saveChanges];
}

@end
