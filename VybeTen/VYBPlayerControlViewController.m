//
//  VYBPlayerControlViewController.m
//  VybeTen
//
//  Created by jinsuk on 10/6/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBPlayerControlViewController.h"
#import <MotionOrientation@PTEz/MotionOrientation.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "AVAsset+VideoOrientation.h"
#import "VYBPlayerView.h"
#import "VYBUtility.h"
#import "VYBCache.h"
#import "VYBConstants.h"
#import "VYBActiveButton.h"
#import <GAI.h>
#import <GAITracker.h>
#import <GAIFields.h>
#import <GAIDictionaryBuilder.h>

@interface VYBPlayerControlViewController ()
@property (nonatomic, weak) IBOutlet UIButton *counterButton;
@property (nonatomic, weak) IBOutlet UIButton *portalButton;
@property (nonatomic, weak) IBOutlet UIButton *locationTimeButton;
@property (nonatomic, weak) IBOutlet UIButton *dismissButton;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *portalButtonHorizontalSpacing;

- (IBAction)goNextButtonPressed:(id)sender;
- (IBAction)goPrevButtonPressed:(id)sender;

- (IBAction)counterButtonPressed;
- (IBAction)dismissButtonPressed;

@property (nonatomic, weak) VYBPlayerView *currPlayerView;
@property (nonatomic) AVPlayer *currPlayer;
@property (nonatomic) AVPlayerItem *currItem;

- (void)playAsset:(AVAsset *)asset;

@end


@implementation VYBPlayerControlViewController {
    NSInteger downloadingVybeIndex;
    BOOL menuMode;
    NSTimer *overlayTimer;
    
    NSInteger _pageIndex;
    NSArray *_zoneVybes;
    NSInteger _zoneVybeCurrIdx;
    
    AVCaptureVideoOrientation lastOrientation;
    
    UIView *backgroundView;
}
@synthesize dismissButton;
@synthesize currVybeIndex;
@synthesize counterButton;
@synthesize portalButton;
@synthesize locationTimeButton;

@synthesize currPlayer = _currPlayer;
@synthesize currPlayerView = _currPlayerView;
@synthesize currItem = _currItem;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBAppDelegateApplicationDidReceiveRemoteNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBAppDelegateApplicationDidBecomeActiveNotification object:nil];
}

- (id)initWithPageIndex:(NSInteger)pageIndex {
    self = [super init];
    if (self) {
        if (pageIndex != VYBHubPageIndex)
            return nil;
        
        _pageIndex = pageIndex;
    }
    return self;
}

- (NSInteger)pageIndex {
    return _pageIndex;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    menuMode = NO;

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
    
    UILongPressGestureRecognizer *tapAndHoldGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(portalButtonTapAndHoldDetected:)];
    tapAndHoldGesture.minimumPressDuration = 0.3;
    [portalButton addGestureRecognizer:tapAndHoldGesture];
    
    /*
    // Portal button image set up
    [portalButton setNormalImage:[UIImage imageNamed:@"player_zone_in.png"]
                  highlightImage:[UIImage imageNamed:@"player_zone_in_highlight.png"]];
    [portalButton setActiveImage:[UIImage imageNamed:@"player_zone_out.png"]
                  highlightImage:[UIImage imageNamed:@"player_zone_out_highlight.png"]];
    [portalButton setActive:NO];
    */
    
    [self syncUIElementsWithMenuMode];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
    [self.currPlayer pause];
    
    self.vybePlaylist = nil;

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    if (self.vybePlaylist && ([self.vybePlaylist count] > 0)) {
        [self beginPlayingFrom:0];
    }
    else {
        NSString *functionName = @"get_active_vybes";
        [PFCloud callFunctionInBackground:functionName withParameters:@{} block:^(NSArray *objects, NSError *error) {
            if (!error) {
                self.vybePlaylist = objects;
                if (self.vybePlaylist.count > 0)
                    [self beginPlayingFrom:0];
            }
        }];
    }
}

#pragma mark - Custom Accessors

- (NSArray *)vybePlaylist {
    if (!_vybePlaylist) {
       _vybePlaylist = [[VYBCache sharedCache] freshVybes];
    }
    return _vybePlaylist;
}

#pragma mark - Behind the scene

- (void)beginPlayingFrom:(NSInteger)from {
    currVybeIndex = from;

    downloadingVybeIndex = currVybeIndex + 1;
    
    PFObject *currVybe = [self.vybePlaylist objectAtIndex:currVybeIndex];
    [self syncUI:currVybe withCompletion:^{
        
        // Play after syncing UI elements
        NSURL *cacheURL = (NSURL *)[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
        cacheURL = [cacheURL URLByAppendingPathComponent:[currVybe objectId]];
        cacheURL = [cacheURL URLByAppendingPathExtension:@"mov"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[cacheURL path]]) {
            AVURLAsset *asset = [AVURLAsset URLAssetWithURL:cacheURL options:nil];
            
            [self playAsset:asset];
            
            [[VYBCache sharedCache] removeFreshVybe:currVybe];
            [self prepareVybeAt:downloadingVybeIndex];
        } else {
            PFFile *vid = [currVybe objectForKey:kVYBVybeVideoKey];
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [vid getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                if (!error) {
                    [data writeToURL:cacheURL atomically:YES];
                    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:cacheURL options:nil];
                    
                    [self playAsset:asset];
                    [[VYBCache sharedCache] removeFreshVybe:currVybe];
                    [self prepareVybeAt:downloadingVybeIndex];
                } else {
                    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Network Temporarily Unavailable" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [av show];
                }
            }];
        }

    }];
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
                    //[MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                    
                    [self prepareVybeAt:downloadingVybeIndex + 1];
                    [self syncUI:aVybe withCompletion:^{
                        [data writeToURL:cacheURL atomically:YES];
                        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:cacheURL options:nil];
                        
                        [self playAsset:asset];
                        
                        [[VYBCache sharedCache] removeFreshVybe:aVybe];
                    }];
                }
            }
        }];
    }
}


- (void)beginPlayingZoneVybes {
    if (_zoneVybes && _zoneVybes.count > 0) {
        _zoneVybeCurrIdx = 0;
        [self playZoneVybeAt:0];
    } else {
        [self portalButtonZoneOut:self.portalButton];
    }
}

- (void)playZoneVybeAt:(NSInteger)idx {
    PFObject *currVybe = [_zoneVybes objectAtIndex:idx];

    [self syncUI:currVybe withCompletion:^{
        // Play after syncing UI elements
        NSURL *cacheURL = (NSURL *)[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
        cacheURL = [cacheURL URLByAppendingPathComponent:[currVybe objectId]];
        cacheURL = [cacheURL URLByAppendingPathExtension:@"mov"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[cacheURL path]]) {
            AVURLAsset *asset = [AVURLAsset URLAssetWithURL:cacheURL options:nil];
            [self playAsset:asset];
        }
        else {
            PFFile *vid = [currVybe objectForKey:kVYBVybeVideoKey];
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [vid getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                if (!error) {
                    [data writeToURL:cacheURL atomically:YES];
                    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:cacheURL options:nil];
                    [self playAsset:asset];
                } else {
                    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Network Temporarily Unavailable" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [av show];
                }
            }];
        }
    }];
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


- (void)syncUI:(PFObject *)aVybe withCompletion:(void (^)())completionBlock {
    // Display location and time
    [locationTimeButton setTitle:@"" forState:UIControlStateNormal];
    NSString *locationTimeString = [[NSString alloc] init];
    NSString *locationStr = aVybe[kVYBVybeLocationStringKey];
    NSArray *arr = [locationStr componentsSeparatedByString:@","];
    if (arr.count == 3) {
        locationStr = [arr[1] stringByAppendingString:@", "];
    } else {
        locationStr = @"Earth, ";
    }
    locationTimeString = [locationStr stringByAppendingString:[VYBUtility reverseTime:[aVybe objectForKey:kVYBVybeTimestampKey]]];
    [locationTimeButton setTitle:locationTimeString forState:UIControlStateNormal];
    
    
    if (_zoneVybes) {
        [counterButton setTitle: [NSString stringWithFormat:@"%ld", (long)_zoneVybes.count - _zoneVybeCurrIdx - 1] forState:UIControlStateNormal];
    }
    else {
        [counterButton setTitle: [NSString stringWithFormat:@"%ld", (long)self.vybePlaylist.count - currVybeIndex - 1] forState:UIControlStateNormal];
    }
    
    if ( ! _zoneVybes ) {
        NSNumber *nearbyCount = [[VYBCache sharedCache] nearbyCountForVybe:aVybe];
        if (nearbyCount) {
            BOOL hasNearby = [nearbyCount boolValue];
            if (hasNearby) {
                [portalButton setHidden:NO];
                if (completionBlock)
                    completionBlock();
            }
            else {
                [portalButton setHidden:YES];
            }
        }
        else {
            NSString *functionName = @"get_nearby_count";
            //NOTE: portal button disappears while loading and should do something when reappears
            [PFCloud callFunctionInBackground:functionName withParameters:@{ @"vybeID" : aVybe.objectId } block:^(NSNumber *count, NSError *error) {
                if (!error) {
                    [[VYBCache sharedCache] setNearbyCount:count forVybe:aVybe];
                    BOOL hasNearby = [count boolValue];
                    if (hasNearby) {
                        [portalButton setHidden:NO];
                        if (completionBlock)
                            completionBlock();
                    }
                    else {
                        [portalButton setHidden:YES];
                    }
                }
                else {
                    [portalButton setEnabled:NO];
                }
            }];
        }
    }
    else {
        if (completionBlock)
            completionBlock();
    }
}


/**
 * User Interactions
 **/

#pragma mark - User Interactions

- (void)portalButtonTapAndHoldDetected:(UILongPressGestureRecognizer *)recognizer {
    // Zone in
    if (recognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    if (!_zoneVybes) {
        [self.portalButton setEnabled:NO];
        [self portalButtonZoneIn:self.portalButton];
    }
    else {
        [self.portalButton setEnabled:NO];
        [self portalButtonZoneOut:self.portalButton];
    }
}

- (void)portalButtonZoneIn:(UIButton *)button {
    [self.currPlayer pause];

    PFObject *currVybe = self.vybePlaylist[currVybeIndex];
    [PFCloud callFunctionInBackground:@"get_nearby_vybes"
                       withParameters:@{ @"vybeID" : currVybe.objectId}
                                block:^(NSArray *objects, NSError *error) {
                                    if (!error) {
                                        _zoneVybes = objects;
                                        _zoneVybeCurrIdx = 0;
                                        [self beginPlayingZoneVybes];
                                    }
                                }];
    
    // Animation to change bg image
    [UIView animateWithDuration:0.7 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.portalButton setSelected:YES];
    } completion:^(BOOL success) {
        [self.portalButton setEnabled:YES];
    }];
    
}

- (void)portalButtonZoneOut:(UIButton *)button {
    [self.currPlayer pause];

    _zoneVybes = nil;

    // Animation to change bg image
    [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.portalButton setSelected:NO];
    } completion:^(BOOL success) {
        [self.portalButton setEnabled:YES];
        
        [self beginPlayingFrom:currVybeIndex];
    }];
    
}


- (IBAction)counterButtonPressed {
    
}

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
    if (_zoneVybes)
        [self playNextZoneVideo];
    else
        [self playNextStreamVideo];
}


- (void)playNextItem {
    if (_zoneVybes) {
        [self playNextZoneVideo];
    }
    else {
        [self playNextStreamVideo];
    }
}


- (void)playNextStreamVideo {
    if (!self.vybePlaylist) {
        return;
    }
    
    if (currVybeIndex >= (self.vybePlaylist.count - 1)) {
        // Reached the end show the ENDING screen
        [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
    [self.currPlayer pause];
    currVybeIndex++;
    [self beginPlayingFrom:currVybeIndex];
}

- (void)playNextZoneVideo {
    if (_zoneVybeCurrIdx == _zoneVybes.count - 1) {
        [self portalButtonZoneOut:self.portalButton];
    }
    else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
        [self.currPlayer pause];
        _zoneVybeCurrIdx++;
        [self playZoneVybeAt:_zoneVybeCurrIdx];
    }
}


- (IBAction)goPrevButtonPressed:(id)sender {
    if (_zoneVybes) {
        [self playPrevZoneVideo];
    }
    else {
        [self playPrevStreamVideo];
    }
}

- (void)playPrevZoneVideo {
    if (_zoneVybeCurrIdx == 0) {
        // Reached the beginning show the BEGINNING screen
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
    [self.currPlayer pause];
    _zoneVybeCurrIdx--;
    [self playZoneVybeAt:_zoneVybeCurrIdx];
}

- (void)playPrevStreamVideo {
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


- (void)playerItemDidReachEnd {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
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
    locationTimeButton.hidden = !menuMode;
    counterButton.hidden = !menuMode;
    dismissButton.hidden = !menuMode;
}


#pragma mark - VYBAppDelegateNotification


- (void)remoteNotificationReceived:(id)sender {

}

- (void)applicationDidBecomeActiveNotificationReceived:(id)sender {
    if ( [[PFUser currentUser] objectForKey:@"tribe"] ) {
        PFObject *myTribe = [[PFUser currentUser] objectForKey:@"tribe"];
        [myTribe fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error) {
                
            }
        }];
    }
}


@end
