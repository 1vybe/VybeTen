//
//  VYBReplayViewController.m
//  VybeTen
//
//  Created by jinsuk on 7/11/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//
#import "VYBReplayViewController.h"
#import "VYBPlayerView.h"
#import "MBProgressHUD.h"
#import "VYBUtility.h"

#import "VYBNavigationController.h"
#import "AVAsset+VideoOrientation.h"

#import "Vybe-Swift.h"

@interface VYBReplayViewController () <UITextFieldDelegate, UIActionSheetDelegate>
@property (nonatomic, weak) IBOutlet VYBPlayerView *playerView;

@property (nonatomic, weak) IBOutlet UIView *overlayView;
@property (nonatomic, weak) IBOutlet UIImageView *bottomBarImageView;
@property (nonatomic, weak) IBOutlet UIButton *rejectButton;

@property (nonatomic, weak) IBOutlet UILabel *checkInLabel;
@property (nonatomic, weak) IBOutlet UIButton *checkAerial;

- (IBAction)rejectButtonPressed:(id)sender;
- (IBAction)checkInButtonPressed:(id)sender;
- (IBAction)acceptButtonPressed:(id)sender;
- (IBAction)hashtagButtonPressed:(id)sender;

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

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    _videoPath = [[[MyVybeStore sharedInstance] currVybe] videoFilePath];
    _thumbnailPath = [[[MyVybeStore sharedInstance] currVybe] thumbnailFilePath];
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.player = [[AVPlayer alloc] init];
  [self.playerView setPlayer:self.player];
  
  Zone *lastZone = [[MyVybeStore sharedInstance] currZone];
  if (lastZone && [[SpotFinder sharedInstance] suggestionsContainSpot:lastZone]) {
    [[MyVybeStore sharedInstance] setCurrZone:lastZone];
    [self.checkInLabel setText:lastZone.name];
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
  
  UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissHashtag)];
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
- (IBAction)checkInButtonPressed:(id)sender {
  [self.checkAerial setEnabled:NO];
  self.overlayView.hidden = YES;
  
  // NOTE: - Before ios8 prsentingVC's modalPresentationStyle needed to be set.
//  self.modalPresentationStyle = UIModalPresentationCurrentContext;

  CheckInViewController *checkInTable = [[CheckInViewController alloc] initWithNibName:@"CheckInViewController" bundle:nil];
  [checkInTable setModalPresentationStyle:UIModalPresentationOverCurrentContext];
  
  [self presentViewController:checkInTable animated:YES completion:nil];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
  [super dismissViewControllerAnimated:flag completion:completion];
  
  if (self.overlayView.hidden) {
    self.overlayView.hidden = NO;
  }
  
  Zone *selected = [[MyVybeStore sharedInstance] currZone];
  if (selected) {
    [self.checkInLabel setText:selected.name];
  }
  [self.checkAerial setEnabled:YES];
}

- (IBAction)acceptButtonPressed:(id)sender {
  [[MyVybeStore sharedInstance] uploadCurrentVybe];
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

- (void)dismissHashtag {
  if (_isEditingCaption) {
    [self.captionTextField removeFromSuperview];
    self.captionTextField = nil;
    
    [self.view endEditing:YES];
  }
}

- (IBAction)hashtagButtonPressed:(id)sender {
  if (_isEditingCaption) {
    [self.captionTextField removeFromSuperview];
    self.captionTextField = nil;
    
    [self.view endEditing:YES];
  } else {
    if (self.captionTextField.superview) {
      [[MyVybeStore sharedInstance] clearCurrHashTags];
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
    
    
    // MyVybeStore.addHashTagForCurrentVybe() filters hash tags
    NSArray *filtered = [[MyVybeStore sharedInstance] currHashTags];
    NSString *filteredHashTagsText = @"";
    for (NSString *tagName in filtered) {
      filteredHashTagsText = [filteredHashTagsText stringByAppendingString:@"#"];
      filteredHashTagsText = [filteredHashTagsText stringByAppendingString:tagName];
      if (![tagName isEqual:filtered.lastObject]) {
        filteredHashTagsText = [filteredHashTagsText stringByAppendingString:@" "];
      }
    }
    self.captionTextField.text = filteredHashTagsText;
    
    return YES;
  }
  
  return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
  const char * _char = [string cStringUsingEncoding:NSUTF8StringEncoding];
  int isBackSpace = strcmp(_char, "\b");
  
  if (isBackSpace == -8) {
    if ( [textField.text isEqualToString:@"#"] ) {
      return NO;
    } else {
      return YES;
    }
  }
  
  NSArray *forbiddenChars = @[@"!", @"@", @"#", @"$", @"%", @"^", @"&", @"*", @":", @";", @"'", @"\"", @"(", @")", @"<", @">", @"/", @","];
  for (NSString *forbidden in forbiddenChars) {
    if ( [forbidden isEqualToString:string] ) {
      return NO;
    }
  }
  
  NSArray *tags = [textField.text componentsSeparatedByString:@"#"];
  NSString *currentTag = tags.lastObject;
  
  if ( [string isEqualToString:@" "] ) {
    // Currently only THREE hash tags can be tagged to a vybe.
    if (tags.count < 4) { // tags first object is ""
      self.captionTextField.text = [self.captionTextField.text stringByAppendingString:@" #"];
    }
    
    return NO;
  } else {
    // each tag is limited to max 12 characters.
    if (currentTag.length >= 12) {
      return NO;
    }
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
