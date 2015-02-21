
//
//  VYBCaptureViewController.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 21..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import <CoreLocation/CoreLocation.h>
#import <MotionOrientation@PTEz/MotionOrientation.h>
#import "VYBCapturePipeline.h"
#import "VYBCaptureViewController.h"
#import "VYBCache.h"
#import "VYBUtility.h"

#import "Vybe-Swift.h"

@interface VYBCaptureViewController () <VYBCapturePipelineDelegate, SelectTribeDelegate, UIAlertViewDelegate, UIActionSheetDelegate> {
  NSInteger _pageIndex;
}
@property (nonatomic, weak) IBOutlet UIView *overlayView;
@property (nonatomic, weak) IBOutlet UIButton *flipButton;
@property (nonatomic, weak) IBOutlet UIButton *flashButton;
@property (nonatomic, weak) IBOutlet UIButton *recordButton;

@property (nonatomic, weak) IBOutlet UIButton *homeButton;
@property (nonatomic, weak) IBOutlet UIButton *chooseTribeButton;
@property (nonatomic, weak) IBOutlet UILabel *tribeLabel;

@property (nonatomic, weak) IBOutlet UIImageView *focusTarget;

@property (nonatomic, strong) UIProgressView *progressBar;

- (IBAction)homeButtonPressed:(id)sender;
- (IBAction)flipButtonPressed:(id)sender;
- (IBAction)flashButtonPressed:(id)sender;
//- (IBAction)recordButtonPressed:(id)sender;

@property (nonatomic) VYBCapturePipeline *capturePipeline;

@end

static void *XYZContext = &XYZContext;
@implementation VYBCaptureViewController {
  NSDate *startTime;
  NSTimer *_timeBomb;
  NSInteger _timerCount;
  CMTime lastSampleTime;
  
  BOOL _flashOn;
  BOOL _isFrontCamera;
  BOOL _isRecording;
  
  AVCaptureVideoOrientation _captureOrientation;
  
  dispatch_queue_t motion_orientation_queue;
  
  UIBackgroundTaskIdentifier _backgroundRecordingID;
}

@synthesize flipButton;
@synthesize flashButton;
@synthesize recordButton;
@synthesize capturePipeline;

- (void)dealloc {
  [capturePipeline stopRunning];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBAppDelegateApplicationDidBecomeActiveNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBAppDelegateApplicationDidEnterBackgourndNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBUtilityActivityCountUpdatedNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionInterruptionNotification object:nil];
}

- (void)viewDidLoad
{
  // Subscribing to Notifications
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActiveNotificationReceived:) name:VYBAppDelegateApplicationDidBecomeActiveNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackgroundNotificationReceived:) name:VYBAppDelegateApplicationDidEnterBackgourndNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityCountChanged) name:VYBUtilityActivityCountUpdatedNotification object:nil];
  
  // In case capture screen is loaded AFTER initial loading from appdelegate is done already
  [self activityCountChanged];
  
  // Device orientation detection
  motion_orientation_queue = dispatch_queue_create("com.vybe.app.capture.motion.orientation.queue", NULL);
  dispatch_async(motion_orientation_queue, ^{
    [MotionOrientation initialize];
  });
  
  _captureOrientation = AVCaptureVideoOrientationPortrait;
  
  capturePipeline = [[VYBCapturePipeline alloc] init];
  [capturePipeline setDelegate:self callbackQueue:dispatch_get_main_queue()];
  
  // Audio session setting
  NSError *error;
  AVAudioSession *audioSession = [AVAudioSession sharedInstance];
  [audioSession setCategory:AVAudioSessionCategoryPlayback error:&error];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionInterrupted:) name:AVAudioSessionInterruptionNotification object:nil];
  
  [super viewDidLoad];
  
  // Tap to focus and expose
  UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusOnTouchArea:)];
  [self.view addGestureRecognizer:tapGesture];
  self.focusTarget.alpha = 0;
  
  UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressDetected:)];
  longPress.minimumPressDuration = 0.2;
  [self.recordButton addGestureRecognizer:longPress];
  
  // Progress Bar
  self.progressBar = [[UIProgressView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 12, self.view.bounds.size.width, 12)];
  
//  UIImage *trackImage = [[UIImage imageNamed:@"ProgressTile(fade)"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 1, 0, 1) resizingMode:UIImageResizingModeStretch];
//  [self.progressBar setTrackImage:trackImage];
//  UIImage *progressImage = [[UIImage imageNamed:@"ProgressTile(Fill)"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 1, 0, 1) resizingMode:UIImageResizingModeStretch];
//  [self.progressBar setProgressImage:progressImage];
  
//  [self.progressBar setProgress:0.7];
  
  [self.view insertSubview:self.progressBar aboveSubview:self.cameraView];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  PFObject *currTribe = [[MyVybeStore sharedInstance] currTribe];
  if (currTribe) {
    self.tribeLabel.text = currTribe[kVYBTribeNameKey];
  }
  
  // NOTE: - Suspicion.
  [capturePipeline startRunning];
  
  self.progressBar.progress = 0.0;
  
  flashButton.selected = _flashOn;
  flipButton.selected = _isFrontCamera;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
#ifdef DEBUG
#else
  [[GAI sharedInstance].defaultTracker set:kGAIScreenName
                                     value:@"Capture Screen"];
  // Send the screen view.
  [[GAI sharedInstance].defaultTracker
   send:[[GAIDictionaryBuilder createAppView] build]];
#endif
  [self resetRotationOfElements];
  
  dispatch_async(motion_orientation_queue, ^{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceRotated:)
                                                 name:MotionOrientationChangedNotification
                                               object:nil];
  });
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:MotionOrientationChangedNotification object:nil];
}

- (void)longPressDetected:(UILongPressGestureRecognizer *)recognizer {
  switch (recognizer.state) {
    case UIGestureRecognizerStateBegan:
      if (!_isRecording) {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        
        if ( [[UIDevice currentDevice] isMultitaskingSupported] )
          _backgroundRecordingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];
        
        [[MyVybeStore sharedInstance] prepareNewVybe];
        [[SpotFinder sharedInstance] findSpotFromCurrentLocationInBackground];
        
        [recordButton setEnabled:NO];
        [recordButton setSelected:YES];
        
        [[AudioManager sharedInstance] activateCategoryPlayAndRecording];
        
        [capturePipeline setRecordingOrientation:_captureOrientation];
        [capturePipeline startRecording];
        
        _isRecording = YES;
        [self syncUIWithRecordingStatus];
      }
      break;
    case UIGestureRecognizerStateCancelled:
    case UIGestureRecognizerStateEnded:
      if (_isRecording) {
        [recordButton setEnabled:NO];
        [_timeBomb invalidate];
        [capturePipeline stopRecording];
      }
      break;
    default:
      break;
  }
}

- (void)recordingStopped {
  _isRecording = NO;
  [self syncUIWithRecordingStatus];
  
  [[AudioManager sharedInstance] activateCategoryPlaybackOnly];
  
  [recordButton setEnabled:YES];
  [recordButton setSelected:NO];
  [recordButton setTitle:@"" forState:UIControlStateNormal];
  
  [UIApplication sharedApplication].idleTimerDisabled = NO;
  
  [[UIApplication sharedApplication] endBackgroundTask:_backgroundRecordingID];
  _backgroundRecordingID = UIBackgroundTaskInvalid;
  
  VYBVybe *currVybe = [[MyVybeStore sharedInstance] currVybe];
  if (currVybe) {
    [VYBUtility saveThumbnailImageForVybe:currVybe];
    
    [self performSegueWithIdentifier:@"PreviewSegue" sender:self];
  }

}

#pragma mark - VYBCapturePipelineDelegate

- (void)capturePipeline:(VYBCapturePipeline *)pipeline didStopWithError:(NSError *)error {
  
}

- (void)capturePipelineRecordingDidStart:(VYBCapturePipeline *)pipeline {
  [recordButton setEnabled:YES];
  _timeBomb = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timer:) userInfo:nil repeats:YES];
  _timerCount = 150;
}

- (void)capturePipelineRecordingWillStop:(VYBCapturePipeline *)pipeline {
  [recordButton setEnabled:NO];
}

- (void)capturePipelineRecordingDidStop:(VYBCapturePipeline *)pipeline {
  [self recordingStopped];
}

- (void)capturePipeline:(VYBCapturePipeline *)pipeline recordingDidFailWithError:(NSError *)error {
  [self recordingStopped];
  
  NSLog(@"[CaptureVC] recording failed: %@", error);
}


#pragma mark - Capture Settings

- (IBAction)flipButtonPressed:(id)sender {
  
  [self.flipButton setEnabled:NO];
  [self.flashButton setEnabled:NO];
  [self.homeButton setEnabled:NO];
  [self.chooseTribeButton setEnabled:NO];
  
  [capturePipeline flipCameraWithCompletion:^(AVCaptureDevicePosition cameraPosition){
    dispatch_async(dispatch_get_main_queue(), ^{
      _isFrontCamera = (cameraPosition == AVCaptureDevicePositionFront);
      [[self flipButton] setSelected:_isFrontCamera];
      [[self flipButton] setEnabled:YES];
      [[self flashButton] setEnabled:YES];
      [[self flashButton] setHidden:_isFrontCamera];
      [self.homeButton setEnabled:YES];
      [self.chooseTribeButton setEnabled:YES];
    });
  }];
}


- (IBAction)flashButtonPressed:(id)sender {
  _flashOn = !_flashOn;
  flashButton.selected = _flashOn;
  [capturePipeline setFlashOn:_flashOn];
}


#pragma mark - UIResponder


- (void)timer:(NSTimer *)timer {
  _timerCount = _timerCount - 1;
  
  if (_timerCount > 0) {
    float percent = (150 - _timerCount) / 150.0;
    [self.progressBar setProgress:percent];
//    [recordButton setTitle:[NSString stringWithFormat:@"%u", (int)_timerCount] forState:UIControlStateSelected];
  }
  else {
    if (_isRecording) {
      [recordButton setEnabled:NO];
      [_timeBomb invalidate];
      _timeBomb = nil;
      [capturePipeline stopRecording];
    }
    
  }
}

#pragma mark - DeviceOrientation

- (BOOL)shouldAutorotate {
  return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait;
}

- (void)deviceRotated:(NSNotification *)notification {
  UIDeviceOrientation currentOrientation = [MotionOrientation sharedInstance].deviceOrientation;
  
  double rotation;
  switch (currentOrientation) {
    case UIDeviceOrientationUnknown:
    case UIDeviceOrientationFaceDown:
    case UIDeviceOrientationFaceUp:
    case UIDeviceOrientationPortrait:
    case UIDeviceOrientationPortraitUpsideDown:
      rotation = 0;
      _captureOrientation = AVCaptureVideoOrientationPortrait;
      break;
    case UIDeviceOrientationLandscapeLeft:
      rotation = M_PI_2;
      _captureOrientation = AVCaptureVideoOrientationLandscapeLeft;
      break;
    case UIDeviceOrientationLandscapeRight:
      rotation = -M_PI_2;
      _captureOrientation = AVCaptureVideoOrientationLandscapeRight;
      break;
  }
  
  CGAffineTransform transform = CGAffineTransformMakeRotation(rotation);
  dispatch_async(dispatch_get_main_queue(), ^{
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
      [recordButton setTransform:transform];
    } completion:nil];
  });
}

- (void)resetRotationOfElements {
  UIDeviceOrientation currentOrientation = [MotionOrientation sharedInstance].deviceOrientation;

  double rotation;
  switch (currentOrientation) {
    case UIDeviceOrientationUnknown:
    case UIDeviceOrientationFaceDown:
    case UIDeviceOrientationFaceUp:
    case UIDeviceOrientationPortrait:
    case UIDeviceOrientationPortraitUpsideDown:
      rotation = 0;
      _captureOrientation = AVCaptureVideoOrientationPortrait;
      break;
    case UIDeviceOrientationLandscapeLeft:
      rotation = M_PI_2;
      _captureOrientation = AVCaptureVideoOrientationLandscapeLeft;
      break;
    case UIDeviceOrientationLandscapeRight:
      rotation = -M_PI_2;
      _captureOrientation = AVCaptureVideoOrientationLandscapeRight;
      break;
  }
  CGAffineTransform transform = CGAffineTransformMakeRotation(rotation);
  [recordButton setTransform:transform];
}


- (BOOL)prefersStatusBarHidden {
  return YES;
}


#pragma mark - NSNotifications

- (void)applicationDidBecomeActiveNotificationReceived:(id)sender {
  // Refresh fetch of feed and activity count when app is brought to foreground
  //[VYBUtility getNewActivityCountWithCompletion:nil];
}

- (void)applicationDidEnterBackgroundNotificationReceived:(id)sender {
  // stop recording
  
  // clear out all
}

- (void)audioSessionInterrupted:(NSNotification *)notification {
  NSDictionary *userInfo = [notification userInfo];
  if (userInfo) {
    AVAudioSessionInterruptionType type = (AVAudioSessionInterruptionType)userInfo[AVAudioSessionInterruptionTypeKey];
    switch (type) {
      case AVAudioSessionInterruptionTypeBegan:
        [capturePipeline resetSessionWithCompletion:^{
          [[AudioManager sharedInstance] activateCategoryPlaybackOnly];
        }];
        break;
      case AVAudioSessionInterruptionTypeEnded:
      default:
        [capturePipeline resetSessionWithCompletion:^{
          [[AudioManager sharedInstance] activateCategoryPlayAndRecording];
        }];
        break;
    }
  }
}

- (void)activityCountChanged {
  
}

#pragma mark - Tap to focus

- (void)focusOnTouchArea:(UIGestureRecognizer *)gesture {
  if (_isRecording) {
    return;
  }
  CGPoint touchPt = [gesture locationInView:self.view];
  self.focusTarget.center = touchPt;
  self.focusTarget.alpha = 1.0;
  
  [UIView animateWithDuration:0.8 delay:0.3 options:UIViewAnimationOptionCurveEaseInOut animations:^{
    self.focusTarget.alpha = 0.0;
  } completion:nil];
  
  CGPoint scaledPt = [(AVCaptureVideoPreviewLayer *)self.cameraView.layer captureDevicePointOfInterestForPoint:touchPt];
  [capturePipeline setFocusPoint:scaledPt];
  [capturePipeline setExposurePoint:scaledPt];
}

#pragma mark - SelectTribeDelegate

- (void)didSelectTribe:(__nullable id)tribe {
  [self dismissViewControllerAnimated:YES completion:^{
    if (tribe && tribe[kVYBTribeNameKey]) {
      self.tribeLabel.text = tribe[kVYBTribeNameKey];
    } else {
      self.tribeLabel.text = @"Select Tribe";
    }
    self.overlayView.hidden = NO;
  }];
}

- (void)dismissSelectTribeViewContrller:(__nonnull SelectTribeViewController *)vc {
  [self dismissViewControllerAnimated:YES completion:^{
    self.overlayView.hidden = NO;
  }];
}

#pragma mark - ()

- (void)syncUIWithRecordingStatus {
  self.homeButton.hidden = _isRecording;
  self.tribeLabel.hidden = _isRecording;
  self.chooseTribeButton.hidden = _isRecording;
  
  flipButton.hidden = _isRecording;
  flashButton.hidden = _isRecording || _isFrontCamera;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ( [segue.identifier isEqualToString:@"SelectTribeSegue"] ) {
    SelectTribeViewController *selectTribe = (SelectTribeViewController *)segue.destinationViewController;
    selectTribe.delegate = self;
    
    self.overlayView.hidden = YES;
  }
}

- (IBAction)homeButtonPressed:(id)sender {
  SwipeContainerController *swipeContainer = (SwipeContainerController *)self.parentViewController;
  [swipeContainer moveToTribeScreenWithAnimation:YES];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  NSLog(@"[Capture] Memory Warning");
}

@end
