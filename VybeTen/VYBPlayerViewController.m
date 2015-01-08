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

@interface VYBPlayerViewController () <VYBPlayerViewControllerDelegate>
@property (nonatomic, weak) IBOutlet UIButton *bmpButton;
@property (nonatomic, weak) IBOutlet UILabel *bumpCountLabel;
@property (nonatomic, weak) IBOutlet UILabel *timeLabel;

@property (nonatomic, weak) IBOutlet UIView *firstOverlay;

@property (nonatomic, weak) IBOutlet UILabel *locationLabel;
@property (nonatomic, weak) IBOutlet UILabel *usernameLabel;
@property (nonatomic, weak) IBOutlet UIButton *dismissButton;
@property (nonatomic, weak) IBOutlet UIButton *optionsButton;

@property (nonatomic, weak) IBOutlet UIButton *goPrevButton;
@property (nonatomic, weak) IBOutlet UIButton *goNextButton;
@property (nonatomic, weak) IBOutlet UIButton *nextAerialButton;
@property (nonatomic, weak) IBOutlet UIButton *prevAerialButton;

@property (nonatomic, weak) IBOutlet UIView *optionsOverlay;
@property (nonatomic, weak) IBOutlet UIButton *flagOverlayButton;
@property (nonatomic, weak) IBOutlet UIButton *blockOverlayButton;

@property (nonatomic, weak) IBOutlet UIButton *firstHashtag;
@property (nonatomic, weak) IBOutlet UIButton *secondHashtag;
@property (nonatomic, weak) IBOutlet UIButton *thirdHashtag;
@property (nonatomic) NSArray *hashtagButtons;

- (IBAction)goNextButtonPressed:(id)sender;
- (IBAction)goPrevButtonPressed:(id)sender;
- (IBAction)dismissButtonPressed;
- (IBAction)optionsButtonPressed:(id)sender;

- (IBAction)flagOverlayButtonPressed;
- (IBAction)blockOverlayButtonPressed;

- (IBAction)bmpButtonPressed:(id)sender;

- (IBAction)firstHashTagClicked:(id)sender;
- (IBAction)secondHashTagClicked:(id)sender;
- (IBAction)thirdHashTagClicked:(id)sender;


@property (nonatomic, weak) VYBPlayerView *currPlayerView;
@property (nonatomic) AVPlayer *currPlayer;
@property (nonatomic) AVPlayerItem *currItem;

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
  [self.view addGestureRecognizer:tapGesture];
  
  longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressDetected:)];
  longPressRecognizer.minimumPressDuration = 0.3;
  longPressRecognizer.delegate = self;
  [[UIApplication sharedApplication].keyWindow addGestureRecognizer:longPressRecognizer];
  
  self.optionsOverlay.hidden = YES;

  self.firstHashtag.hidden = YES;
  self.secondHashtag.hidden = YES;
  self.thirdHashtag.hidden = YES;
  self.hashtagButtons = @[self.firstHashtag, self.secondHashtag, self.thirdHashtag];
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
  
  [VYBUtility updateBumpCountInBackground:vybe withBlock:^(BOOL success) {
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
//  [query setCachePolicy:kPFCachePolicyCacheElseNetwork];
  [query includeKey:kVYBVybeUserKey];
  [query whereKey:kVYBVybeTimestampKey greaterThanOrEqualTo:someTimeAgo];
  [query orderByAscending:kVYBVybeTimestampKey];
  // NOTE: - Blocked users, flagged iterms are not filter
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
    dispatch_async(dispatch_get_main_queue(), ^{
      [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
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
  
  // Display hashtags
  NSArray *hashtags = aVybe[kVYBVybeHashtagsKey];
  if (hashtags) {
    for (UIButton *tagButton in self.hashtagButtons) {
      tagButton.hidden = YES;
    }
    for (int i = 0; i < hashtags.count; i++) {
      NSString *tagText = [NSString stringWithFormat:@"#%@", hashtags[i]];
      UIButton *tagButton = (UIButton *)self.hashtagButtons[i];
      [tagButton setTitle:tagText forState:UIControlStateNormal];
      tagButton.hidden = NO;
    }
  }
  
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
  
  [self.currPlayer play];
  self.lastTimePlayingAsset = [NSDate date];
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
  if (self.lastTimePlayingAsset && [self.lastTimePlayingAsset timeIntervalSinceNow] > -2.0) {
    [self playPrevItem];
  } else {
    [self playCurrentItemAgain];
  }
}

- (void)playCurrentItemAgain {
  [self playStream:_zoneVybes atIndex:_zoneCurrIdx];
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

- (void)tapOnce:(id)sender {
  // You can't pause/resume when you are in options menu
  if ( ! self.optionsOverlay.hidden) {
    return;
  }
  
  if (self.currPlayer.rate == 0.0) {
    [self.currPlayer play];
  }
  else {
    [self.currPlayer pause];
  }
}

- (IBAction)firstHashTagClicked:(id)sender {
  NSString *hashtag = [(UIButton *)self.hashtagButtons[0] titleLabel].text;
  [self jumpToStreamFor:hashtag];
}

- (IBAction)secondHashTagClicked:(id)sender {
  NSString *hashtag = [(UIButton *)self.hashtagButtons[1] titleLabel].text;
  [self jumpToStreamFor:hashtag];
}

- (IBAction)thirdHashTagClicked:(id)sender {
  NSString *hashtag = [(UIButton *)self.hashtagButtons[2] titleLabel].text;
  [self jumpToStreamFor:hashtag];
}

- (void)jumpToStreamFor:(NSString *)hashtag {
  [self.currPlayer pause];
  
  NSString *tagName = [hashtag substringFromIndex:1].lowercaseString;
  
  PFQuery *query = [PFQuery queryWithClassName:kVYBHashtagClassKey];
  [query whereKey:kVYBHashtagLowercaseKey equalTo:tagName];

  [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  [query getFirstObjectInBackgroundWithBlock:^(PFObject *tagObject, NSError *error) {
    if (!error) {
      PFRelation *vybes = tagObject[kVYBHashtagVybesKey];
      PFQuery *sQuery = vybes.query;
      [sQuery includeKey:kVYBVybeUserKey];
      [sQuery orderByDescending:kVYBVybeTimestampKey];
      [sQuery setLimit:12];
      [sQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
          VYBPlayerViewController *sPlayerVC = [[VYBPlayerViewController alloc] initWithNibName:@"VYBPlayerViewController" bundle:nil];
          sPlayerVC.delegate = self;
          [sPlayerVC playStream:[[objects reverseObjectEnumerator] allObjects]]; // b/c objects are ordered by descending
        } else {
          // Jump failed
        }
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
      }];
    } else {
      // Jump failed
      [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }
  }];
}

- (void)playerViewController:(VYBPlayerViewController *)playerVC didFinishSetup:(BOOL)ready {
  if (ready) {
    [self presentViewController:playerVC animated:YES completion:nil];
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
    
    [UIView animateWithDuration:0.6 delay:0.2 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
    } completion:nil];
  }
  
  [self updateBumpCountFor:currVybe];
  
  self.bmpButton.selected = !self.bmpButton.selected;
}

- (void)updateBumpCountFor:(PFObject *)aVybe {
  NSNumber *counter = [[VYBCache sharedCache] likeCountForVybe:aVybe];
  if (counter && [counter intValue]) {
    self.bumpCountLabel.text = [NSString stringWithFormat:@"%@", counter];
  }
  else {
    self.bumpCountLabel.text = @"";
  }
}

- (IBAction)optionsButtonPressed:(id)sender {
  if (self.optionsButton.selected) {
    self.optionsOverlay.hidden = YES;
    self.goNextButton.hidden = NO;
    self.goPrevButton.hidden = NO;
    self.dismissButton.hidden = NO;
    self.bmpButton.hidden = NO;
    self.bumpCountLabel.hidden = NO;
    self.timeLabel.hidden = NO;
    
    [self.currPlayer play];
  }
  else {
    self.optionsOverlay.hidden = NO;
    self.goNextButton.hidden = YES;
    self.goPrevButton.hidden = YES;
    self.dismissButton.hidden = YES;
    self.bmpButton.hidden = YES;
    self.bumpCountLabel.hidden = YES;
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

#pragma mark - VYBAppDelegateNotification


- (void)remoteNotificationReceived:(id)sender {
  
}


#pragma mark - Map



@end
