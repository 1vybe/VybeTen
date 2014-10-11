
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
#import "VYBAppDelegate.h"
#import "VYBCapturePipeline.h"
#import "VYBCaptureViewController.h"
#import "VYBReplayViewController.h"
#import "VYBCameraView.h"
#import "VYBCache.h"
#import "VYBUtility.h"
#import "VYBMyVybeStore.h"
#import <GAI.h>
#import <GAITracker.h>
#import <GAIFields.h>
#import <GAIDictionaryBuilder.h>

@interface VYBCaptureViewController () <VYBCapturePipelineDelegate, CLLocationManagerDelegate> 

@property (nonatomic, weak) IBOutlet UIButton *flipButton;
@property (nonatomic, weak) IBOutlet UIButton *flashButton;
@property (nonatomic, weak) IBOutlet UIButton *hubButton;
@property (nonatomic, weak) IBOutlet UIButton *activityButton;
@property (nonatomic, weak) IBOutlet VYBCameraView *cameraView;
@property (nonatomic, weak) IBOutlet UIButton *recordButton;

- (IBAction)hubButtonPressed:(id)sender;
- (IBAction)activityButtonPressed:(id)sender;
- (IBAction)flipButtonPressed:(id)sender;
- (IBAction)flashButtonPressed:(id)sender;
- (IBAction)recordButtonPressed:(id)sender;

@property (nonatomic) VYBMyVybe *currVybe;
@property (nonatomic) VYBCapturePipeline *capturePipeline;

@end

@implementation VYBCaptureViewController {
    NSDate *startTime;
    NSTimer *recordingTimer;
    CMTime lastSampleTime;
    
    BOOL _flashOn;
    BOOL _isFrontCamera;
    BOOL _isRecording;
    
    CLLocationManager *locationManager;
    
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBCacheFreshVybeCountChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBFreshVybeFeedFetchedFromRemoteNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBUtilityActivityCountUpdatedNotification object:nil];
    
    NSLog(@"CaptureVC deallocated");
}

- (id)init {
    self = [super init];
    if (self) {
        _isRecording = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    _captureOrientation = AVCaptureVideoOrientationPortrait;
    
    if ([CLLocationManager locationServicesEnabled]) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy=kCLLocationAccuracyBest;
    }
    
    // Subscribing to Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteNotificationReceived:) name:VYBAppDelegateApplicationDidReceiveRemoteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActiveNotificationReceived:) name:VYBAppDelegateApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackgroundNotificationReceived:) name:VYBAppDelegateApplicationDidEnterBackgourndNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(freshVybeCountChanged) name:VYBCacheFreshVybeCountChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(freshVybeCountChanged) name:VYBFreshVybeFeedFetchedFromRemoteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityCountChanged) name:VYBUtilityActivityCountUpdatedNotification object:nil];
    
    
    // In case capture screen is loaded AFTER initial loading from appdelegate is done already
    [self freshVybeCountChanged];
    [self activityCountChanged];
    
    
    // Hide status bar
    [self setNeedsStatusBarAppearanceUpdate];
    
    // Device orientation detection
    [MotionOrientation initialize];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceRotated:)
                                                 name:MotionOrientationChangedNotification
                                               object:nil];
    
    [(AVCaptureVideoPreviewLayer *)[self.cameraView layer] setVideoGravity:AVLayerVideoGravityResizeAspect];
    
    capturePipeline = [[VYBCapturePipeline alloc] init];
    [capturePipeline setDelegate:self callbackQueue:dispatch_get_main_queue()];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [capturePipeline startRunning];
    
    flashButton.selected = _flashOn;
    flipButton.selected = _isFrontCamera;
    
    // Google Analytics
    self.screenName = @"Capture Screen";
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName
                                       value:@"Capture Screen"];
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker
     send:[[GAIDictionaryBuilder createAppView] build]];
}

- (IBAction)recordButtonPressed:(id)sender {
    if (!_isRecording) {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        
        if ( [[UIDevice currentDevice] isMultitaskingSupported] )
            _backgroundRecordingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];
        
        [recordButton setEnabled:NO];
        [recordButton setTitle:@"Stop" forState:UIControlStateNormal];
        
        self.currVybe = [[VYBMyVybe alloc] init];
        [self.currVybe setTimeStamp:[NSDate date]];
        [[VYBMyVybeStore sharedStore] setCurrVybe:self.currVybe];
        [capturePipeline setRecordingOrientation:_captureOrientation];
        [capturePipeline startRecording];
        _isRecording = YES;
        [self syncUIWithRecordingStatus];
    } else {
        [capturePipeline stopRecording];
    }
}

- (void)recordingStopped {
    _isRecording = NO;
    [self syncUIWithRecordingStatus];
    [recordButton setEnabled:YES];
    [recordButton setTitle:@"Record" forState:UIControlStateNormal];
    
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    [[UIApplication sharedApplication] endBackgroundTask:_backgroundRecordingID];
    _backgroundRecordingID = UIBackgroundTaskInvalid;
    
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
    [[self hubButton] setEnabled:NO];
    
    [capturePipeline flipCameraWithCompletion:^(AVCaptureDevicePosition cameraPosition){
        dispatch_async(dispatch_get_main_queue(), ^{
            _isFrontCamera = (cameraPosition == AVCaptureDevicePositionFront);
            [[self flipButton] setSelected:_isFrontCamera];
            [[self flipButton] setEnabled:YES];
            [[self flashButton] setEnabled:YES];
            [[self flashButton] setHidden:_isFrontCamera];
            [[self activityButton] setEnabled:YES];
            [[self hubButton] setEnabled:YES];
        });
    }];
}


- (IBAction)flashButtonPressed:(id)sender {
    _flashOn = !_flashOn;
    flashButton.selected = _flashOn;
}


+ (void)setTorchMode:(AVCaptureTorchMode)torchMode forDevice:(AVCaptureDevice *)device
{
	if ([device hasTorch] && [device isTorchModeSupported:torchMode])
	{
		NSError *error = nil;
		if ([device lockForConfiguration:&error])
		{
            [device setTorchMode:torchMode];
			[device unlockForConfiguration];
		}
		else
		{
			NSLog(@"%@", error);
		}
	}
}


#pragma mark - UIResponder

- (void)longPressDetected:(UILongPressGestureRecognizer *)recognizer {
    /*
    if (!_isRecording) {
        [self.view addSubview:self.captureButton];
        self.captureButton.center = [recognizer locationInView:self.view];

        double rotation = 0;
        switch (lastOrientation) {
            case AVCaptureVideoOrientationPortrait:
                rotation = 0;
                break;
            case AVCaptureVideoOrientationPortraitUpsideDown:
                rotation = -M_PI;
                break;
            case AVCaptureVideoOrientationLandscapeLeft:
                rotation = -M_PI_2;
                break;
            case AVCaptureVideoOrientationLandscapeRight:
                rotation = M_PI_2;
                break;
            default:
                return;
        }
        
        CGAffineTransform transform = CGAffineTransformMakeRotation(rotation);
        self.captureButton.transform = transform;
        
        [self startRecording];
    }
    
    if ([recognizer state] == UIGestureRecognizerStateChanged) {
        CGPoint pt = [recognizer locationInView:self.view];
        self.captureButton.center = pt;
    }
    
    if (([recognizer state] == UIGestureRecognizerStateEnded) || ([recognizer state] == UIGestureRecognizerStateCancelled)) {
        [self.captureButton removeFromSuperview];

        if (isRecording) {
            isRecording = NO;
            [self syncUIWithRecordingStatus:NO];
            if (_videoWriter.status == AVAssetWriterStatusWriting) {
                [_videoWriterInput markAsFinished];
                [_audioWriterInput markAsFinished];
                [_videoWriter finishWritingWithCompletionHandler:^{
                    _videoWriterInput = nil;
                    _videoWriter = nil;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self stopRecording];
                    });
                }];
            }
        }
    }
    */
}
/*
- (void)startRecording {
    
    isRecording = YES;
    [self syncUIWithRecordingStatus:YES];

    startTime = [NSDate date];
    self.currVybe = [[VYBMyVybe alloc] init];
    [self.currVybe setTimeStamp:startTime];
    
    [locationManager startUpdatingLocation];
    
    if (recordingTimer) {
        [recordingTimer invalidate];
        recordingTimer = nil;
    }
    
    recordingTimer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(timer:) userInfo:nil repeats:YES];
    
    if (![self setUpAssetWriter]) {
        NSLog(@"setupAssetWriter FAILED :(");
        return;
    }
    
    dispatch_async([self sessionQueue], ^{
        if ([[UIDevice currentDevice] isMultitaskingSupported])
        {
            // Setup background task. This is needed because the captureOutput:didFinishRecordingToOutputFileAtURL: callback is not received until AVCam returns to the foreground unless you request background execution time. This also ensures that there will be time to write the file to the assets library when AVCam is backgrounded. To conclude this background execution, -endBackgroundTask is called in -recorder:recordingDidFinishToOutputFileURL:error: after the recorded file has been saved.
            [self setBackgroundRecordingID:[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil]];
        }
     
        // Turning flash for video recording
        if (flashOn) {
            [VYBCaptureViewController setTorchMode:AVCaptureTorchModeOn forDevice:[[self videoInput] device]];
        }
        
    });
 
}
*/
- (void)timer:(NSTimer *)timer {
    /*
    double secondsSinceStart = [[NSDate date] timeIntervalSinceDate:startTime];
    // less than 3.0 because of a delay in drawing. This guarantees user hold until red circle is full to pass the minimum
    if (secondsSinceStart >= VYBE_LENGTH_SEC) {
        [self.captureButton removeFromSuperview];
        isRecording = NO;
        [self syncUIWithRecordingStatus:NO];
        if (_videoWriter.status == AVAssetWriterStatusWriting) {
            [_videoWriterInput markAsFinished];
            [_audioWriterInput markAsFinished];
            [_videoWriter finishWritingWithCompletionHandler:^{
                _videoWriterInput = nil;
                _videoWriter = nil;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self stopRecording];
                });
            }];
        }
    }
    else if (secondsSinceStart >= 2.89) {
        if (!self.captureButton.passedMin) {
            self.captureButton.passedMin = YES;
        }
        double maxPercent = (secondsSinceStart - 2.89) / (VYBE_LENGTH_SEC - 2.89);
        [self.captureButton setMaxPercentage:maxPercent];
    } else {
        double minPercent = secondsSinceStart / 2.89;
        [self.captureButton setMinPercentage:minPercent];
    }
    [self.captureButton setNeedsDisplay];
    */
}

- (void)stopRecording {
    /*
    NSDate *now = [NSDate date];
    double secondsSinceStart = [now timeIntervalSinceDate:startTime];
    
    if (secondsSinceStart >= 3.0) {
        VYBReplayViewController *replayVC = [[VYBReplayViewController alloc] initWithNibName:@"VYBReplayViewController" bundle:nil];
        [replayVC setCurrVybe:self.currVybe];
        [self presentViewController:replayVC animated:NO completion:nil];
    }
    else {
        NSError *error;
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:[self.currVybe videoFilePath]];
        [[NSFileManager defaultManager] removeItemAtURL:outputURL  error:&error];
        if (error) {
            NSLog(@"Failed to delete a vybe under 3 seconds");
        }
    }

    startTime = nil;
    [recordingTimer invalidate];
    recordingTimer = nil;
    
    [VYBCaptureViewController setTorchMode:AVCaptureTorchModeOff forDevice:[[self videoInput] device]];
    */
}


#pragma mark - CLLocationManagerDelegate 

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Failed to get current location");
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *currLocation = [locations lastObject];
    CLGeocoder *reverseGeocoder = [[CLGeocoder alloc] init];

    [self.currVybe setGeoTag:currLocation];

    [reverseGeocoder reverseGeocodeLocation:currLocation completionHandler:^(NSArray *placemarks, NSError *error)
     {
         CLPlacemark *myPlacemark = [placemarks objectAtIndex:0];
         NSString *neighborhood = myPlacemark.subLocality;
         NSString *city = myPlacemark.locality;
         NSString *isoCountryCode = myPlacemark.ISOcountryCode;
         NSString *locationStr = [NSString stringWithFormat:@"%@,%@,%@",neighborhood, city, isoCountryCode];
         [self.currVybe setLocationString:locationStr];
         [[PFUser currentUser] setObject:locationStr forKey:kVYBUserLastVybedLocationKey];
     }];
    
    [locationManager stopUpdatingLocation];
}

#pragma mark - DeviceOrientation

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (void)deviceRotated:(NSNotification *)notification {
    UIDeviceOrientation currentOrientation = [MotionOrientation sharedInstance].deviceOrientation;

    double rotation = 0;
    switch (currentOrientation) {
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationUnknown:
            return;
        case UIDeviceOrientationPortrait:
            rotation = 0;
            _captureOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            rotation = -M_PI;
            _captureOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIDeviceOrientationLandscapeLeft:
            rotation = M_PI_2;
            _captureOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight:
            _captureOrientation = AVCaptureVideoOrientationLandscapeLeft;
            rotation = -M_PI_2;
            break;
    }
    
    CGAffineTransform transform = CGAffineTransformMakeRotation(rotation);
    [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.flipButton setTransform:transform];
        [self.flashButton setTransform:transform];
        [self.hubButton setTransform:transform];
        [self.activityButton setTransform:transform];
    } completion:nil];
}


- (BOOL)prefersStatusBarHidden {
    return YES;
}


#pragma mark - NSNotifications

- (void)remoteNotificationReceived:(id)sender {
    [VYBUtility getNewActivityCountWithCompletion:nil];
}

- (void)applicationDidBecomeActiveNotificationReceived:(id)sender {    
    // Refresh fetch of feed and activity count when app is brought to foreground
    [VYBUtility fetchFreshVybeFeedWithCompletion:nil];
    [VYBUtility getNewActivityCountWithCompletion:nil];
}

- (void)applicationDidEnterBackgroundNotificationReceived:(id)sender {
    // stop recording
    
    // clear out all
}

- (void)freshVybeCountChanged {
    NSInteger count = [[[VYBCache sharedCache] freshVybes] count];
    self.hubButton.selected = !count;
    if (count)
        [self.hubButton setTitle:[NSString stringWithFormat:@"%ld", (long)count] forState:UIControlStateNormal];
    else
        [self.hubButton setTitle:@"" forState:UIControlStateNormal];

}

- (void)activityCountChanged {
    NSInteger count = [[VYBCache sharedCache] activityCount];
    self.activityButton.selected = !count;
    if (count)
        [self.activityButton setTitle:[NSString stringWithFormat:@"%ld", (long)count] forState:UIControlStateNormal];
    else
        [self.activityButton setTitle:@"" forState:UIControlStateNormal];
}


#pragma mark - ()

- (void)syncUIWithRecordingStatus {
    self.activityButton.hidden = _isRecording;
    self.hubButton.hidden = _isRecording;
    flipButton.hidden = _isRecording;
    flashButton.hidden = _isRecording || _isFrontCamera;
}

- (IBAction)activityButtonPressed:(id)sender {
    VYBAppDelegate *appDel = (VYBAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDel moveToPage:VYBActivityPageIndex];
}

- (IBAction)hubButtonPressed:(id)sender {
    VYBAppDelegate *appDel = (VYBAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDel moveToPage:VYBHubPageIndex];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@"[Capture] Memory Warning");
}



@end
