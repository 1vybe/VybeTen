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

#import "VybeTen-Swift.h"

@interface VYBPlayerViewController ()
@property (nonatomic, weak) IBOutlet UIButton *bmpButton;
@property (nonatomic, weak) IBOutlet UILabel *bumpCountLabel;
@property (nonatomic, weak) IBOutlet UILabel *bumpCountGhost;
@property (nonatomic, weak) IBOutlet UILabel *timeLabel;

@property (nonatomic, weak) IBOutlet UIView *firstOverlay;

@property (nonatomic, weak) IBOutlet UILabel *locationLabel;
@property (nonatomic, weak) IBOutlet UILabel *usernameLabel;
@property (nonatomic, weak) IBOutlet UIButton *dismissButton;
@property (nonatomic, weak) IBOutlet UIButton *optionsButton;

@property (nonatomic, weak) IBOutlet UIView *interactionOverlay;
@property (nonatomic, weak) IBOutlet UIButton *goPrevButton;
@property (nonatomic, weak) IBOutlet UIButton *goNextButton;
@property (nonatomic, weak) IBOutlet UIButton *nextAerialButton;
@property (nonatomic, weak) IBOutlet UIButton *prevAerialButton;
@property (nonatomic, weak) IBOutlet UIButton *pauseButton;

@property (nonatomic, weak) IBOutlet UIView *optionsOverlay;
@property (nonatomic, weak) IBOutlet UIButton *flagOverlayButton;
@property (nonatomic, weak) IBOutlet UIButton *blockOverlayButton;

- (IBAction)goNextButtonPressed:(id)sender;
- (IBAction)goPrevButtonPressed:(id)sender;
- (IBAction)pauseButtonPressed:(id)sender;
- (IBAction)dismissButtonPressed;
- (IBAction)optionsButtonPressed:(id)sender;

- (IBAction)flagOverlayButtonPressed;
- (IBAction)blockOverlayButtonPressed;

- (IBAction)bmpButtonPressed:(id)sender;

@property (nonatomic, weak) VYBPlayerView *currPlayerView;
@property (nonatomic) AVPlayer *currPlayer;
@property (nonatomic) AVPlayerItem *currItem;


- (void)playAsset:(AVAsset *)asset;

@end

@interface DownloadQueue : NSObject
@end

@implementation DownloadQueue {
  NSArray *queue;
}

- (BOOL)isDownloading:(PFFile *)aFile {
  for (PFFile *file in queue) {
    if ([file.url isEqualToString:aFile.url]) {
      return YES;
    }
  }
  
  return NO;
}

- (void)insert:(PFFile *)newFile {
  if (queue) {
    queue = [queue arrayByAddingObject:newFile];
  } else {
    queue = [NSArray arrayWithObject:newFile];
  }
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
  
  BOOL _userPausedFromOptions;
    
  UILongPressGestureRecognizer *longPressRecognizer;
  
  DownloadQueue *downloadQueue;
}
@synthesize dismissButton;

@synthesize currPlayer = _currPlayer;
@synthesize currPlayerView = _currPlayerView;
@synthesize currItem = _currItem;

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBAppDelegateApplicationDidReceiveRemoteNotification object:nil];
  
  [[UIApplication sharedApplication].keyWindow removeGestureRecognizer:longPressRecognizer];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
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
  tapGesture.numberOfTapsRequired = 1;
  [self.view addGestureRecognizer:tapGesture];
  
  longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressDetected:)];
  longPressRecognizer.minimumPressDuration = 0.3;
  longPressRecognizer.delegate = self;
  [[UIApplication sharedApplication].keyWindow addGestureRecognizer:longPressRecognizer];
  
  self.optionsOverlay.hidden = YES;
  self.firstOverlay.hidden = YES;
  self.bumpCountGhost.hidden = YES;
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
    self.pauseButton.selected = NO;
  }
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
  NSURL *cacheURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
  cacheURL = [cacheURL URLByAppendingPathComponent:[vybe objectId]];
  cacheURL = [cacheURL URLByAppendingPathExtension:@"mp4"];
  
  [VYBUtility updateBumpCountInBackground:vybe withBlock:^(BOOL success) {
    PFFile *vid = [vybe objectForKey:kVYBVybeVideoKey];
    if ( ! [downloadQueue isDownloading:vid]) {
      [vid getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
          [data writeToURL:cacheURL atomically:YES];
          
          [self playVybe:vybe];
          completionBlock(YES);
        }
        else {
          completionBlock(NO);
        }
      }];
      
      [downloadQueue insert:vid];
    }
    completionBlock(NO);
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


- (void)playFeaturedVybes:(NSArray *)vybes {
  _zoneVybes = vybes;
  _zoneCurrIdx = 0;
  [self prepareVideoInBackgroundFor:_zoneVybes[_zoneCurrIdx] withCompletion:^(BOOL success) {
    [self.delegate playerViewController:self didFinishSetup:success];
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
    if (!error) {
      if (objects.count > 0) {
        _zoneVybes = objects;
        _zoneCurrIdx = 0;
        [self prepareVideoInBackgroundFor:_zoneVybes[_zoneCurrIdx] withCompletion:^(BOOL success) {
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
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      [self syncUIElementsFor:vybe];
    });
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:cacheURL options:nil];
    [self playAsset:asset];
    
    if (_isFreshStream) {
      [[ZoneStore sharedInstance] removeWatchedFromFreshFeed:vybe];
    }
    if (_zoneCurrIdx + 1 < _zoneVybes.count) {
      PFObject *nextItem = _zoneVybes[_zoneCurrIdx + 1];
      [self prepareVideoInBackgroundFor:nextItem withCompletion:^(BOOL success) {
        PFObject *currItem = _zoneVybes[_zoneCurrIdx];
        if ( [currItem.objectId isEqualToString:nextItem.objectId]) {
          [self.nextAerialButton setEnabled:YES];
        }
      }];
    }
  } else {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.nextAerialButton setEnabled:NO];
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
  
  self.bmpButton.selected = [[VYBCache sharedCache] vybeLikedByMe:aVybe];
  
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
      self.interactionOverlay.hidden = NO;
    }
    self.optionsButton.hidden = YES;
  } else {
    self.optionsButton.hidden = NO;
  }
  
  self.flagOverlayButton.selected = [[VYBCache sharedCache] vybeFlaggedByMe:aVybe];
  self.blockOverlayButton.selected = NO;
  
  [self updateBumpCountFor:aVybe];
}

- (void)playAsset:(AVAsset *)asset {
  [self.currPlayerView setOrientation:[asset videoOrientation]];
  
  self.currItem = [AVPlayerItem playerItemWithAsset:asset];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
  [self.currPlayer replaceCurrentItemWithPlayerItem:self.currItem];
  
  if (_userPausedFromOptions) {
    return;
  }
  
  [self.currPlayer play];
  self.pauseButton.selected = NO;

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
    self.pauseButton.selected = NO;
    [self.currPlayer play];
  }
  else {
    self.pauseButton.selected = YES;
    [self.currPlayer pause];
  }
}

- (void)tapOnce:(UIGestureRecognizer *)recognizer {
  
  CGPoint location = [recognizer locationInView:self.view];
  if (CGRectContainsPoint(self.goNextButton.frame, location) ||
      CGRectContainsPoint(self.goPrevButton.frame, location)) {
    return;
  }
  
  if (self.optionsOverlay.hidden) {
    menuMode = !menuMode;
    [self menuModeChanged];
    if (menuMode) {
      self.goPrevButton.hidden = (_zoneCurrIdx == 0);
      self.goNextButton.hidden = (_zoneCurrIdx == _zoneVybes.count - 1);
      [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(overlayTimerExpired:) userInfo:nil repeats:NO];
    }
  }
}

- (void)overlayTimerExpired:(NSTimer *)timer {
  self.goPrevButton.hidden = YES;
  self.goNextButton.hidden = YES;
  
  [timer invalidate];
}


- (void)menuModeChanged {
  self.firstOverlay.hidden = !menuMode;
  self.bumpCountGhost.hidden = !menuMode;
  PFObject *currVybe = _zoneVybes[_zoneCurrIdx];
  if (currVybe) {
    [self updateBumpCountFor:currVybe];
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
  CGPoint location = [recognizer locationInView:recognizer.view];
  CGRect locationAerial = CGRectMake(0, self.view.bounds.size.height - 50, 100, 50);
  BOOL isInLocationAerial = CGRectContainsPoint(locationAerial, location);

  switch (recognizer.state) {
    case UIGestureRecognizerStateBegan:
      if (isInLocationAerial) {
        [self presentMapViewController];
      }
      break;
    case UIGestureRecognizerStateCancelled:
    case UIGestureRecognizerStateEnded:
      [self dismissMapViewController];
      break;
    default:
      break;
  }


}

- (void)presentMapViewController {
  PFObject *vybeObj = _zoneVybes[_zoneCurrIdx];
  CLLocationCoordinate2D targetLocation;

  if (vybeObj[kVYBVybeZoneLatitudeKey]) {
    double lat = [(NSNumber *)vybeObj[kVYBVybeZoneLatitudeKey] doubleValue];
    double lng = [(NSNumber *)vybeObj[kVYBVybeZoneLongitudeKey] doubleValue];
    targetLocation = CLLocationCoordinate2DMake(lat, lng);
  }
  else if (vybeObj[kVYBVybeGeotag]) {
    PFGeoPoint *geoPt = vybeObj[kVYBVybeGeotag];
    targetLocation = CLLocationCoordinate2DMake(geoPt.latitude, geoPt.longitude);
  }
  
  VYBMapViewController *mapVC = [[VYBMapViewController alloc] init];
  mapVC.delegate = self;
  [mapVC displayLocation:targetLocation];
}

- (void)dismissMapViewController {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)bmpButtonPressed:(id)sender {
  PFObject *currVybe = _zoneVybes[_zoneCurrIdx];
  if (!currVybe)
    return;
  
  if (self.bmpButton.selected) {
    [VYBUtility unlikeVybeInBackground:currVybe block:nil];
  } else {
    [VYBUtility likeVybeInBackground:currVybe block:nil];
  }
  
  [self updateBumpCountFor:currVybe];
  self.bmpButton.selected = !self.bmpButton.selected;
}

- (void)updateBumpCountFor:(PFObject *)aVybe {
  
  NSNumber *counter = [[VYBCache sharedCache] likeCountForVybe:aVybe];
  if (counter && [counter intValue]) {
    if (self.firstOverlay.hidden) {
      self.bumpCountLabel.text = [NSString stringWithFormat:@"%@", counter];
    }
    else {
      self.bumpCountGhost.text = [NSString stringWithFormat:@"%@", counter];
      self.bumpCountLabel.text = ([counter intValue] > 1) ? @"Bumps" : @"Bump";
    }
  }
  else {
    if (self.firstOverlay.hidden) {
      self.bumpCountLabel.text = @"";
    }
    else {
      self.bumpCountGhost.text = @"";
      self.bumpCountLabel.text = @"";
    }
  }
}

- (IBAction)optionsButtonPressed:(id)sender {
  if (self.optionsButton.selected) {
    self.optionsOverlay.hidden = YES;
    self.interactionOverlay.hidden = NO;
  }
  else {
    self.optionsOverlay.hidden = NO;
    self.interactionOverlay.hidden = YES;
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
      
      [self.currPlayer play];
      self.pauseButton.selected = NO;
      _userPausedFromOptions = NO;
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
      [self.currPlayer play];
      self.pauseButton.selected = NO;
      _userPausedFromOptions = NO;
    }];
    [alertController addAction:blockAction];
    [alertController addAction:cancelAction];
    
    [self.currPlayer pause];
    _userPausedFromOptions = YES;
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
        
        [self.currPlayer play];
        self.pauseButton.selected = NO;
        _userPausedFromOptions = NO;
      }];
      UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self.currPlayer play];
        self.pauseButton.selected = NO;
        _userPausedFromOptions = NO;
      }];
      [alertController addAction:blockAction];
      [alertController addAction:cancelAction];
      
      [self.currPlayer pause];
      _userPausedFromOptions = YES;
      [self presentViewController:alertController animated:YES completion:nil];
    }
  }
}

#pragma mark - VYBAppDelegateNotification


- (void)remoteNotificationReceived:(id)sender {
  
}


#pragma mark - Map



@end
