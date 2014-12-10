
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
//#import <MotionOrientation@PTEz/MotionOrientation.h>
#import "VYBCapturePipeline.h"
#import "VYBCaptureViewController.h"
#import "VYBReplayViewController.h"
#import "VYBCaptureButton.h"
#import "VYBActiveButton.h"
#import "VYBCameraView.h"
#import "VYBCache.h"
#import "VYBUtility.h"
#import "VYBMyVybeStore.h"

#import "VybeTen-Swift.h"

@interface VYBCaptureViewController () <VYBCapturePipelineDelegate, UIAlertViewDelegate, UIActionSheetDelegate> {
  NSInteger _pageIndex;
}

@property (nonatomic, weak) IBOutlet UIButton *flipButton;
@property (nonatomic, weak) IBOutlet UIButton *flashButton;
@property (nonatomic, weak) IBOutlet UIButton *activityButton;
@property (nonatomic, weak) IBOutlet VYBCameraView *cameraView;
@property (nonatomic, weak) IBOutlet UIButton *recordButton;
@property (nonatomic, weak) IBOutlet CircleProgressView *uploadProgressView;

- (IBAction)activityButtonPressed:(id)sender;
- (IBAction)flipButtonPressed:(id)sender;
- (IBAction)flashButtonPressed:(id)sender;
- (IBAction)recordButtonPressed:(id)sender;

//@property (nonatomic) VYBMyVybe *currVybe;
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
  
  UIBackgroundTaskIdentifier _backgroundRecordingID;
  
}

@synthesize flipButton;
@synthesize flashButton;
@synthesize recordButton;
@synthesize capturePipeline;

- (void)dealloc {
  [capturePipeline stopRunning];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBAppDelegateApplicationDidReceiveRemoteNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBAppDelegateApplicationDidBecomeActiveNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBAppDelegateApplicationDidEnterBackgourndNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBUtilityActivityCountUpdatedNotification object:nil];
  
  [[VYBMyVybeStore sharedStore] removeObserver:self forKeyPath:@"currentUploadPercent" context:XYZContext];
  [[VYBMyVybeStore sharedStore] removeObserver:self forKeyPath:@"currentUploadStatus" context:XYZContext];
}

- (id)initWithPageIndex:(NSInteger)pageIndex {
  self = [super init];
  if (self) {
    if (pageIndex != VYBCapturePageIndex)
      return nil;
    
    _pageIndex = pageIndex;
  }
  return self;
}

- (NSInteger)pageIndex {
  return _pageIndex;
}

- (void)viewDidLoad
{
  _captureOrientation = AVCaptureVideoOrientationPortrait;
  
  // Subscribing to Notifications
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteNotificationReceived:) name:VYBAppDelegateApplicationDidReceiveRemoteNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActiveNotificationReceived:) name:VYBAppDelegateApplicationDidBecomeActiveNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackgroundNotificationReceived:) name:VYBAppDelegateApplicationDidEnterBackgourndNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityCountChanged) name:VYBUtilityActivityCountUpdatedNotification object:nil];
  
  
  // In case capture screen is loaded AFTER initial loading from appdelegate is done already
  [self activityCountChanged];
  
  // Device orientation detection
  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  
  [(AVCaptureVideoPreviewLayer *)[self.cameraView layer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
  
  capturePipeline = [[VYBCapturePipeline alloc] init];
  [capturePipeline setDelegate:self callbackQueue:dispatch_get_main_queue()];
  
  [super viewDidLoad];
  
  self.uploadProgressView.hidden = YES;
  
  [[VYBMyVybeStore sharedStore] addObserver:self forKeyPath:@"currentUploadPercent" options:NSKeyValueObservingOptionNew context:XYZContext];
  [[VYBMyVybeStore sharedStore] addObserver:self forKeyPath:@"currentUploadStatus" options:NSKeyValueObservingOptionNew context:XYZContext];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [capturePipeline startRunning];
  
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
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(deviceRotated:)
                                               name:UIDeviceOrientationDidChangeNotification
                                             object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (IBAction)recordButtonPressed:(id)sende {
  if (!_isRecording) {
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    if ( [[UIDevice currentDevice] isMultitaskingSupported] )
      _backgroundRecordingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];
    
    [[VYBMyVybeStore sharedStore] prepareNewVybe];
    
    [[ZoneFinder sharedInstance] findZoneFromCurrentLocationInBackground];
    
    [recordButton setEnabled:NO];
    
    [recordButton setSelected:YES];
    
    [capturePipeline setRecordingOrientation:_captureOrientation];
    [capturePipeline startRecording];
   
    _isRecording = YES;
    [self syncUIWithRecordingStatus];
  }
  else {
    [recordButton setEnabled:NO];
    [_timeBomb invalidate];
    [capturePipeline stopRecording];
  }
}

- (void)recordingStopped {
  _isRecording = NO;
  
  [self syncUIWithRecordingStatus];
  [recordButton setEnabled:YES];
  [recordButton setSelected:NO];
  [recordButton setTitle:@"" forState:UIControlStateNormal];
  
  
  [UIApplication sharedApplication].idleTimerDisabled = NO;
  
  [[UIApplication sharedApplication] endBackgroundTask:_backgroundRecordingID];
  _backgroundRecordingID = UIBackgroundTaskInvalid;
  
  VYBVybe *currVybe = [[VYBMyVybeStore sharedStore] currVybe];
  [VYBUtility saveThumbnailImageForVybe:currVybe];
  
  VYBReplayViewController *replayVC = [[VYBReplayViewController alloc] initWithNibName:@"VYBReplayViewController" bundle:nil];
  [self presentViewController:replayVC animated:NO completion:nil];
}

#pragma mark - VYBCapturePipelineDelegate

- (void)capturePipeline:(VYBCapturePipeline *)pipeline sessionPreviewReadyForDisplay:(AVCaptureSession *)session {
  [self.cameraView setSession:session];
  
}

- (void)capturePipeline:(VYBCapturePipeline *)pipeline didStopWithError:(NSError *)error {
  
}

- (void)capturePipelineRecordingDidStart:(VYBCapturePipeline *)pipeline {
  [recordButton setEnabled:YES];
  _timeBomb = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timer:) userInfo:nil repeats:YES];
  [recordButton setTitle:[NSString stringWithFormat:@"%d", VYBE_LENGTH_SEC] forState:UIControlStateSelected];
  _timerCount = 15;
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
  
  [[self flipButton] setEnabled:NO];
  [[self flashButton] setEnabled:NO];
  [[self activityButton] setEnabled:NO];
  
  [capturePipeline flipCameraWithCompletion:^(AVCaptureDevicePosition cameraPosition){
    dispatch_async(dispatch_get_main_queue(), ^{
      _isFrontCamera = (cameraPosition == AVCaptureDevicePositionFront);
      [[self flipButton] setSelected:_isFrontCamera];
      [[self flipButton] setEnabled:YES];
      [[self flashButton] setEnabled:YES];
      [[self flashButton] setHidden:_isFrontCamera];
      [[self activityButton] setEnabled:YES];
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
    [recordButton setTitle:[NSString stringWithFormat:@"%u", (int)_timerCount] forState:UIControlStateSelected];
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
  UIDeviceOrientation currentOrientation = [UIDevice currentDevice].orientation ;
  
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
      _captureOrientation = AVCaptureVideoOrientationLandscapeRight;
      break;
    case UIDeviceOrientationLandscapeRight:
      rotation = -M_PI_2;
      _captureOrientation = AVCaptureVideoOrientationLandscapeLeft;
      break;
  }
  
  CGAffineTransform transform = CGAffineTransformMakeRotation(rotation);
  dispatch_async(dispatch_get_main_queue(), ^{
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
      [self.flipButton setTransform:transform];
      [self.flashButton setTransform:transform];
      [self.activityButton setTransform:transform];
      [recordButton setTransform:transform];

    } completion:nil];
  });
}

- (void)resetRotationOfElements {
  UIDeviceOrientation currentOrientation = [UIDevice currentDevice].orientation ;
  
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
      _captureOrientation = AVCaptureVideoOrientationLandscapeRight;
      break;
    case UIDeviceOrientationLandscapeRight:
      rotation = -M_PI_2;
      _captureOrientation = AVCaptureVideoOrientationLandscapeLeft;
      break;
  }
  CGAffineTransform transform = CGAffineTransformMakeRotation(rotation);
  [self.flipButton setTransform:transform];
  [self.flashButton setTransform:transform];
  [self.activityButton setTransform:transform];
  [recordButton setTransform:transform];


  
}


- (BOOL)prefersStatusBarHidden {
  return YES;
}


#pragma mark - NSNotifications

- (void)remoteNotificationReceived:(id)sender {
}

- (void)applicationDidBecomeActiveNotificationReceived:(id)sender {
  // Refresh fetch of feed and activity count when app is brought to foreground
  //[VYBUtility getNewActivityCountWithCompletion:nil];
}

- (void)applicationDidEnterBackgroundNotificationReceived:(id)sender {
  // stop recording
  
  // clear out all
}

- (void)activityCountChanged {
  
}

#pragma mark - Vybe Upload Progress

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if (context == XYZContext) {
    if ([keyPath isEqualToString:@"currentUploadPercent"]) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.uploadProgressView setProgress:[[change objectForKey:NSKeyValueChangeNewKey] intValue]/100.0];
      });
      return;
    }
    if ([keyPath isEqualToString:@"currentUploadStatus"]) {
      NSInteger status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
      if (status == CurrentUploadStatusUploading) {
        dispatch_async(dispatch_get_main_queue(), ^{
          self.activityButton.hidden = YES;
          self.uploadProgressView.hidden = NO;
          [self.uploadProgressView setProgress:0.0];
        });
        return;
      }
      if (status == CurrentUploadStatusSuccess) {
        dispatch_async(dispatch_get_main_queue(), ^{
          self.uploadProgressView.hidden = YES;
          self.activityButton.hidden = NO;
          [self.activityButton setSelected:NO];
        });
        return;
      }
      if (status == CurrentUploadStatusFailed) {
        dispatch_async(dispatch_get_main_queue(), ^{
          self.uploadProgressView.hidden = YES;
          self.activityButton.hidden = NO;
          [self.activityButton setSelected:YES];
        });
        return;
      }
    }
  }
  
  [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - ()


- (void)syncUIWithRecordingStatus {
  self.activityButton.hidden = _isRecording;
  flipButton.hidden = _isRecording;
  flashButton.hidden = _isRecording || _isFrontCamera;
}

- (IBAction)activityButtonPressed:(id)sender {
  SwipeContainerController *swipeContainer = (SwipeContainerController *)self.parentViewController;
  [swipeContainer moveToActivityScreen];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  NSLog(@"[Capture] Memory Warning");
}

@end
