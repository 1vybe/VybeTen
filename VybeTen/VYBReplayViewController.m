//
//  VYBReplayViewController.m
//  VybeTen
//
//  Created by jinsuk on 7/11/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBAppDelegate.h"
#import "VYBReplayViewController.h"
#import "VYBPlayerView.h"
#import "MBProgressHUD.h"
#import "VYBUtility.h"
#import "VYBMyVybeStore.h"
#import "VYBOldZoneFinder.h"
#import "VYBNavigationController.h"
#import "AVAsset+VideoOrientation.h"

@interface VYBReplayViewController () <UITextFieldDelegate, UIActionSheetDelegate>

@property (nonatomic, weak) IBOutlet UIButton *rejectButton;
@property (nonatomic, weak) IBOutlet UILabel *acceptLabel;
@property (nonatomic, weak) IBOutlet UIView *overlayView;
@property (nonatomic, weak) IBOutlet UILabel *zoneLabel;
@property (nonatomic, weak) IBOutlet VYBPlayerView *playerView;

- (IBAction)rejectButtonPressed:(id)sender;
- (IBAction)selectZoneButtonPressed:(id)sender;
- (IBAction)acceptButtonPressed:(id)sender;

@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerItem *currItem;

@end

@implementation VYBReplayViewController {
  NSString *_videoPath;
  NSString *_thumbnailPath;
  NSArray *_suggestions;
  AVURLAsset *currentAsset;
}

- (void)dealloc {
  self.player = nil;
  self.playerView = nil;
  currentAsset = nil;
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBMyVybeStoreLocationFetchedNotification object:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _videoPath = [[[VYBMyVybeStore sharedStore] currVybe] videoFilePath];
    _thumbnailPath = [[[VYBMyVybeStore sharedStore] currVybe] thumbnailFilePath];
    NSURL *videoURL = [[NSURL alloc] initFileURLWithPath:_videoPath];
    currentAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.player = [[AVPlayer alloc] init];
  [self.playerView setPlayer:self.player];
  
  Zone *lastZone = [[VYBMyVybeStore sharedStore] currZone];
  if (lastZone && [[ZoneFinder sharedInstance] suggestionsContainZone:lastZone]) {
    [[VYBMyVybeStore sharedStore] setCurrZone:lastZone];
    [self.zoneLabel setText:lastZone.name];
  }
  
  switch (currentAsset.videoOrientation) {
    case AVCaptureVideoOrientationPortrait:
    case AVCaptureVideoOrientationPortraitUpsideDown:
      [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
      break;
    case AVCaptureVideoOrientationLandscapeLeft:
      [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
      break;
    case AVCaptureVideoOrientationLandscapeRight:
      [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeLeft];
      break;
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  self.currItem = [AVPlayerItem playerItemWithAsset:currentAsset];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
  [self.player replaceCurrentItemWithPlayerItem:self.currItem];
  [self.player play];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self.player pause];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
}

- (void)playerItemDidReachEnd {
  [self.currItem seekToTime:kCMTimeZero];
  [self.player play];
}

#pragma mark - Zone
- (IBAction)selectZoneButtonPressed:(id)sender {
  [[ZoneFinder sharedInstance] findZoneNearLocationInBackground:^(BOOL success) {
    if (success) {
      NSArray *suggestions = [[ZoneFinder sharedInstance] suggestions];
      if (suggestions && suggestions.count > 0) {
        [self displayCurrentPlaceSuggestions:suggestions];
      }
    }
  }];
}

- (void)displayCurrentPlaceSuggestions:(NSArray *)suggestions {
  CLLocationManager *tmp = [[CLLocationManager alloc] init];
  BOOL isLatestOS = [tmp respondsToSelector:@selector(requestAlwaysAuthorization)];
  
  // iOS 8
  if (isLatestOS) {
    UIAlertController *checkInController = [UIAlertController alertControllerWithTitle:@"Check In" message:@"Where are you vybing? :)" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *noTagAction = [UIAlertAction actionWithTitle:@"No Check In" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
      [[VYBMyVybeStore sharedStore] setCurrZone:nil];
      [self.zoneLabel setText:@"Check In"];
    }];
    [checkInController addAction:noTagAction];
    
    for (Zone *aZone in suggestions) {
      UIAlertAction *action = [UIAlertAction actionWithTitle:aZone.name style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[VYBMyVybeStore sharedStore] setCurrZone:aZone];
        [self.zoneLabel setText:aZone.name];
      }];
      [checkInController addAction:action];
    }
    if (checkInController.actions.count > 0) {
      Zone *currZone = [[VYBMyVybeStore sharedStore] currZone];
      if (currZone) {
        [checkInController setMessage:[NSString stringWithFormat:@"Your are in %@", currZone.name]];
      }
    }
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"Go Back" style:UIAlertActionStyleCancel handler:nil];
    [checkInController addAction:action];
    
//    [checkInController setModalPresentationStyle:UIModalPresentationPopover];
    [self presentViewController:checkInController animated:YES completion:nil];
  
    
//    UIPopoverPresentationController *popOverController = [checkInController popoverPresentationController];
//    popOverController.sourceView = self.zoneLabel;
//    popOverController.sourceRect = CGRectMake(0, 0, 0, 0);
//    [self presentViewController:checkInController animated:YES completion:nil];
  }
  else {
    UIActionSheet *actionsheet = [[UIActionSheet alloc] initWithTitle:@"Where are you vybing?" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for (Zone *aZone in suggestions) {
      [actionsheet addButtonWithTitle:aZone.name];
    }
    [actionsheet addButtonWithTitle:@"Go Back"];
    actionsheet.cancelButtonIndex = suggestions.count;
    dispatch_async(dispatch_get_main_queue(), ^{
      [actionsheet showInView:[UIApplication sharedApplication].keyWindow];
    });
  }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  NSArray *suggestions = [[ZoneFinder sharedInstance] suggestions];
  // cancel button
  if (buttonIndex == suggestions.count) {
    
  }
  else {
    Zone *zone = suggestions[buttonIndex];
    [self.zoneLabel setText:zone.name];
    [[VYBMyVybeStore sharedStore] setCurrZone:zone];
  }
}


- (IBAction)acceptButtonPressed:(id)sender {
  [[VYBMyVybeStore sharedStore] uploadCurrentVybe];
  [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
  [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}


- (IBAction)rejectButtonPressed:(id)sender {
  // GA stuff
  id tracker = [[GAI sharedInstance] defaultTracker];
  if (tracker) {
    // upload cancel metric for capture_video event
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"capture_video" label:@"cancel" value:nil] build]];
  }
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    NSError *error;
    
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:_videoPath];
    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:&error];
    
    outputURL = [[NSURL alloc] initFileURLWithPath:_thumbnailPath];
    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:&error];

  });
  [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
  [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}


#pragma mark - DeviceOrientation

- (BOOL)shouldAutorotate {
  return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (BOOL)prefersStatusBarHidden {
  return YES;
}

@end
