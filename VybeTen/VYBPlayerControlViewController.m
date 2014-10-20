//
//  VYBPlayerControlViewController.m
//  VybeTen
//
//  Created by jinsuk on 10/6/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBPlayerControlViewController.h"
#import "VYBPlayerViewController.h"
#import "VYBAppDelegate.h"
#import <MotionOrientation@PTEz/MotionOrientation.h>
#import "VYBCaptureViewController.h"
#import "VYBLogInViewController.h"
#import "AVAsset+VideoOrientation.h"
#import "VYBPlayerView.h"
#import "VYBUtility.h"
#import "VYBCache.h"
#import "VYBLabel.h"
#import "VYBConstants.h"
#import "VYBUserStore.h"
#import "VYBDynamicSizeView.h"
#import <GAI.h>
#import <GAITracker.h>
#import <GAIFields.h>
#import <GAIDictionaryBuilder.h>

@interface VYBPlayerControlViewController ()
@property (nonatomic, weak) IBOutlet UIButton *counterButton;
@property (nonatomic, weak) IBOutlet UIButton *portalButton;
@property (nonatomic, weak) IBOutlet UIButton *locationTimeButton;
@property (nonatomic, weak) IBOutlet UIButton *captureButton;
@property (nonatomic, weak) IBOutlet UIButton *pauseButton;


- (IBAction)goNextButtonPressed:(id)sender;
- (IBAction)goPrevButtonPressed:(id)sender;
- (IBAction)pauseButtonPressed:(id)sender;

- (IBAction)counterButtonPressed;
- (IBAction)captureButtonPressed;


@property (nonatomic, weak) VYBPlayerViewController *playerVC;

@end


@implementation VYBPlayerControlViewController {
    NSInteger downloadingVybeIndex;
    BOOL menuMode;
    NSTimer *overlayTimer;
    
    NSInteger _pageIndex;
    NSArray *_zoneVybes;
    NSInteger _zoneVybeCurrIdx;
}
@synthesize captureButton;
@synthesize currVybeIndex;
@synthesize counterButton;
@synthesize portalButton;
@synthesize locationTimeButton;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBAppDelegateApplicationDidReceiveRemoteNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBAppDelegateApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBFreshVybeFeedFetchedFromRemoteNotification object:nil];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(freshVybesFetched:) name:VYBFreshVybeFeedFetchedFromRemoteNotification object:nil];
    
    // Device orientation detection
    [MotionOrientation initialize];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceRotated:)
                                                 name:MotionOrientationChangedNotification
                                               object:nil];
    
    self.playerVC = [(VYBAppDelegate *)[[UIApplication sharedApplication] delegate] playerVC];
    self.playerVC.playerController = self;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnce)];
    tapGesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapGesture];
    
    UILongPressGestureRecognizer *tapAndHoldGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(portalButtonTapAndHoldDetected:)];
    tapAndHoldGesture.minimumPressDuration = 0.5;
    [portalButton addGestureRecognizer:tapAndHoldGesture];
    
    menuMode = NO;
    [self syncUIElementsWithMenuMode];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerVC.currItem];
        [self.playerVC.currPlayer pause];
    });
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    self.vybePlaylist = [[VYBCache sharedCache] freshVybes];
    
    if (self.vybePlaylist && ([self.vybePlaylist count] > 0))
        [self beginPlayingFrom:0];
}


#pragma mark - Behind the scene

- (void)beginPlayingFrom:(NSInteger)from {
    currVybeIndex = from;
    
    NSString *counterString = [NSString stringWithFormat:@"%ld", (long)self.vybePlaylist.count - currVybeIndex - 1];
    [counterButton setTitle:counterString forState:UIControlStateNormal];
    
    downloadingVybeIndex = currVybeIndex + 1;
    
    PFObject *currVybe = [self.vybePlaylist objectAtIndex:currVybeIndex];
    [self syncUI:currVybe withCompletion:^{
        
        // Play after syncing UI elements
        NSURL *cacheURL = (NSURL *)[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
        cacheURL = [cacheURL URLByAppendingPathComponent:[currVybe objectId]];
        cacheURL = [cacheURL URLByAppendingPathExtension:@"mov"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[cacheURL path]]) {
            AVURLAsset *asset = [AVURLAsset URLAssetWithURL:cacheURL options:nil];
            
            [self.playerVC playAsset:asset];
            
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
                    
                    [self.playerVC playAsset:asset];
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
                        
                        [self.playerVC playAsset:asset];
                        
                        [[VYBCache sharedCache] removeFreshVybe:aVybe];
                    }];
                }
            }
        }];
    }
}


- (void)beginPlayingZoneVybes {
    _zoneVybeCurrIdx = 0;
    [self playZoneVybeAt:0];
    
}
- (void)playZoneVybeAt:(NSInteger)idx {
    PFObject *currVybe = [_zoneVybes objectAtIndex:idx];
    
    // Play after syncing UI elements
    NSURL *cacheURL = (NSURL *)[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
    cacheURL = [cacheURL URLByAppendingPathComponent:[currVybe objectId]];
    cacheURL = [cacheURL URLByAppendingPathExtension:@"mov"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[cacheURL path]]) {
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:cacheURL options:nil];
        [self.playerVC playAsset:asset];
    }
    else {
        PFFile *vid = [currVybe objectForKey:kVYBVybeVideoKey];
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [vid getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            if (!error) {
                [data writeToURL:cacheURL atomically:YES];
                AVURLAsset *asset = [AVURLAsset URLAssetWithURL:cacheURL options:nil];
                [self.playerVC playAsset:asset];
            } else {
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Network Temporarily Unavailable" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [av show];
            }
        }];
    }
}


- (void)playNextItem {
    if (_zoneVybes) {
        [self playNextZoneVideo];
        return;
    }
    if (currVybeIndex == self.vybePlaylist.count - 1) {
        [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
        return;
    } else {
        [self.playerVC.currPlayer pause];
        currVybeIndex++;
        [self beginPlayingFrom:currVybeIndex];
    }
}

- (void)playNextZoneVideo {
    if (_zoneVybeCurrIdx == _zoneVybes.count - 1) {
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.playerVC.view.alpha = 0.0;
            self.playerVC.view.transform = CGAffineTransformMakeScale(0.1f, 0.1f);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                self.playerVC.view.alpha = 1.0;
                self.playerVC.view.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
            } completion:^(BOOL finished) {
                _zoneVybes = nil;
                [self beginPlayingFrom:currVybeIndex];
            }];
        }];

        return;
    } else {
        [self.playerVC.currPlayer pause];
        _zoneVybeCurrIdx++;
        [self playZoneVybeAt:_zoneVybeCurrIdx];
    }
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
        locationStr = @"Nebulas, ";
    }
    locationTimeString = [locationStr stringByAppendingString:[VYBUtility reverseTime:[aVybe objectForKey:kVYBVybeTimestampKey]]];
    [locationTimeButton setTitle:locationTimeString forState:UIControlStateNormal];
    
    
    // Display how many vybes have been around current vybe
    [portalButton setTitle:@"" forState:UIControlStateNormal];
    if ( ! [aVybe objectForKey:kVYBVybeGeotag] ) {
        if (completionBlock)
            completionBlock();
        return;
    }
    
    PFQuery *query = [PFQuery queryWithClassName:kVYBVybeClassKey];
    [query whereKey:kVYBVybeGeotag nearGeoPoint:[aVybe objectForKey:kVYBVybeGeotag] withinKilometers:0.02];
    [query setLimit:50];
    query.cachePolicy = kPFCachePolicyCacheElseNetwork;
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        portalButton.hidden = YES;
        if (!error) {
            if (number > 0) {
                [portalButton setTitle:[NSString stringWithFormat:@"%d", number] forState:UIControlStateNormal];
                portalButton.hidden = NO;
            }
            if (completionBlock)
                completionBlock();
        }
    }];
    
    
//    } else if (aVybe[kVYBVybeCountryCodeKey]) {
//        countryCode = aVybe[kVYBVybeCountryCodeKey];
//    }
    
    /*
    [self.likeButton setSelected:NO];

    // Updating LIKE button status and count of the vybe
    if ( [[VYBCache sharedCache] attributesForVybe:aVybe] ) {
        [self.likeButton setSelected:[[VYBCache sharedCache] vybeLikedByMe:aVybe]];
        
    } else {
        PFQuery *query = [VYBUtility queryForActivitiesOnVybe:aVybe cachePolicy:kPFCachePolicyNetworkOnly];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                NSMutableArray *likers = [NSMutableArray array];
                NSMutableArray *commenters = [NSMutableArray array];
                
                BOOL isLikedByCurrentUser = NO;
                
                for (PFObject *activity in objects) {
                    if ([[activity objectForKey:kVYBActivityTypeKey] isEqualToString:kVYBActivityTypeLike] && [activity objectForKey:kVYBActivityFromUserKey]) {
                        [likers addObject:[activity objectForKey:kVYBActivityFromUserKey]];
                    } else if ([[activity objectForKey:kVYBActivityTypeKey] isEqualToString:kVYBActivityTypeComment] && [activity objectForKey:kVYBActivityFromUserKey]) {
                        [commenters addObject:[activity objectForKey:kVYBActivityFromUserKey]];
                    }
                    
                    if ([[[activity objectForKey:kVYBActivityFromUserKey] objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
                        if ([[activity objectForKey:kVYBActivityTypeKey] isEqualToString:kVYBActivityTypeLike]) {
                            isLikedByCurrentUser = YES;
                        }
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.likeButton setSelected:isLikedByCurrentUser];
                });
                
                [[VYBCache sharedCache] setAttributesForVybe:aVybe likers:likers commenters:commenters likedByCurrentUser:isLikedByCurrentUser];
            }
        }];
    }
    */
}


/**
 * User Interactions
 **/

#pragma mark - User Interactions

- (void)portalButtonTapAndHoldDetected:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self.playerVC.currPlayer pause];

        [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.playerVC.view.transform = CGAffineTransformMakeScale(3.0f, 3.0f);
        } completion:^(BOOL success) {
            [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                self.playerVC.view.alpha = 0.0f;
            } completion:^(BOOL success) {
                self.playerVC.view.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
            }];
        }];
        
        PFObject *currVybe = self.vybePlaylist[currVybeIndex];
        [PFCloud callFunctionInBackground:@"get_nearby_vybes"
                           withParameters:@{ @"vybeID" : currVybe.objectId}
                                    block:^(NSArray *objects, NSError *error) {
                                        if (!error) {
                                            _zoneVybes = objects;
                                            _zoneVybeCurrIdx = 0;
                                            [self beginPlayingZoneVybes];
                                        }
                                        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                                            self.playerVC.view.alpha = 1.0;
                                        } completion:nil];
                                    }];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        if ( ! _zoneVybes)
            return;
        
        [self.playerVC.currPlayer pause];
        
        [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.playerVC.view.transform = CGAffineTransformMakeScale(0.2f, 0.2f);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                self.playerVC.view.alpha = 0.0;
            } completion:^(BOOL finished) {
                self.playerVC.view.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                _zoneVybes = nil;
                [self beginPlayingFrom:currVybeIndex];
                [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                    self.playerVC.view.alpha = 1.0;
                } completion:nil];
            }];
        }];
    }
}

- (IBAction)counterButtonPressed {
    
}

- (IBAction)captureButtonPressed {
    
}

- (IBAction)dismissButtonPressed:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)likeButtonPressed:(id)sender {
    PFObject *aVybe = [self.vybePlaylist objectAtIndex:self.currVybeIndex];
    BOOL isLikedByMe = [[VYBCache sharedCache] vybeLikedByMe:aVybe];
    if (isLikedByMe) {
        [VYBUtility unlikeVybeInBackground:aVybe block:nil];
//        [self.likeButton setSelected:NO];
    } else {
        [VYBUtility likeVybeInBackground:aVybe block:nil];
//        [self.likeButton setSelected:YES];
    }
}

- (IBAction)goNextButtonPressed:(id)sender {
    //[MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    if (!self.vybePlaylist) {
        return;
    }
    
    if ( _zoneVybes)
        return;
    
    if (currVybeIndex == self.vybePlaylist.count - 1) {
        // Reached the end show the ENDING screen
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerVC.currItem];
    [self.playerVC.currPlayer pause];
    currVybeIndex++;
    [self beginPlayingFrom:currVybeIndex];
    
}

- (IBAction)goPrevButtonPressed:(id)sender {
    //[MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    if (!self.vybePlaylist) {
        return;
    }
    
    if ( _zoneVybes)
        return;
    
    if (currVybeIndex == 0) {
        // Reached the beginning show the BEGINNING screen
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerVC.currItem];
    [self.playerVC.currPlayer pause];
    currVybeIndex--;
    [self beginPlayingFrom:currVybeIndex];
}

- (IBAction)pauseButtonPressed:(id)sender {
    if (self.playerVC.currPlayer.rate == 0.0) {
        [self.playerVC.currPlayer play];
    }
    else {
        [self.playerVC.currPlayer pause];
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
    captureButton.hidden = !menuMode;
    self.pauseButton.hidden = !menuMode;
}


#pragma mark - VYBAppDelegateNotification

- (void)freshVybesFetched:(NSNotification *)notification {
    /*
    self.vybePlaylist = [[VYBCache sharedCache] freshVybes];
    if (self.vybePlaylist && (self.vybePlaylist.count > 0))
        [self beginPlayingFrom:0];
    */
}


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

- (void)deviceRotated:(NSNotification *)notification {
    UIDeviceOrientation currentOrientation = [MotionOrientation sharedInstance].deviceOrientation;
    
    double rotation = 0;
    CGRect newBounds;
    switch (currentOrientation) {
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationUnknown:
            return;
        case UIDeviceOrientationPortrait:
            rotation = 0;
            newBounds = [[UIScreen mainScreen] bounds];
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            rotation = -M_PI;
            newBounds = [[UIScreen mainScreen] bounds];
            break;
        case UIDeviceOrientationLandscapeLeft:
            rotation = M_PI_2;
            newBounds = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
            break;
        case UIDeviceOrientationLandscapeRight:
            rotation = -M_PI_2;
            newBounds = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
            break;
    }
    
    CGAffineTransform transform = CGAffineTransformMakeRotation(rotation);
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.view setTransform:transform];
        [self.view setBounds:newBounds];
    } completion:nil];
    
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}



@end
