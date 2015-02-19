//
//  VYBPlayerViewController.m
//  VybeTen
//
//  Created by jinsuk on 10/6/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBPlayerViewController.h"
#import <MotionOrientation@PTEz/MotionOrientation.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "AVAsset+VideoOrientation.h"
#import "VYBAppDelegate.h"
#import "VYBPlayerView.h"
#import "VYBUtility.h"
#import "VYBCache.h"
#import "VYBConstants.h"

#import "NSArray+PFObject.h"

#import "Vybe-Swift.h"

@interface VYBPlayerViewController () <VYBPlayerViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *loopImageView;
@property (nonatomic, weak) IBOutlet UIView *firstOverlay;

@property (nonatomic, weak) IBOutlet UIImageView *topBarBG;
@property (nonatomic, weak) IBOutlet UILabel *locationLabel;
@property (nonatomic, weak) IBOutlet UIButton *dismissButton;
@property (nonatomic, weak) IBOutlet UIButton *addButton;

@property (nonatomic, weak) IBOutlet UILabel *timeLabel;
@property (nonatomic, weak) IBOutlet UILabel *usernameLabel;
@property (nonatomic, weak) IBOutlet UIButton *optionsButton;

@property (nonatomic, weak) IBOutlet UIButton *goPrevButton;
@property (nonatomic, weak) IBOutlet UIButton *goNextButton;
@property (nonatomic, weak) IBOutlet UIButton *nextAerialButton;
@property (nonatomic, weak) IBOutlet UIButton *prevAerialButton;

@property (nonatomic, weak) IBOutlet UIView *optionsOverlay;
@property (nonatomic, weak) IBOutlet UIButton *flagOverlayButton;
@property (nonatomic, weak) IBOutlet UIButton *blockOverlayButton;

@property (nonatomic) NSArray *hashtagButtons;

- (IBAction)dismissButtonPressed;

- (IBAction)goNextButtonPressed:(id)sender;
- (IBAction)goPrevButtonPressed:(id)sender;

- (IBAction)optionsButtonPressed:(id)sender;
- (IBAction)flagOverlayButtonPressed;
- (IBAction)blockOverlayButtonPressed;

@property (nonatomic, weak) VYBPlayerView *currPlayerView;
@property (nonatomic) AVPlayer *currPlayer;
@property (nonatomic) AVPlayerItem *currItem;

@property (nonatomic) BOOL loopCurrItem;

@property (nonatomic, strong) NSDate *lastTimePlayingAsset;
@end

@interface DownloadQueue : NSObject
@end

@implementation DownloadQueue {
  NSArray *queue;
}

- (BOOL)isDownloading:(PFObject *)vybe {
  for (PFObject *aVybe in queue) {
    if ([aVybe.objectId isEqualToString:vybe.objectId]) {
      return YES;
    }
  }
  
  return NO;
}

- (void)insert:(PFObject *)newObj {
  if (queue) {
    queue = [queue arrayByAddingObject:newObj];
  } else {
    queue = [NSArray arrayWithObject:newObj];
  }
}

- (void)remove:(PFObject *)dObj {
  NSMutableArray *newQueue = [NSMutableArray array];
  if (newQueue) {
    for (PFObject *vybe in queue) {
      if ( ! [vybe.objectId isEqualToString:dObj.objectId]) {
        [newQueue addObject:vybe];
      }
    }
  }
  queue = newQueue;
}

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
  
  BOOL _isFreshStream;
  
  UILongPressGestureRecognizer *longPressRecognizer;
  
  DownloadQueue *downloadQueue;
}
@synthesize dismissButton;

@synthesize currPlayer = _currPlayer;
@synthesize currPlayerView = _currPlayerView;
@synthesize currItem = _currItem;

- (void)dealloc {  
  [[UIApplication sharedApplication].keyWindow removeGestureRecognizer:longPressRecognizer];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  _loopCurrItem = NO;
  self.loopImageView.hidden = YES;
  
  downloadQueue = [[DownloadQueue alloc] init];
  
  // Set up player view
  VYBPlayerView *playerView = [[VYBPlayerView alloc] init];
  [playerView setFrame:[[UIScreen mainScreen] bounds]];
  self.currPlayerView = playerView;
  
  self.currPlayer = [[AVPlayer alloc] init];
  [playerView setPlayer:self.currPlayer];
  
  [self.view insertSubview:playerView atIndex:0];
  
  // Add gestures on screen
  UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnce:)];
  [self.view addGestureRecognizer:tapGesture];
  
  longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressDetected:)];
  longPressRecognizer.minimumPressDuration = 0.3;
  longPressRecognizer.delegate = self;
  [self.view addGestureRecognizer:longPressRecognizer];
  
  UISwipeGestureRecognizer *swipeUpGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeUpDetected:)];
  swipeUpGesture.direction = UISwipeGestureRecognizerDirectionUp;
  [self.view addGestureRecognizer:swipeUpGesture];
  
  self.firstOverlay.hidden = YES;
  self.optionsOverlay.hidden = YES;
  self.goNextButton.hidden = YES;
  self.goPrevButton.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
//  [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
  [self.currPlayer pause];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
//  [self playCurrentItem];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  [self setNeedsStatusBarAppearanceUpdate];
  
//  if (self.currPlayer && self.currItem) {
//    [self.currPlayer play];
//  }
#ifdef DEBUG
#else
  id tracker = [[GAI sharedInstance] defaultTracker];
  if (tracker) {
    [tracker set:kGAIScreenName
           value:@"Player Screen"];
    
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
  }
#endif
}

- (void)prepareVideoInBackgroundFor:(PFObject *)vybe withCompletion:(void (^)(BOOL))completionBlock {
  if ( [downloadQueue isDownloading:vybe] ) {
    return;
  }
  
  NSURL *cacheURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
  cacheURL = [cacheURL URLByAppendingPathComponent:[vybe objectId]];
  cacheURL = [cacheURL URLByAppendingPathExtension:@"mp4"];
  
  [downloadQueue insert:vybe];
  
  PFFile *vid = [vybe objectForKey:kVYBVybeVideoKey];
  [vid getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
    if (!error) {
      [data writeToURL:cacheURL atomically:YES];
      
      [self playVybe:vybe];
      if (completionBlock) {
        completionBlock(YES);
      }
    }
    else {
      if (completionBlock) {
        completionBlock(NO);
      }
    }
    [downloadQueue remove:vybe];
  }];
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
                                    [self prepareVideoInBackgroundFor:_zoneVybes[0] withCompletion:^(BOOL success) {
                                      [self.delegate playerViewController:self didFinishSetup:success];
                                    }];
                                  }
                                  else {
                                    [self.delegate playerViewController:self didFinishSetup:NO];
                                  }
                                }
                                else {
                                  [self.delegate playerViewController:self didFinishSetup:NO];
                                }
                              }];
}

- (void)playStream:(NSArray *)vybes {
  _zoneVybes = vybes;
  _zoneCurrIdx = 0;
  
  [self prepareVideoInBackgroundFor:_zoneVybes[0] withCompletion:^(BOOL success) {
    [self.delegate playerViewController:self didFinishSetup:success];
  }];
}

- (void)playStream:(NSArray *)vybes from:(PFObject *)vybe {
  _zoneVybes = [[NSArray alloc] init];
  
  NSInteger index = [vybes indexOfObject:vybe];
  for (NSInteger i = index; i < vybes.count; i++) {
    _zoneVybes = [_zoneVybes arrayByAddingObject:vybes[i]];
  }
  
  _zoneCurrIdx = 0;
  [self prepareVideoInBackgroundFor:_zoneVybes[0] withCompletion:^(BOOL success) {
    [self.delegate playerViewController:self didFinishSetup:success];
  }];
}

- (void)playCurrentItem {
  if (_zoneVybes) {
    [self playStream:_zoneVybes atIndex:_zoneCurrIdx];
  }
}

- (void)playAllFresh {
  [[ZoneStore sharedInstance] refreshFreshVybesInBackground:^(BOOL success) {
    if (success) {
      NSArray *allContents = [NSArray arrayWithArray:[[ZoneStore sharedInstance] allFreshVybes]];
      _zoneVybes = allContents;
      _zoneCurrIdx = 0;
      _isFreshStream = YES;
      [self prepareVideoInBackgroundFor:_zoneVybes[_zoneCurrIdx] withCompletion:^(BOOL success) {
        [self.delegate playerViewController:self didFinishSetup:success];
      }];
    }
    else {
      [self.delegate playerViewController:self didFinishSetup:NO];
    }
  }];
}

- (void)playAllActiveVybes {
  NSDate *someTimeAgo = [NSDate dateWithTimeIntervalSinceNow:-60*60*24]; // 24 hour
  PFQuery *query = [PFQuery queryWithClassName:kVYBVybeClassKey];
  [query setLimit:1000];
  [query setCachePolicy:kPFCachePolicyCacheElseNetwork];
  [query includeKey:kVYBVybeUserKey];
  [query whereKey:kVYBVybeTimestampKey greaterThanOrEqualTo:someTimeAgo];
  [query orderByAscending:kVYBVybeTimestampKey];
  // NOTE: - Blocked users, flagged iterms are not filtered
  [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    if (!error && objects.count) {
      _zoneVybes = objects;
      _zoneCurrIdx = 0;
      [self prepareVideoInBackgroundFor:_zoneVybes[_zoneCurrIdx] withCompletion:^(BOOL success) {
        [self.delegate playerViewController:self didFinishSetup:success];
      }];
    } else {
      [self.delegate playerViewController:self didFinishSetup:NO];
    }
  }];
}

- (void)playOnce:(PFObject *)vybe {
  PFUser *user = vybe[kVYBVybeUserKey];
  [user fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
    if (!error) {
      _zoneVybes = [NSArray arrayWithObject:vybe];
      _zoneCurrIdx = 0;
      
      [self prepareVideoInBackgroundFor:_zoneVybes[0] withCompletion:^(BOOL success) {
        [self.delegate playerViewController:self didFinishSetup:success];
      }];
    } else {
      [self.delegate playerViewController:self didFinishSetup:NO];
    }
  }];
}


- (void)playFeaturedZone:(Zone *)zone {
  PFQuery *query = [PFQuery queryWithClassName:kVYBVybeClassKey];
  [query whereKey:kVYBVybeZoneIDKey equalTo:zone.zoneID];
  [query whereKey:kVYBVybeTimestampKey greaterThanOrEqualTo:zone.fromDate];
  [query includeKey:kVYBVybeUserKey];
  [query orderByAscending:kVYBVybeTimestampKey];
  
  [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    if (!error) {
      _zoneVybes = objects;
      _zoneCurrIdx = 0;
      [self prepareVideoInBackgroundFor:_zoneVybes[_zoneCurrIdx] withCompletion:^(BOOL success) {
        [self.delegate playerViewController:self didFinishSetup:success];
      }];
    } else {
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
        _isFreshStream = YES;
        [self prepareVideoInBackgroundFor:_zoneVybes[_zoneCurrIdx] withCompletion:^(BOOL success) {
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
    if (!error && objects.count) {
      _zoneVybes = objects;
      _zoneCurrIdx = 0;
      [self prepareVideoInBackgroundFor:_zoneVybes[_zoneCurrIdx] withCompletion:^(BOOL success) {
        [self.delegate playerViewController:self didFinishSetup:success];
      }];
    }
    else {
      [self.delegate playerViewController:self didFinishSetup:NO];
    }
  }];
}




#pragma mark - Behind the scene

- (void)playStream:(NSArray *)stream atIndex:(NSInteger)streamIdx {
#ifdef DEBUG
#else
  // GA stuff
  id tracker = [[GAI sharedInstance] defaultTracker];
  if (tracker) {
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"play_video" label:@"play" value:nil] build]];
  }
#endif
  
  PFObject *vybeBeingWatched = [stream objectAtIndex:streamIdx];
  PFUser *fromUser = [vybeBeingWatched objectForKey:kVYBVybeUserKey];
  // Filter out contents from blocked users
  NSArray *usersBlocked = [[VYBCache sharedCache] usersBlockedByMe];
  if ([usersBlocked containsPFObject:fromUser]) {
    [self playNextItem];
    return;
  }

  [self playVybe:vybeBeingWatched];
}

- (void)playVybe:(PFObject *)vybe {
  PFObject *currVybe = _zoneVybes[_zoneCurrIdx];
  if ( ! [currVybe.objectId isEqualToString:vybe.objectId]) {
    return;
  }
  
  // Play after syncing UI elements
  NSURL *cacheURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
  cacheURL = [cacheURL URLByAppendingPathComponent:[vybe objectId]];
  cacheURL = [cacheURL URLByAppendingPathExtension:@"mp4"];
  
  if ([[NSFileManager defaultManager] fileExistsAtPath:[cacheURL path]]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
      [self syncUIElementsFor:vybe];
    });
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:cacheURL options:nil];
    [self playAsset:asset];
    
    if (_zoneCurrIdx + 1 < _zoneVybes.count) {
      PFObject *nextItem = _zoneVybes[_zoneCurrIdx + 1];
      [self prepareVideoInBackgroundFor:nextItem withCompletion:^(BOOL success) {
        PFObject *currItem = _zoneVybes[_zoneCurrIdx];
        if ( [currItem.objectId isEqualToString:nextItem.objectId]) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [self.nextAerialButton setEnabled:YES];
          });
        }
      }];
    }
  } else {
    dispatch_async(dispatch_get_main_queue(), ^{
      [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      [self.nextAerialButton setEnabled:NO];
    });
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

- (void)syncUIElementsFor:(PFObject *)aVybe {
  // Display location and time
  NSString *zoneName = aVybe[kVYBVybeZoneNameKey];
  if (!zoneName) {
    zoneName = @"Earth";
  }
  [self.locationLabel setText:zoneName];
  
  NSString *timeString = [[NSString alloc] init];
  timeString = [VYBUtility timeStringForPlayer:aVybe[kVYBVybeTimestampKey]];
  [self.timeLabel setText:timeString];
  
  PFObject *user = aVybe[kVYBVybeUserKey];
  NSString *username = user[kVYBUserUsernameKey];
  if (username) {
    [self.usernameLabel setText:username];
  }
  if ( [user.objectId isEqualToString:[PFUser currentUser].objectId] ) {
    // close down optionOverlay before hiding it
    if (!self.optionsOverlay.hidden) {
      self.optionsButton.selected = NO;
      self.optionsOverlay.hidden = YES;
    }
    self.optionsButton.hidden = YES;
  } else {
    self.optionsButton.hidden = NO;
  }
  
  self.flagOverlayButton.selected = [[VYBCache sharedCache] vybeFlaggedByMe:aVybe];
  self.blockOverlayButton.selected = NO;
}

- (void)playAsset:(AVAsset *)asset {
  [self.currPlayerView setOrientation:[asset videoOrientation]];
  
  self.currItem = [AVPlayerItem playerItemWithAsset:asset];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
  [self.currPlayer replaceCurrentItemWithPlayerItem:self.currItem];
  
  [self.currPlayer play];
  self.lastTimePlayingAsset = [NSDate date];
}

- (IBAction)goNextButtonPressed:(id)sender {
  [self playNextItem];
  
  [UIView animateWithDuration:0.7 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
    self.goNextButton.alpha = 0.0;
    self.goPrevButton.alpha = 0.0;
  } completion:^(BOOL finished) {
    if (finished) {
      self.goNextButton.alpha = 1.0;
      self.goPrevButton.alpha = 1.0;
      
      self.goNextButton.hidden = YES;
      self.goPrevButton.hidden = YES;
    }
  }];

}

- (void)playNextItem {
  // Remove notification for current item
  [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
  
  if (_zoneVybes) {
    PFObject *currItem = _zoneVybes[_zoneCurrIdx];
    [ActionUtility removeFromMyFeed:currItem];
    
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
    [self playCurrentItem];
  }
}


- (IBAction)goPrevButtonPressed:(id)sender {
//  if (self.lastTimePlayingAsset && [self.lastTimePlayingAsset timeIntervalSinceNow] > -2.0) {
//    [self playPrevItem];
//  } else {
//    [self playCurrentItem];
//  }
//  
//  if (!self.goPrevButton.hidden) {
//    [UIView animateWithDuration:0.7 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
//      self.goNextButton.alpha = 0.0;
//      self.goPrevButton.alpha = 0.0;
//    } completion:^(BOOL finished) {
//      if (finished) {
//        self.goNextButton.alpha = 1.0;
//        self.goPrevButton.alpha = 1.0;
//    
//        self.goNextButton.hidden = YES;
//        self.goPrevButton.hidden = YES;
//      }
//    }];
//  }
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
    [self playCurrentItem];
  }
}

- (void)playerItemDidReachEnd {
  if (_loopCurrItem) {
    [self playCurrentItem];
  } else {
    [self playNextItem];
  }
}

- (void)tapOnce:(id)sender {
  // You can't pause/resume when you are in options menu
  if ( ! self.optionsOverlay.hidden) {
    return;
  }
  
  self.firstOverlay.hidden = !self.firstOverlay.hidden;
}


- (void)playerViewController:(VYBPlayerViewController *)playerVC didFinishSetup:(BOOL)ready {
  if (ready) {
    [self presentViewController:playerVC animated:YES completion:^{
      [playerVC playCurrentItem];
    }];
  }
}


/**
 * User Interactions
 **/

#pragma mark - User Interactions

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
  return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
  return YES;
}

- (void)longPressDetected:(UIGestureRecognizer *)recognizer {
  switch (recognizer.state) {
    case UIGestureRecognizerStateBegan:
      self.loopImageView.hidden = NO;
        _loopCurrItem = YES;
      break;
    case UIGestureRecognizerStateCancelled:
    case UIGestureRecognizerStateEnded:
      self.loopImageView.hidden = YES;
        _loopCurrItem = NO;
      break;
    default:
      break;
  }
}

- (void)swipeUpDetected:(UIGestureRecognizer *)recognizer {
  PFObject *currObj = _zoneVybes[_zoneCurrIdx];
  if (currObj) {
    
  }
}

#pragma mark - Map

- (void)presentMapViewController {
  PFObject *vybeObj = _zoneVybes[_zoneCurrIdx];
  CLLocationCoordinate2D targetLocation;

  if (vybeObj[kVYBVybeZoneLatitudeKey]) {
    double lat = [(NSNumber *)vybeObj[kVYBVybeZoneLatitudeKey] doubleValue];
    double lng = [(NSNumber *)vybeObj[kVYBVybeZoneLongitudeKey] doubleValue];
    targetLocation = CLLocationCoordinate2DMake(lat, lng);
  }
  else if (vybeObj[kVYBVybeGeotagKey]) {
    PFGeoPoint *geoPt = vybeObj[kVYBVybeGeotagKey];
    targetLocation = CLLocationCoordinate2DMake(geoPt.latitude, geoPt.longitude);
  }
  
  VYBMapViewController *mapVC = [[VYBMapViewController alloc] init];
  mapVC.delegate = self;
  [mapVC displayLocation:targetLocation];
}

- (void)dismissMapViewController {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)optionsButtonPressed:(id)sender {
  if (self.optionsButton.selected) {
    self.optionsOverlay.hidden = YES;
    
    self.topBarBG.hidden = NO;
    self.dismissButton.hidden = NO;
    self.addButton.hidden = NO;
    self.timeLabel.hidden = NO;
    
    [self.currPlayer play];
  }
  else {
    self.optionsOverlay.hidden = NO;
    
    self.goNextButton.hidden = YES;
    self.goPrevButton.hidden = YES;
    self.topBarBG.hidden = YES;
    self.dismissButton.hidden = YES;
    self.addButton.hidden = YES;
    self.timeLabel.hidden = YES;
    
    [self.currPlayer pause];
  }
  self.optionsButton.selected = !self.optionsButton.selected;
}

- (IBAction)dismissButtonPressed {
  [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)flagOverlayButtonPressed {
  if (self.flagOverlayButton.selected) {
    NSString *functionName = @"unflag_vybe";
    PFObject *currObj = _zoneVybes[_zoneCurrIdx];
    if (currObj) {
      [PFCloud callFunctionInBackground:functionName withParameters:@{@"vybeID": currObj.objectId} block:^(PFObject *unflaggedObj, NSError *error) {
        if (!error) {
          NSLog(@"Reported UNFLAG: vybe(%@)", unflaggedObj);
        }
      }];
    }
    
    [[VYBCache sharedCache] setAttributesForVybe:currObj flaggedByCurrentUser:NO];
    self.flagOverlayButton.selected = NO;
  }
  else {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"You are reporting this content as inappropriate" preferredStyle:UIAlertControllerStyleAlert];  UIAlertAction *blockAction = [UIAlertAction actionWithTitle:@"Flag" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
      //Flag this vybe
      NSString *functionName = @"flag_vybe";
      PFObject *currObj = _zoneVybes[_zoneCurrIdx];
      if (currObj) {
        [PFCloud callFunctionInBackground:functionName withParameters:@{@"vybeID": currObj.objectId} block:^(PFObject *flaggedObj, NSError *error) {
          if (!error) {
            NSLog(@"Reported FLAG: vybe(%@)", flaggedObj.objectId);
          }
        }];
      }
      
      [[VYBCache sharedCache] setAttributesForVybe:currObj flaggedByCurrentUser:YES];
      self.flagOverlayButton.selected = YES;
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:blockAction];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
  }
}

- (IBAction)blockOverlayButtonPressed {
  if (self.blockOverlayButton.selected) {
    self.blockOverlayButton.selected = NO;
    PFObject *currObj = _zoneVybes[_zoneCurrIdx];
    if (currObj) {
      PFUser *aUser = currObj[kVYBVybeUserKey];
      PFRelation *blacklist = [[PFUser currentUser] relationForKey:kVYBUserBlockedUsersKey];
      [blacklist removeObject:aUser];
      [[PFUser currentUser] saveInBackground];
      [[VYBCache sharedCache] removeBlockedUser:aUser forUser:[PFUser currentUser]];
    }
  }
  else {
    PFObject *currObj = _zoneVybes[_zoneCurrIdx];
    if (currObj) {
      PFUser *aUser = currObj[kVYBVybeUserKey];
      if ( [aUser.objectId isEqualToString:[PFUser currentUser].objectId] ) {
        return;
      }
      
      UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"You are blocking this user" message:@"You will not receive any content from this user." preferredStyle:UIAlertControllerStyleAlert];
      UIAlertAction *blockAction = [UIAlertAction actionWithTitle:@"Block" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        self.blockOverlayButton.selected = YES;
        
      PFRelation *blacklist = [[PFUser currentUser] relationForKey:kVYBUserBlockedUsersKey];
        [blacklist addObject:aUser];
        [[PFUser currentUser] saveInBackground];
        [[VYBCache sharedCache] addBlockedUser:aUser forUser:[PFUser currentUser]];
      }];
      UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
      [alertController addAction:blockAction];
      [alertController addAction:cancelAction];

      [self presentViewController:alertController animated:YES completion:nil];
    }
  }
}




@end
