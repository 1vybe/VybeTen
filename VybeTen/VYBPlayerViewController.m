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
#import <GAI.h>
#import <GAITracker.h>
#import <GAIFields.h>
#import <GAIDictionaryBuilder.h>

@interface VYBPlayerViewController ()
@property (nonatomic, weak) IBOutlet UIButton *portalButton;
@property (nonatomic, weak) IBOutlet UILabel *locationLabel;
@property (nonatomic, weak) IBOutlet UIButton *userButton;
@property (nonatomic, weak) IBOutlet UILabel *timeLabel;
@property (nonatomic, weak) IBOutlet UIButton *mapButton;
@property (nonatomic, weak) IBOutlet UIButton *dismissButton;
@property (nonatomic, weak) IBOutlet UIButton *goPrevButton;
@property (nonatomic, weak) IBOutlet UIButton *goNextButton;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *portalButtonHorizontalSpacing;

- (IBAction)goNextButtonPressed:(id)sender;
- (IBAction)goPrevButtonPressed:(id)sender;

- (IBAction)dismissButtonPressed;
- (IBAction)mapButtonPressed;

@property (nonatomic) NSArray *initialStream;

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
    NSInteger _initialStreamCurrIdx;
    NSArray *_zoneVybes;
    NSInteger _zoneCurrIdx;
    
    AVCaptureVideoOrientation lastOrientation;
    
    UIView *backgroundView;
    
    BOOL _isPlaying;
}
@synthesize dismissButton;
@synthesize portalButton;

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
    
    UITapGestureRecognizer *tapPortalButton = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(portalButtonPressed:)];
    tapPortalButton.numberOfTapsRequired = 1;
    [portalButton addGestureRecognizer:tapPortalButton];
    
    [self showOverlayMenu:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
    [self.currPlayer pause];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    if (self.currPlayer && self.currItem) {
        [self.currPlayer play];
    }
}

- (void)playZoneVybesFromVybe:(PFObject *)aVybe {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
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
                                    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                                    if (!error) {
                                        if (objects.count > 0) {
                                            _zoneVybes = objects;
                                            _zoneCurrIdx = 0;
                                            [self playStream:_zoneVybes atIndex:_zoneCurrIdx];
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                [self.portalButton setSelected:YES];
                                            });
                                        }
                                        else {
                                            //Your vybe is the most recent so object count should always be at least 1
                                        }
                                    }
                                    else {
                                        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                                    }
                                }];
}


- (void)playVybes:(NSArray *)vybes {
    [self playVybes:vybes from:0];
}

- (void)playVybes:(NSArray *)vybes from:(NSInteger)idx {
    self.initialStream = vybes;
    
    _initialStreamCurrIdx = idx;
    // We are beginning with initial stream
    [self playStream:self.initialStream atIndex:_initialStreamCurrIdx];
}

- (void)playActiveVybesFromZone:(NSString *)zoneID {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    NSString *functionName = @"get_active_zone_vybes";
    
    [PFCloud callFunctionInBackground:functionName withParameters:@{@"zoneID": zoneID} block:^(NSArray *objects, NSError *error) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        if (!error) {
            if (objects.count > 0) {
                _zoneVybes = objects;
                _zoneCurrIdx = 0;
                [self playStream:_zoneVybes atIndex:_zoneCurrIdx];
            }
            else {
                //TODO: No vybe within past 24 hours.
                [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
            }
        }
        else {
            [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
        }
    }];
}




#pragma mark - Behind the scene

- (void)playStream:(NSArray *)stream atIndex:(NSInteger)streamIdx {
    
    PFObject *currVybe = [stream objectAtIndex:streamIdx];
    [self syncUI:currVybe withCompletion:^{
        
        // Play after syncing UI elements
        NSURL *cacheURL = (NSURL *)[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
        cacheURL = [cacheURL URLByAppendingPathComponent:[currVybe objectId]];
        cacheURL = [cacheURL URLByAppendingPathExtension:@"mov"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[cacheURL path]]) {
            AVURLAsset *asset = [AVURLAsset URLAssetWithURL:cacheURL options:nil];
            
            [self playAsset:asset];
            // this playerVC is ONLY playing zone vybes
            if (!self.initialStream) {
                [[VYBCache sharedCache] removeFreshVybe:currVybe];
            }
        } else {
            PFFile *vid = [currVybe objectForKey:kVYBVybeVideoKey];
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [vid getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                if (!error) {
                    [data writeToURL:cacheURL atomically:YES];
                    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:cacheURL options:nil];
                    
                    [self playAsset:asset];
                    // this playerVC is ONLY playing zone vybes
                    if (!self.initialStream) {
                        [[VYBCache sharedCache] removeFreshVybe:currVybe];
                    }
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
    
    if (completionBlock)
        completionBlock();
}


/**
 * User Interactions
 **/

#pragma mark - User Interactions

- (void)portalButtonPressed:(id)sender {
    // Zone in
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
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    PFObject *currVybe = self.initialStream[_initialStreamCurrIdx];
    [PFCloud callFunctionInBackground:@"get_vybes_in_zone"
                       withParameters:@{ @"vybeID" : currVybe.objectId,
                                         @"zoneID" : currVybe[kVYBVybeZoneIDKey],
                                         @"timestamp" : currVybe[kVYBVybeTimestampKey]}
                                block:^(NSArray *objects, NSError *error) {
                                    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                                    if (!error) {
                                        _zoneVybes = objects;
                                        // First zone vybe to play is -1 relative to the current video playing on stream
                                        _zoneCurrIdx = -1;
                                        
                                        // Updadate counter because you just zoned in
                                        //TODO: shine a number of something to notify
                                    }
                                    [self.currPlayer play];
                                }];
    
#warning this does not create any animation effect
    // Animation to change bg image
    [UIView animateWithDuration:0.7 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.portalButton setSelected:YES];
    } completion:^(BOOL success) {
        [self.portalButton setEnabled:YES];
    }];
    
}

- (void)portalButtonZoneOut:(UIButton *)button {
    if (self.initialStream) {
        //Remove vybes from the stream that you watched while you were in the zone
        NSMutableArray *watchedZoneVybes = [[NSMutableArray alloc] init];
        for (int i = 0; i <= _zoneCurrIdx; i++) {
            [watchedZoneVybes addObject:_zoneVybes[i]];
        }
        
        NSMutableArray *prunedStream = [[NSMutableArray alloc] init];
        
        for (NSInteger i = _initialStreamCurrIdx; i < self.initialStream.count; i++) {
            if ( ! [watchedZoneVybes containsPFObject:self.initialStream[i]] ) {
                [prunedStream addObject:self.initialStream[i]];
            }
        }
        
        self.initialStream = prunedStream;
        _initialStreamCurrIdx = -1;
    }
    
    _zoneVybes = nil;


#warning this does not create any animation effect
    // Animation to change bg image
    [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.portalButton setSelected:NO];
    } completion:^(BOOL success) {
        [self.portalButton setEnabled:YES];
        
        [self playNextItem];
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
    [self playNextItem];
}


- (void)playNextItem {
    // Remove notification for current item
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
    
    if (_zoneVybes) {
        [self playNextZoneVideo];
    }
    else {
        [self playNextStreamVideo];
    }
}


- (void)playNextStreamVideo {
    // This playerViewController is ONLY playing zone vybes
    if (!_initialStream) {
        [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
        return;
    }
    
    // Reached the end of stream. Show the ENDING screen
    if (_initialStreamCurrIdx == (self.initialStream.count - 1)) {
        [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
        return;
    }
    else {
        //[self.currPlayer pause];
        _initialStreamCurrIdx = _initialStreamCurrIdx + 1;
        [self playStream:self.initialStream atIndex:_initialStreamCurrIdx];
    }

}

- (void)playNextZoneVideo {
    NSAssert(_zoneVybes, @"Can't play next video in zone because zone is nil");
    
    // Reached the end of zone. Zone OUT
    if (_zoneCurrIdx == _zoneVybes.count - 1) {
        [self portalButtonZoneOut:self.portalButton];
        return;
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
    else {
        [self playPrevStreamVideo];
    }
}


- (void)playPrevStreamVideo {
    NSAssert(self.initialStream, @"Can't play prev video on stream because stream is nil");
    
    // Reached the beginning of the stream.
    if (_initialStreamCurrIdx == 0) {
        return;
    }
    else {
        _initialStreamCurrIdx = _initialStreamCurrIdx - 1;
        [self playStream:self.initialStream atIndex:_initialStreamCurrIdx];
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
    if (!menuMode) {
        overlayTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(overlayTimerExpired:) userInfo:nil repeats:NO];
    } else {
        [overlayTimer invalidate];
    }
    
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

- (IBAction)mapButtonPressed {
    [self.currPlayer pause];
    // while on zone stream display all videos in that zone
    if (_zoneVybes) {
        if (_zoneVybes.count > 0) {
            VYBMapViewController *mapVC = [[VYBMapViewController alloc] initWithNibName:@"VYBMapViewController" bundle:nil];
            [self presentViewController:mapVC animated:YES completion:^{
            }];
        }
    }
    else {
        PFObject *currVybe = self.initialStream[_initialStreamCurrIdx];
        VYBMapViewController *mapVC = [[VYBMapViewController alloc] initWithNibName:@"VYBMapViewController" bundle:nil];
        [self presentViewController:mapVC animated:YES completion:^{
            //[mapVC displayNearbyAroundVybe:currVybe];
        }];
    }
}



@end
