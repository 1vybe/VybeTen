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
@property (nonatomic, weak) IBOutlet UIButton *counterButton;
@property (nonatomic, weak) IBOutlet UIButton *portalButton;
@property (nonatomic, weak) IBOutlet UIButton *locationTimeButton;
@property (nonatomic, weak) IBOutlet UIButton *dismissButton;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *portalButtonHorizontalSpacing;

- (IBAction)goNextButtonPressed:(id)sender;
- (IBAction)goPrevButtonPressed:(id)sender;

- (IBAction)counterButtonPressed;
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
    
    menuMode = NO;

    [self syncUIElementsWithMenuMode];
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

- (void)playZoneVybesAfterVybe:(PFObject *)aVybe {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [PFCloud callFunctionInBackground:@"get_vybes_in_zone"
                       withParameters:@{ @"vybeID" : aVybe.objectId,
                                         @"zoneID" : aVybe[kVYBVybeZoneIDKey],
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
    // Pick fresh vybes from this zone and store them
    NSArray *freshContents = [[VYBCache sharedCache] freshVybes];
    NSMutableArray *zoneVybes = [[NSMutableArray alloc] init];

    // We only care about fresh vybes from this zone
    if (freshContents) {
        for (PFObject *aVybe in freshContents) {
            if (aVybe[kVYBVybeZoneIDKey] && [aVybe[kVYBVybeZoneIDKey] isEqualToString:zoneID] ) {
                [zoneVybes addObject:aVybe];
            }
        }
    }
    
    [self.portalButton setSelected:YES];

    if (zoneVybes.count > 0) {
        _zoneVybes = zoneVybes;
        _zoneCurrIdx = 0;
        [self playStream:_zoneVybes atIndex:_zoneCurrIdx];
    }
    // User watched all the active vybes. It will show you vybes from past 24 hours now.
    else {
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
    [locationTimeButton setTitle:@"" forState:UIControlStateNormal];
    NSString *locationTimeString = [[NSString alloc] init];
    NSString *zoneName = aVybe[kVYBVybeZoneNameKey];
    if (!zoneName) {
        zoneName = aVybe[kVYBVybeLocationStringKey];
        NSArray *arr = [zoneName componentsSeparatedByString:@","];
        if (arr.count == 3) {
            zoneName = [arr[1] stringByAppendingString:@", "];
        } else {
            zoneName = @"Earth, ";
        }
    }
    
    locationTimeString = [zoneName stringByAppendingString:[VYBUtility reverseTime:[aVybe objectForKey:kVYBVybeTimestampKey]]];
    [locationTimeButton setTitle:locationTimeString forState:UIControlStateNormal];
    
    
    if (_zoneVybes) {
        [counterButton setTitle: [NSString stringWithFormat:@"%ld", (long)_zoneVybes.count - _zoneCurrIdx - 1] forState:UIControlStateNormal];
    }
    else {
        [counterButton setTitle: [NSString stringWithFormat:@"%ld", (long)self.initialStream.count - _initialStreamCurrIdx - 1] forState:UIControlStateNormal];
    }
    
    if ( ! _zoneVybes ) {
        NSNumber *nearbyCount = [[VYBCache sharedCache] nearbyCountForVybe:aVybe];
        if (nearbyCount) {
            BOOL hasNearby = [nearbyCount boolValue];
            if (hasNearby) {
                [portalButton setHidden:NO];
            }
            else {
                [portalButton setHidden:YES];
            }
            if (completionBlock) {
                completionBlock();
            }
        }
        else {
            if ( aVybe[kVYBVybeZoneIDKey] ) {
                NSString *functionName = @"get_count_for_zone";
                //NOTE: portal button disappears while loading and should do something when reappears
                [PFCloud callFunctionInBackground:functionName withParameters:@{ @"vybeID" : aVybe.objectId, @"zoneID" : aVybe[kVYBVybeZoneIDKey], @"timestamp" : aVybe[kVYBVybeTimestampKey]} block:^(NSNumber *count, NSError *error) {
                    if (!error) {
                        [[VYBCache sharedCache] setNearbyCount:count forVybe:aVybe];
                        BOOL hasNearby = [count boolValue];
                        [portalButton setHidden:YES];
                        if (hasNearby) {
                            [portalButton setHidden:NO];
                        }
                        else {
                        }
                    }
                    else {
                        [portalButton setHidden:YES];
                    }
                    if (completionBlock) {
                        completionBlock();
                    }
                }];
            }
            else {
                [[VYBCache sharedCache] setNearbyCount:[NSNumber numberWithInt:0] forVybe:aVybe];
                [portalButton setHidden:YES];
                if (completionBlock) {
                    completionBlock();
                }
            }
        }
    }
    else {
        if (completionBlock) {
            completionBlock();
        }
    }
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
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [self.counterButton setTitle:[NSString stringWithFormat:@"%ld", _zoneVybes.count] forState:UIControlStateNormal];
                                        });
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

#pragma mark - Map

- (IBAction)mapButtonPressed {
    [self.currPlayer pause];
    // while on zone stream display all videos in that zone
    if (_zoneVybes) {
        if (_zoneVybes.count > 0) {
            VYBMapViewController *mapVC = [[VYBMapViewController alloc] initWithNibName:@"VYBMapViewController" bundle:nil];
            [self presentViewController:mapVC animated:YES completion:^{
                [mapVC displayVybes:_zoneVybes];
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
