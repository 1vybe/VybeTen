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
@property (nonatomic, strong) VYBLabel *privateCountLabel;
@property (nonatomic, strong) UIButton *privateViewButton;

@end

@implementation VYBPlayerViewController {
    NSInteger pageIndex;
    
    NSInteger currVybeIndex;
    NSInteger downloadingVybeIndex;
    
    UIView *backgroundView;
    UIButton *captureButton;
    UIImageView *pauseImageView;
    UILabel *locationLabel;
    UILabel *timeLabel;
    
    VYBTimerView *timerView;
    
    
}

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

    [playerView setFrame:CGRectMake(0, 0, backgroundView.bounds.size.height, backgroundView.bounds.size.width)];

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
    
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
    [self.view addSubview:pauseImageView];
    pauseImageView.hidden = YES;
    
    // Adding PRIVATE view button
    frame = CGRectMake(self.view.bounds.size.height - 70, 0, 70, 70);
    self.privateViewButton = [[UIButton alloc] initWithFrame:frame];
    [self.privateViewButton setImage:[UIImage imageNamed:@"button_private_view.png"] forState:UIControlStateNormal];
    [self.privateViewButton setImage:[UIImage imageNamed:@"button_private_view_new.png"] forState:UIControlStateSelected];
    [self.privateViewButton addTarget:self action:@selector(privateViewButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.privateViewButton setContentMode:UIViewContentModeLeft];
    [self.view addSubview:self.privateViewButton];
    // Adding PRIVATE count label
    frame = CGRectMake(self.view.bounds.size.height - 70, 0, 70, 70);
    self.privateCountLabel = [[VYBLabel alloc] initWithFrame:frame];
    [self.privateCountLabel setTextAlignment:NSTextAlignmentCenter];
    [self.privateCountLabel setFont:[UIFont fontWithName:@"AvenirLTStd-Book.otf" size:20.0]];
    [self.privateCountLabel setTextColor:[UIColor whiteColor]];
    self.privateCountLabel.userInteractionEnabled = NO;
    [self.view addSubview:self.privateCountLabel];
    
    // Adding USERNAME label
    frame = CGRectMake(18, self.view.bounds.size.width - 70, 150, 70);
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.isPublicMode) {
        // Deep sky blue
        [backgroundView setBackgroundColor:[UIColor colorWithRed:0.0 green:191.0/255.0 blue:1.0 alpha:1.0]];
    } else {
        [backgroundView setBackgroundColor:[UIColor orangeColor]];
    }

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
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    if (!self.isPublicMode) {
        NSString *functionName = @"get_tribe_vybes";
        PFGeoPoint *geoPoint = [PFGeoPoint geoPoint];
        
        [PFCloud callFunctionInBackground:functionName withParameters:@{@"location": geoPoint, @"startTime": [[VYBUserStore sharedStore] lastWatchedVybeTimeStamp]} block:^(NSArray *vybes, NSError *error) {
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
    } else {
        if (self.currCity) {
            NSString *functionName = @"get_city_vybes";
            [PFCloud callFunctionInBackground:functionName withParameters:@{@"cityID": self.currCity.objectId} block:^(NSArray *vybes, NSError *error) {
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
        else {
            NSString *functionName = @"default_algorithm";
            PFGeoPoint *geoPoint = [PFGeoPoint geoPoint];
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
}

- (void)beginPlayingFrom:(NSInteger)from {
    currVybeIndex = from;
    downloadingVybeIndex = currVybeIndex + 1;
    
    PFObject *currVybe = [self.vybePlaylist objectAtIndex:currVybeIndex];
   
    // Keep track of the last vybe watched (for private ONLY)
    if ( ![[currVybe objectForKey:kVYBVybeTypePublicKey] boolValue] ) {
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
    }
    
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
        [vid getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
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
                [locationLabel setNeedsDisplay];
            }
        }];
    } else {
        locationLabel.text = @"";
    }
    
    if ([aVybe objectForKey:kVYBVybeUserKey]) {
        PFUser *aUser = [aVybe objectForKey:kVYBVybeUserKey];
        [aUser fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error) {
                self.usernameLabel.text = [object objectForKey:kVYBUserUsernameKey];
            }
        }];
    }
    
    timeLabel.text = [VYBUtility reverseTime:[aVybe objectForKey:kVYBVybeTimestampKey]];
}


/**
 * User Interactions
 **/

- (void)captureButtonPressed:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)privateViewButtonPressed:(id)sender {
    self.isPublicMode = NO;
    [self loadVybes];
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
    [[VYBUserStore sharedStore] saveChanges];
}

@end
