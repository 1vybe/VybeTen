//
//  VYBPlayerViewController.m
//  VybeTen
//
//  Created by jinsuk on 10/6/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

//TODO: Manage a pool to asynchronously download vybes using a queue
#import "VYBPlayerViewController.h"
#import <MotionOrientation@PTEz/MotionOrientation.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "AVAsset+VideoOrientation.h"
#import "VYBAppDelegate.h"
#import "VYBPlayerView.h"
#import "VYBUtility.h"
#import "VYBCache.h"
#import "VYBConstants.h"
#import "VYBActiveButton.h"
#import "NSArray+PFObject.h"

@interface VYBPlayerViewController ()
@property (nonatomic, weak) IBOutlet UILabel *locationLabel;
@property (nonatomic, weak) IBOutlet UIButton *userButton;
@property (nonatomic, weak) IBOutlet UILabel *timeLabel;
@property (nonatomic, weak) IBOutlet UIButton *mapButton;
@property (nonatomic, weak) IBOutlet UIButton *dismissButton;
@property (nonatomic, weak) IBOutlet UIButton *goPrevButton;
@property (nonatomic, weak) IBOutlet UIButton *goNextButton;

- (IBAction)goNextButtonPressed:(id)sender;
- (IBAction)goPrevButtonPressed:(id)sender;

- (IBAction)dismissButtonPressed;

@property (nonatomic, weak) VYBPlayerView *currPlayerView;
@property (nonatomic) AVPlayer *currPlayer;
@property (nonatomic) AVPlayerItem *currItem;

- (void)playAsset:(AVAsset *)asset;

@end


@implementation VYBPlayerViewController {
    NSInteger downloadingVybeIndex;
    BOOL menuMode;
    NSTimer *overlayTimer;
    
    NSInteger _pageIndex;
    NSArray *_zoneVybes;
    NSInteger _zoneCurrIdx;
    
    AVCaptureVideoOrientation lastOrientation;
    
    UIView *backgroundView;
    
    BOOL _isPlaying;
}
@synthesize dismissButton;

@synthesize currPlayer = _currPlayer;
@synthesize currPlayerView = _currPlayerView;
@synthesize currItem = _currItem;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBAppDelegateApplicationDidReceiveRemoteNotification object:nil];
}

- (id)initWithPageIndex:(NSInteger)pageIndex {
    self = [super init];
    if (self) {
        _pageIndex = pageIndex;
    }
    return self;
}

- (NSInteger)pageIndex {
    return _pageIndex;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set up player view
    VYBPlayerView *playerView = [[VYBPlayerView alloc] init];
    [playerView setFrame:[[UIScreen mainScreen] bounds]];
    self.currPlayerView = playerView;
    
    self.currPlayer = [[AVPlayer alloc] init];
    [playerView setPlayer:self.currPlayer];
    
    [self.view insertSubview:playerView atIndex:0];

    // Add gestures on screen
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnce)];
    tapGesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapGesture];
    
    [self showOverlayMenu:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
    [self.currPlayer pause];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ( _zoneVybes ) {
        [self playStream:_zoneVybes atIndex:_zoneCurrIdx];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    if (self.currPlayer && self.currItem) {
        [self.currPlayer play];
    }
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker) {
        [tracker set:kGAIScreenName
               value:@"Player Screen"];
        
        [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    }
}

- (void)prepareFirstVideoInBackgroundWithCompletion:(void (^)(BOOL))completionBlock {
    PFObject *firstVideo = _zoneVybes[0];
    NSURL *cacheURL = (NSURL *)[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
    cacheURL = [cacheURL URLByAppendingPathComponent:[firstVideo objectId]];
    cacheURL = [cacheURL URLByAppendingPathExtension:@"mov"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[cacheURL path]]) {
        completionBlock(YES);
    }
    else {
        PFFile *vid = [firstVideo objectForKey:kVYBVybeVideoKey];
        [vid getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!error) {
                [data writeToURL:cacheURL atomically:YES];
                completionBlock(YES);
            }
            else {
                completionBlock(NO);
            }
        }];
    }
}

- (void)playZoneVybesFromVybe:(PFObject *)aVybe {
    
    NSString *zoneID;
    if (aVybe[kVYBVybeZoneIDKey] == nil) {
        zoneID = @"";
    } else {
        zoneID = aVybe[kVYBVybeZoneIDKey];
    }
    
    [PFCloud callFunctionInBackground:@"get_vybes_in_zone"
                       withParameters:@{ @"vybeID" : aVybe.objectId,
                                         @"zoneID" : zoneID,
                                         @"timestamp" : aVybe[kVYBVybeTimestampKey]}
                                block:^(NSArray *objects, NSError *error) {
                                    if (!error) {
                                        if (objects.count > 0) {
                                            _zoneVybes = objects;
                                            _zoneCurrIdx = 0;
                                            [self prepareFirstVideoInBackgroundWithCompletion:^(BOOL success) {
                                                [self.delegate playerViewController:self didFinishSetup:success];
                                            }];
                                        }
                                        else {
                                            [self.delegate playerViewController:self didFinishSetup:NO];
                                            //Your vybe is the most recent so object count should always be at least 1
                                        }
    
                                    }
                                    else {
                                        [self.delegate playerViewController:self didFinishSetup:NO];
                                    }
                                }];
}


- (void)playFreshVybesFromZone:(NSString *)zoneID {
  [[ZoneStore sharedInstance] refreshFreshVybesInBackground:^(BOOL success) {
      if (success) {
          NSArray *freshContents = [NSArray arrayWithArray:[[ZoneStore sharedInstance] freshVybesFromZone:zoneID]];
          if (freshContents.count > 0) {
              _zoneVybes = freshContents;
              _zoneCurrIdx = 0;
              [self prepareFirstVideoInBackgroundWithCompletion:^(BOOL success) {
                  [self.delegate playerViewController:self didFinishSetup:success];
              }];
          }
          else {
              [self playActiveVybesFromZone:zoneID];
          }
      }
      else {
          [self.delegate playerViewController:self didFinishSetup:NO];
      }
  }];
}

- (void)playActiveVybesFromZone:(NSString *)zoneID {
    NSString *functionName = @"get_active_zone_vybes";
    
    [PFCloud callFunctionInBackground:functionName withParameters:@{@"zoneID": zoneID} block:^(NSArray *objects, NSError *error) {
        if (!error) {
            if (objects.count > 0) {
                _zoneVybes = objects;
                _zoneCurrIdx = 0;
                [self prepareFirstVideoInBackgroundWithCompletion:^(BOOL success) {
                    [self.delegate playerViewController:self didFinishSetup:success];
                }];
            }
            else {
                //TODO: No vybe within past week.
                [self.delegate playerViewController:self didFinishSetup:NO];
            }
        }
        else {
            [self.delegate playerViewController:self didFinishSetup:NO];
        }
    }];
}




#pragma mark - Behind the scene

- (void)playStream:(NSArray *)stream atIndex:(NSInteger)streamIdx {
    // GA stuff
    id tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker) {
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"play_video" label:@"play" value:nil] build]];
    }

    PFObject *currVybe = [stream objectAtIndex:streamIdx];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self syncUIElementsWithVybe:currVybe];
            self.goPrevButton.hidden = (streamIdx == 0);
        self.goNextButton.hidden = (streamIdx == stream.count - 1);
    });
    
    // Play after syncing UI elements
    NSURL *cacheURL = (NSURL *)[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
    cacheURL = [cacheURL URLByAppendingPathComponent:[currVybe objectId]];
    cacheURL = [cacheURL URLByAppendingPathExtension:@"mov"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[cacheURL path]]) {
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:cacheURL options:nil];
        
        [self playAsset:asset];

        [[ZoneStore sharedInstance] removeWatchedFromFreshFeed:currVybe];
    } else {
        PFFile *vid = [currVybe objectForKey:kVYBVybeVideoKey];
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [vid getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            if (!error) {
                [data writeToURL:cacheURL atomically:YES];
                AVURLAsset *asset = [AVURLAsset URLAssetWithURL:cacheURL options:nil];
                
                [self playAsset:asset];
                [[ZoneStore sharedInstance] removeWatchedFromFreshFeed:currVybe];
            } else {
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Network Temporarily Unavailable" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [av show];
            }
        }];
    }
}


#pragma mark - DeviceOrientation

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - ()

- (BOOL)prefersStatusBarHidden {
    return YES;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)syncUIElementsWithVybe:(PFObject *)aVybe {
    // Display location and time
    NSString *zoneName = aVybe[kVYBVybeZoneNameKey];
    if (!zoneName) {
        zoneName = @"Earth";
    }
    [self.locationLabel setText:zoneName];

    NSString *timeString = [[NSString alloc] init];
    timeString = [VYBUtility reverseTime:aVybe[kVYBVybeTimestampKey]];
    [self.timeLabel setText:timeString];
    
    PFObject *user = aVybe[kVYBVybeUserKey];
    NSString *username = user[kVYBUserUsernameKey];

    if (username) {
        [self.userButton setTitle:username forState:UIControlStateNormal];
    }
}


/**
 * User Interactions
 **/

#pragma mark - User Interactions


- (IBAction)dismissButtonPressed {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}



- (void)playAsset:(AVAsset *)asset {
    [self.currPlayerView setOrientation:[asset videoOrientation]];
    
    self.currItem = [AVPlayerItem playerItemWithAsset:asset];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
    [self.currPlayer replaceCurrentItemWithPlayerItem:self.currItem];
    [self.currPlayer play];
}



- (IBAction)goNextButtonPressed:(id)sender {
    [self playNextItem];
}


- (void)playNextItem {
    // Remove notification for current item
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
    
    if (_zoneVybes) {
        [self playNextZoneVideo];
    }
}


- (void)playNextZoneVideo {
    NSAssert(_zoneVybes, @"Can't play next video in zone because zone is nil");
    
    // Reached the end of zone. Zone OUT
    if (_zoneCurrIdx == _zoneVybes.count - 1) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        //[self.currPlayer pause];

        _zoneCurrIdx = _zoneCurrIdx + 1;
        [self playStream:_zoneVybes atIndex:_zoneCurrIdx];
    }
}


- (IBAction)goPrevButtonPressed:(id)sender {
    [self playPrevItem];
}

- (void)playPrevItem {
    // Remove notification for current item
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
    
    if (_zoneVybes) {
        [self playPrevZoneVideo];
    }
}

- (void)playPrevZoneVideo {
    NSAssert(_zoneVybes, @"Can't play prev video in zone because zone is nil");

    // Reached the beginning of the zone
    if (_zoneCurrIdx == 0) {
        return;
    }
    else {
        _zoneCurrIdx = _zoneCurrIdx - 1;
        [self playStream:_zoneVybes atIndex:_zoneCurrIdx];
    }
}


- (void)playerItemDidReachEnd {
    [self playNextItem];
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
//    if (!menuMode) {
//        overlayTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(overlayTimerExpired:) userInfo:nil repeats:NO];
//    } else {
//        [overlayTimer invalidate];
//    }
    
    menuMode = !menuMode;
    [self showOverlayMenu:menuMode];
}

- (void)overlayTimerExpired:(NSTimer *)timer {
    [self showOverlayMenu:NO];
}

- (void)showOverlayMenu:(BOOL)show {
    menuMode = show;
    
    [self menuModeChanged];
}

- (void)menuModeChanged {
    self.locationLabel.hidden = !menuMode;
    self.userButton.hidden = !menuMode;
    self.dismissButton.hidden = !menuMode;
    self.goPrevButton.selected = !menuMode;
    self.goNextButton.selected = !menuMode;
}


#pragma mark - VYBAppDelegateNotification


- (void)remoteNotificationReceived:(id)sender {

}


#pragma mark - Map



@end
