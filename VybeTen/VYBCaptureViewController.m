
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

@interface VYBCaptureViewController () <VYBCapturePipelineDelegate, UIAlertViewDelegate, CLLocationManagerDelegate>

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

//@property (nonatomic) VYBMyVybe *currVybe;
@property (nonatomic) VYBCapturePipeline *capturePipeline;

@end

@implementation VYBCaptureViewController {
    NSDate *startTime;
    NSTimer *recordingTimer;
    CMTime lastSampleTime;
    
    BOOL _flashOn;
    BOOL _isFrontCamera;
    BOOL _isRecording;
        
    AVCaptureVideoOrientation _captureOrientation;
    
    UIBackgroundTaskIdentifier _backgroundRecordingID;
    
    CLLocationManager *_locationManager;
    BOOL _isLatestOS;
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
    
    [self checkPermissionSettings];
    
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
        
        [[VYBMyVybeStore sharedStore] prepareNewVybe];
        
        [recordButton setSelected:YES];
        [recordButton setEnabled:NO];
        
        [capturePipeline setRecordingOrientation:_captureOrientation];
        [capturePipeline startRecording];
        _isRecording = YES;
        [self syncUIWithRecordingStatus];
    } else {
        [recordButton setEnabled:NO];
        [recordButton setSelected:NO];
        [capturePipeline stopRecording];
    }
}

- (void)recordingStopped {
    _isRecording = NO;
    [self syncUIWithRecordingStatus];
    [recordButton setEnabled:YES];
    
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
    [NSTimer scheduledTimerWithTimeInterval:VYBE_LENGTH_SEC target:self selector:@selector(timer:) userInfo:nil repeats:NO];
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
    [capturePipeline setFlashOn:_flashOn];
}




#pragma mark - UIResponder

- (void)longPressDetected:(UILongPressGestureRecognizer *)recognizer {

}

- (void)timer:(NSTimer *)timer {
    if (_isRecording) {
        [recordButton setEnabled:NO];
        [capturePipeline stopRecording];
    }
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
        [recordButton setTransform:transform];
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
             
#pragma mark - Permissions

- (void)checkPermissionSettings {
    _locationManager = [[CLLocationManager alloc] init];
    _isLatestOS = [_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)];
    
    [self checkPermissionForAudioAccess];
}

- (void)checkPermissionForAudioAccess {
    NSString *title = [[NSString alloc] init];
    NSString *message = [[NSString alloc] init];
    
    // iOS7 and prior
    if ( !_isLatestOS) {
        NSString *audioPermission = [[NSUserDefaults standardUserDefaults] objectForKey:kVYBUserDefaultsAudioAccessPermissionKey];
        
        if ( [audioPermission isEqualToString:kVYBUserDefaultsAudioAccessPermissionDeniedKey] ) {
            title = @"Enable Audio Access";
            message = @"Please allow Vybe to access your location from Settings -> Privacy -> Microhpone";
        
            UIAlertView *mediaAlertView = [[UIAlertView alloc] initWithTitle:title
                                                                     message:message
                                                                    delegate:self
                                                           cancelButtonTitle:@"OK"
                                                           otherButtonTitles:nil];
            [mediaAlertView show];
        }
        else if ( [audioPermission isEqualToString:kVYBUserDefaultsAudioAccessPermissionUndeterminedKey] ) {
            UIAlertView *mediaAlertView = [[UIAlertView alloc] initWithTitle:title
                                                                     message:message
                                                                    delegate:self
                                                           cancelButtonTitle:@"Cancel"
                                                           otherButtonTitles:@"OK",nil];
            [mediaAlertView show];
        }
    }
    // iOS8 and later
    else {
        if ([[AVAudioSession sharedInstance] recordPermission] == AVAudioSessionRecordPermissionDenied) {
            title = @"Enable Audio Access";
            message = @"Please allow Vybe to access your location from Settings -> Privacy -> Microhpone";
        
            UIAlertController *mediaAlertController = [UIAlertController alertControllerWithTitle:title
                                                                                          message:message
                                                                                   preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                                 [self checkPermissionForVideoAccess];
                                                             }];
            [mediaAlertController addAction:okAction];
            [self presentViewController:mediaAlertController animated:NO completion:nil];
        }
        else if ([[AVAudioSession sharedInstance] recordPermission] == AVAudioSessionRecordPermissionUndetermined) {      title = @"Audio Access";
            message = @"We'd like to record what you hear when you are vybing";
            
            UIAlertController *mediaAlertController = [UIAlertController alertControllerWithTitle:title
                                                                                          message:message
                                                                                   preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *action) {
                                                                     [self checkPermissionForVideoAccess];
                                                                 }];
            [mediaAlertController addAction:cancelAction];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                                 [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                                                                     [self checkPermissionForVideoAccess];
                                                                 }];
                                                             }];
            [mediaAlertController addAction:okAction];
            [self presentViewController:mediaAlertController animated:NO completion:nil];
        }
    }
}

- (void)checkPermissionForVideoAccess {
    NSString *title = [[NSString alloc] init];
    NSString *message = [[NSString alloc] init];
    
    NSString *videoPermission = [[NSUserDefaults standardUserDefaults] objectForKey:kVYBUserDefaultsVideoAccessPermissionKey];
    // Video access denied
    if ( [videoPermission isEqualToString:kVYBUserDefaultsVideoAccessPermissionDeniedKey] ) {
        title = @"Enable Video Access";
        message = @"Please allow Vybe to access your location from Settings -> Privacy -> Camera";
        
        // iOS7 and prior
        if ( !_isLatestOS ) {

            
            UIAlertView *mediaAlertView = [[UIAlertView alloc] initWithTitle:title
                                                                     message:message
                                                                    delegate:self
                                                           cancelButtonTitle:@"OK"
                                                           otherButtonTitles:nil];
            [mediaAlertView show];
        }
        else {
            UIAlertController *mediaAlertController = [UIAlertController alertControllerWithTitle:title
                                                                                          message:message
                                                                                   preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                                 [self checkPermissionForLocationAccess];
                                                             }];
            [mediaAlertController addAction:okAction];
            [self presentViewController:mediaAlertController animated:NO completion:nil];

        }
    }
    else if ( [videoPermission isEqualToString:kVYBUserDefaultsVideoAccessPermissionUndeterminedKey] ) {
        title = @"Video Access";
        message = @"Vybe wants to access your camera to record your videos";
        
        // iOS7 and prior
        if ( !_isLatestOS ) {
            UIAlertView *mediaAlertView = [[UIAlertView alloc] initWithTitle:title
                                                                     message:message
                                                                    delegate:self
                                                           cancelButtonTitle:@"Cancel"
                                                           otherButtonTitles:@"OK",nil];
            [mediaAlertView show];
        }
        else {
            UIAlertController *mediaAlertController = [UIAlertController alertControllerWithTitle:title
                                                                                          message:message
                                                                                   preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                   style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction *action) {
                                                                     [self checkPermissionForLocationAccess];
                                                                 }];
            [mediaAlertController addAction:cancelAction];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                                 [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                                                                     [self checkPermissionForLocationAccess];
                                                                 }];
                                                             }];
            [mediaAlertController addAction:okAction];
            [self presentViewController:mediaAlertController animated:NO completion:nil];

        }
    }
}



- (void)checkPermissionForLocationAccess {
    if ( [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        // iOS7 and prior
        if ( !_isLatestOS ) {
            UIAlertView *locationAlertView = [[UIAlertView alloc] initWithTitle:@"Location Access"
                                                                        message:@"Allow access to your location so you know where you are vybing :)"
                                                                       delegate:self
                                                              cancelButtonTitle:@"Cancel"
                                                              otherButtonTitles:@"OK", nil];
            
            [locationAlertView show];
        } else {
            UIAlertController *locationAccessController = [UIAlertController alertControllerWithTitle:@"Location Access"
                                                                                              message:@"Allow access to your location so you know where you are vybing :)"
                                                                                       preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                   style:UIAlertActionStyleCancel
                                                                 handler:nil];
            UIAlertAction *okayAction = [UIAlertAction actionWithTitle:@"OK"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction *action) {
                [_locationManager requestAlwaysAuthorization];
            }];
            
            [locationAccessController addAction:cancelAction];
            [locationAccessController addAction:okayAction];
            
            [self presentViewController:locationAccessController animated:NO completion:nil];
        }
        
    } else if ( [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ) {
        if ( !_isLatestOS ) {
            UIAlertView *locationServiceAlert = [[UIAlertView alloc] initWithTitle:@"Enable Location Service"
                                                                           message:@"Please allow Vybe to access your location from Settings -> Privacy -> Location Services"
                                                                          delegate:self
                                                                 cancelButtonTitle:@"OK"
                                                                 otherButtonTitles:nil];
            [locationServiceAlert show];
        }
        else {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Enable Location Service"
                                                                                     message:@"Please allow Vybe to access your location from Settings -> Privacy -> Location Services" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel
                                                                handler:nil];
            [alertController addAction:alertAction];
            [self presentViewController:alertController animated:NO completion:nil];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ( [[alertView title] isEqualToString:@"Location Access"] ) {
        if ( [[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"OK"] ) {
            [_locationManager startUpdatingLocation];
        }
    }
    else if ( [[alertView title] isEqualToString:@"Audio Access"] ) {
        if ( [[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"OK"] ) {
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                [self checkPermissionForVideoAccess];
            }];
        } else {
            [self checkPermissionForVideoAccess];
        }
    }
    else if ( [[alertView title] isEqualToString:@"Video Access"] ) {
        if ( [[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"OK"] ) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                [self checkPermissionForLocationAccess];
            }];
        } else {
            [self checkPermissionForLocationAccess];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [_locationManager stopUpdatingLocation];
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
