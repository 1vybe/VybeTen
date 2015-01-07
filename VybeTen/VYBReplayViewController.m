//
//  VYBReplayViewController.m
//  VybeTen
//
//  Created by jinsuk on 7/11/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VybeTen-Swift.h"

#import "VYBReplayViewController.h"
#import "VYBPlayerView.h"
#import "MBProgressHUD.h"
#import "VYBUtility.h"
//#import "VYBMyVybeStore.h"

#import "VYBNavigationController.h"
#import "AVAsset+VideoOrientation.h"

@interface VYBReplayViewController () <UITextFieldDelegate, UIActionSheetDelegate>

@property (nonatomic, weak) IBOutlet UIButton *rejectButton;
@property (nonatomic, weak) IBOutlet UIView *overlayView;
@property (nonatomic, weak) IBOutlet UIImageView *bottomBarImageView;
@property (nonatomic, weak) IBOutlet UIButton *zoneButton;
@property (nonatomic, weak) IBOutlet VYBPlayerView *playerView;

- (IBAction)rejectButtonPressed:(id)sender;
- (IBAction)selectZoneButtonPressed:(id)sender;
- (IBAction)acceptButtonPressed:(id)sender;

@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerItem *currItem;

@property (nonatomic) SimpleTextField *captionTextField;
@end

@implementation VYBReplayViewController {
  NSString *_videoPath;
  NSString *_thumbnailPath;
  NSArray *_suggestions;
  AVURLAsset *currentAsset;
  
  BOOL _isEditingCaption;
}

- (void)dealloc {
  self.player = nil;
  self.playerView = nil;
  currentAsset = nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _videoPath = [[[VYBMyVybeStore sharedStore] currVybe] videoFilePath];
    _thumbnailPath = [[[VYBMyVybeStore sharedStore] currVybe] thumbnailFilePath];
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
    [self.zoneButton setTitle:lastZone.name forState:UIControlStateNormal];
    [self.zoneButton setBackgroundImage:nil forState:UIControlStateNormal];
  }
  
  NSURL *videoURL = [[NSURL alloc] initFileURLWithPath:_videoPath];
  currentAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
  
  NSNumber *value;
  switch (currentAsset.videoOrientation) {
    case AVCaptureVideoOrientationPortrait:
    case AVCaptureVideoOrientationPortraitUpsideDown:
      value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
      //      [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
      break;
    case AVCaptureVideoOrientationLandscapeLeft:
      value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
      //      [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
      break;
    case AVCaptureVideoOrientationLandscapeRight:
      value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeRight];
      //      [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeLeft];
      break;
  }
  // NOTE: - It's uncertain why setting currentDevice's orientation and statusBar's to the same does not produce the same outcome.
  if (value) {
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
  }
  
  UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addCaption:)];
  [self.view addGestureRecognizer:tapGesture];
  _isEditingCaption = NO;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
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
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

}

- (void)playerItemDidReachEnd {
  [self.currItem seekToTime:kCMTimeZero];
  [self.player play];
}

#pragma mark - Zone
- (IBAction)selectZoneButtonPressed:(id)sender {
  [self.zoneButton setEnabled:NO];
  [[ZoneFinder sharedInstance] findZoneNearLocationInBackground:^(BOOL success) {
      NSArray *suggestions = [[ZoneFinder sharedInstance] suggestedZones];
      if (suggestions && suggestions.count > 0) {
        [self displayCurrentPlaceSuggestions:suggestions];
      }
      [self.zoneButton setEnabled:YES];
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
      [self.zoneButton setEnabled:YES];
      [self.zoneButton setTitle:@"Check-in location" forState:UIControlStateNormal];
      [self.zoneButton setBackgroundImage:[UIImage imageNamed:@"Checkin-btn"] forState:UIControlStateNormal];
    }];
    [checkInController addAction:noTagAction];
    
    for (Zone *aZone in suggestions) {
      UIAlertAction *action = [UIAlertAction actionWithTitle:aZone.name style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[VYBMyVybeStore sharedStore] setCurrZone:aZone];
        [self.zoneButton setTitle:aZone.name forState:UIControlStateNormal];
        [self.zoneButton setBackgroundImage:nil forState:UIControlStateNormal];
        [self.zoneButton setEnabled:YES];
      }];
      [checkInController addAction:action];
    }
    if (checkInController.actions.count > 0) {
      Zone *currZone = [[VYBMyVybeStore sharedStore] currZone];
      if (currZone) {
        [checkInController setMessage:[NSString stringWithFormat:@"Your are in %@", currZone.name]];
      }
    }
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"Go Back" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
      [self.zoneButton setEnabled:YES];
    }];
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
    [self.zoneButton setTitle:zone.name forState:UIControlStateNormal];
    [self.zoneButton setBackgroundImage:nil forState:UIControlStateNormal];
    [[VYBMyVybeStore sharedStore] setCurrZone:zone];
  }
  [self.zoneButton setEnabled:YES];
}


- (IBAction)acceptButtonPressed:(id)sender {
  [[VYBMyVybeStore sharedStore] uploadCurrentVybe];
  [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
  [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}


- (IBAction)rejectButtonPressed:(id)sender {
#ifdef DEBUG
#else
  // GA stuff
  id tracker = [[GAI sharedInstance] defaultTracker];
  if (tracker) {
    // upload cancel metric for capture_video event
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"capture_video" label:@"cancel" value:nil] build]];
  }
#endif
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSError *error;
    
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:_videoPath];
    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:&error];
    
    outputURL = [[NSURL alloc] initFileURLWithPath:_thumbnailPath];
    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:&error];
  });
  [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
  [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

- (void)addCaption:(UIGestureRecognizer *)recognizer {
  if (_isEditingCaption) {
    [self.captionTextField removeFromSuperview];
    self.captionTextField = nil;
    
    [self.view endEditing:YES];
  } else {
    if (self.captionTextField.superview) {        // We only allow one hash tag for now
      [self.captionTextField removeFromSuperview];
    }
    
    self.captionTextField = [[SimpleTextField alloc] initWithFrame:CGRectMake(0.0, -30.0, self.view.bounds.size.width, 30.0)];
    [self.captionTextField setDelegate:self];
    
    [self.overlayView addSubview:self.captionTextField];
    [self.captionTextField becomeFirstResponder];
  }
}

- (void)keyboardWillShow:(NSNotification *)notification {
  if (_isEditingCaption) {
    return;
  }
  
  NSDictionary *userInfo = [notification userInfo];
  CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
  
  CGRect newFrame = self.captionTextField.frame;
  newFrame.origin.y = self.view.bounds.size.height - (keyboardSize.height + 30.0);
  
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationDelay:0.1f];
  [UIView setAnimationDuration:0.4f];
  [self.captionTextField setFrame:newFrame];
  [UIView commitAnimations];
  
  _isEditingCaption = YES;
}

- (void)keyboardWillHide:(NSNotification *)notification {
  _isEditingCaption = NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  if (self.captionTextField.text && self.captionTextField.text.length > 3) {
    [[MyVybeStore sharedInstance] addHashTagForCurrentVybe:self.captionTextField.text];
    
    [self.captionTextField resignFirstResponder];
    
    CGRect newFrame = self.captionTextField.frame;
    newFrame.origin.y = self.view.bounds.size.height - self.bottomBarImageView.bounds.size.height;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDelay:0.2f];
    [UIView setAnimationDuration:0.2f];
    [self.captionTextField setFrame:newFrame];
    [UIView commitAnimations];
    
    return YES;
  }
  
  return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
  if ( [string isEqualToString:@" "] ) {
    self.captionTextField.text = [self.captionTextField.text stringByAppendingString:@" #"];
    return NO;
  }
  
  return YES;
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
