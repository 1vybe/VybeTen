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
#import "AVAsset+VideoOrientation.h"
#import "VYBUtility.h"
#import "VYBCache.h"
#import "VYBPlayerView.h"
#import "VYBTimerView.h"
#import "VYBLabel.h"
#import "VYBConstants.h"
#import "VYBUserStore.h"
#import "VYBDynamicSizeView.h"
#import <GAI.h>
#import <GAITracker.h>
#import <GAIFields.h>
#import <GAIDictionaryBuilder.h>

@interface VYBPlayerViewController ()
@property (nonatomic, weak) IBOutlet VYBDynamicSizeView *overlayView;
@property (nonatomic, weak) IBOutlet UIButton *goPreviousButton;
@property (nonatomic, weak) IBOutlet UIButton *goNextButton;
@property (nonatomic, weak) IBOutlet UIButton *likeButton;
@property (nonatomic, weak) IBOutlet UIButton *pauseButton;
@property (nonatomic, weak) IBOutlet UILabel *usernameLabel;
@property (nonatomic, weak) IBOutlet PFImageView *profileImageView;
@property (nonatomic, weak) IBOutlet UIImageView *funnySquareFrame;
@property (nonatomic, weak) IBOutlet UIImageView *countryFlagImageView;
@property (nonatomic, weak) IBOutlet UILabel *cityNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *countLabel;
@property (nonatomic, weak) IBOutlet UIButton *dismissButton;

- (IBAction)dismissButtonPressed:(id)sender;
- (IBAction)likeButtonPressed:(id)sender;
- (IBAction)goPreviousButtonPressed:(id)sender;
- (IBAction)goNextButtonPressed:(id)sender;
- (IBAction)pauseButtonPressed:(id)sender;

@property (nonatomic, weak) IBOutlet VYBPlayerView *currPlayerView;
@property (nonatomic) AVPlayer *currPlayer;
@property (nonatomic) AVPlayerItem *currItem;
@property (nonatomic) NSInteger debugMode;

@end

@implementation VYBPlayerViewController {
    AVCaptureVideoOrientation lastOrientation;
    NSInteger downloadingVybeIndex;
    
    UIView *backgroundView;
    VYBTimerView *timerView;
    
    BOOL menuMode;
    NSTimer *overlayTimer;
}

@synthesize currVybeIndex;
@synthesize currPlayer = _currPlayer;
@synthesize currPlayerView = _currPlayerView;
@synthesize currItem = _currItem;
@synthesize usernameLabel, profileImageView, funnySquareFrame, countryFlagImageView, cityNameLabel, countLabel, dismissButton, goNextButton, goPreviousButton, likeButton, overlayView;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBAppDelegateApplicationDidReceiveRemoteNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBAppDelegateApplicationDidBecomeActive object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)loadView {
    [super loadView];

    //VYBPlayerView *playerView = [[VYBPlayerView alloc] init];
    //[playerView setFrame:[[UIScreen mainScreen] bounds]];
    //self.currPlayerView = playerView;
    
    self.currPlayer = [[AVPlayer alloc] init];
    [self.currPlayerView setPlayer:self.currPlayer];
    //[self.view insertSubview:self.currPlayerView atIndex:0];
    
    lastOrientation = AVCaptureVideoOrientationPortrait;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    menuMode = NO;
    [self syncUIElementsWithMenuMode];
    
    // Hide status bar
    [self setNeedsStatusBarAppearanceUpdate];
    
    // AppDelegate Notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteNotificationReceived:) name:VYBAppDelegateApplicationDidReceiveRemoteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActiveNotificationReceived:) name:VYBAppDelegateApplicationDidBecomeActive object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceRotated:) name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
    
    // One tap pops up overlay
    UITapGestureRecognizer *tapOnce = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnce)];
    tapOnce.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapOnce];
    
    // Add DELETE gesture
    UITapGestureRecognizer *tapTwice = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapTwice)];
    tapTwice.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:tapTwice];
 

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
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
    } else if (self.vybePlaylist){
        currVybeIndex = 0;
        [self beginPlayingFrom:currVybeIndex];
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
    
    self.countLabel.text = [NSString stringWithFormat:@"%ld", (long)self.vybePlaylist.count - currVybeIndex - 1];
    
    downloadingVybeIndex = currVybeIndex + 1;
    
    PFObject *currVybe = [self.vybePlaylist objectAtIndex:currVybeIndex];
    
    NSURL *cacheURL = (NSURL *)[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
    cacheURL = [cacheURL URLByAppendingPathComponent:[currVybe objectId]];
    cacheURL = [cacheURL URLByAppendingPathExtension:@"mov"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[cacheURL path]]) {
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:cacheURL options:nil];

        [self syncUIElementsForOrientation:[asset videoOrientation]];
        
        self.currItem = [AVPlayerItem playerItemWithAsset:asset];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
        [self.currPlayer replaceCurrentItemWithPlayerItem:self.currItem];
        [self.currPlayer play];
        [[VYBCache sharedCache] removeFreshVybe:currVybe];
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
               
                [self syncUIElementsForOrientation:[asset videoOrientation]];

                self.currItem = [AVPlayerItem playerItemWithAsset:asset];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
                [self.currPlayer replaceCurrentItemWithPlayerItem:self.currItem];
                [self.currPlayer play];
                [[VYBCache sharedCache] removeFreshVybe:currVybe];
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

                    [self syncUIElementsForOrientation:[asset videoOrientation]];

                    self.currItem = [AVPlayerItem playerItemWithAsset:asset];
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
                    [self.currPlayer replaceCurrentItemWithPlayerItem:self.currItem];
                    [self.currPlayer play];
                    [[VYBCache sharedCache] removeFreshVybe:aVybe];
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
    
    NSString *locationStr = aVybe[kVYBVybeLocationStringKey];
    NSArray *arr = [locationStr componentsSeparatedByString:@","];
    NSString *countryCode = @"";
    self.cityNameLabel.text = @"";
    if (arr.count == 3) {
        countryCode = arr[2];
        cityNameLabel.text = arr[1];
    } else if (aVybe[kVYBVybeCountryCodeKey]) {
        countryCode = aVybe[kVYBVybeCountryCodeKey];
    }
    UIImage *countryFlagImg = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", countryCode]];
    if (countryFlagImg) {
        self.countryFlagImageView.image = countryFlagImg;
    }
    
    self.usernameLabel.text = @"";
    if ([aVybe objectForKey:kVYBVybeUserKey]) {
        PFUser *aUser = [aVybe objectForKey:kVYBVybeUserKey];
        [aUser fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error) {
                self.usernameLabel.text = [object objectForKey:kVYBUserUsernameKey];
                PFFile *profileFile = aUser[kVYBUserProfilePicMediumKey];
                self.profileImageView.file = profileFile;
                [self.profileImageView loadInBackground];
            }
        }];
    }
    
}


/**
 * User Interactions
 **/

- (IBAction)dismissButtonPressed:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)likeButtonPressed:(id)sender {
    PFObject *aVybe = [self.vybePlaylist objectAtIndex:self.currVybeIndex];
    [VYBUtility likeVybeInBackground:aVybe block:^(BOOL succeeded, NSError *error) {
    
    }];
}


- (IBAction)goNextButtonPressed:(id)sender {
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

- (IBAction)goPreviousButtonPressed:(id)sender {
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

- (IBAction)pauseButtonPressed:(id)sender {
    if (self.currPlayer.rate == 0.0) {
        [self.currPlayer play];
    }
    else {
        [self.currPlayer pause];
    }
}

- (void)tapOnce {
    if (!menuMode) {
        overlayTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(overlayTimerExpired:) userInfo:nil repeats:NO];
    } else {
        [overlayTimer invalidate];
    }
    
    menuMode = !menuMode;
    [self syncUIElementsWithMenuMode];
}

- (void)overlayTimerExpired:(NSTimer *)timer {
    if (menuMode) {
        menuMode = !menuMode;
        [self syncUIElementsWithMenuMode];
    }
}

- (void)syncUIElementsWithMenuMode {
    goPreviousButton.hidden = menuMode;
    goNextButton.hidden = menuMode;
    likeButton.hidden = menuMode;
    
    overlayView.hidden = !menuMode;
}

- (void)tapTwice {
    if (self.currPlayer.rate != 0.0) {
        [self.currPlayer pause];
    }
    UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"This vybe will be gone." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"DELETE", nil];
    [deleteAlert show];
}


#pragma mark - DeviceOrientation

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


- (void)deviceRotated:(NSNotification *)notification {
    UIDeviceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
    double rotation = 0;
    CGRect bounds;
    switch (currentOrientation) {
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationUnknown:
            return;
        case UIDeviceOrientationPortrait:
            rotation = 0;
            bounds = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            rotation = M_PI;
            bounds = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
            break;
        case UIDeviceOrientationLandscapeLeft:
            rotation = M_PI_2;
            bounds = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
            break;
        case UIDeviceOrientationLandscapeRight:
            rotation = -M_PI_2;
            bounds = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
            break;
    }
    
    [overlayView setOrientation:currentOrientation];
    CGAffineTransform transform = CGAffineTransformMakeRotation(rotation);
    
    [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.goNextButton.transform = transform;
        self.goPreviousButton.transform = transform;
        self.likeButton.transform = transform;
    } completion:nil];
}

- (void)syncUIElementsForOrientation:(NSInteger)orientation {
    [self.currPlayerView setOrientation:orientation];
}

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
        //[self.privateCountLabel setText:[NSString stringWithFormat:@"%d", (int)[[VYBUserStore sharedStore] newPrivateVybeCount]]];
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
                            //[self.privateCountLabel setText:[NSString stringWithFormat:@"%d", number]];
                            [[VYBUserStore sharedStore] setNewPrivateVybeCount:number];
                        }
                    }
                }];
            }
        }];
    }
}



#pragma mark - ()

- (BOOL)prefersStatusBarHidden {
    return YES;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [[VYBUserStore sharedStore] saveChanges];
}

@end
