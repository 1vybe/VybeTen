
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
#import "VYBCaptureButton.h"
#import "VYBActiveButton.h"
#import "VYBOldZoneFinder.h"
#import "VYBCameraView.h"
#import "VYBCache.h"
#import "VYBUtility.h"
#import "VYBMyVybeStore.h"
#import <GAI.h>
#import <GAITracker.h>
#import <GAIFields.h>
#import <GAIDictionaryBuilder.h>

@interface VYBCaptureViewController () <VYBCapturePipelineDelegate, UIAlertViewDelegate> {
    NSInteger _pageIndex;
}

@property (nonatomic, weak) IBOutlet UIButton *flipButton;
@property (nonatomic, weak) IBOutlet UIButton *flashButton;
@property (nonatomic, weak) IBOutlet VYBActiveButton *activityButton;
@property (nonatomic, weak) IBOutlet VYBCameraView *cameraView;
@property (nonatomic, weak) IBOutlet VYBCaptureButton *recordButton;

- (IBAction)activityButtonPressed:(id)sender;
- (IBAction)flipButtonPressed:(id)sender;
- (IBAction)flashButtonPressed:(id)sender;
- (IBAction)mapButtonPressed:(id)sender;
- (IBAction)checkButtonPressed:(id)sender;

//@property (nonatomic) VYBMyVybe *currVybe;
@property (nonatomic) VYBCapturePipeline *capturePipeline;

@end

@implementation VYBCaptureViewController {
    NSDate *startTime;
    NSTimer *_timeBomb;
    CMTime lastSampleTime;
    
    BOOL _flashOn;
    BOOL _isFrontCamera;
    BOOL _isRecording;
        
    AVCaptureVideoOrientation _captureOrientation;
    
    UIBackgroundTaskIdentifier _backgroundRecordingID;
    
    VYBOldZoneFinder *_oldZoneFinder;
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBFreshVybeFeedFetchedFromRemoteNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBUtilityActivityCountUpdatedNotification object:nil];
    
    NSLog(@"CaptureVC deallocated");
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(freshVybeCountChanged) name:VYBFreshVybeFeedFetchedFromRemoteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityCountChanged) name:VYBUtilityActivityCountUpdatedNotification object:nil];
    
    
    // In case capture screen is loaded AFTER initial loading from appdelegate is done already
    [self freshVybeCountChanged];
    [self activityCountChanged];
    
    // Device orientation detection
    [MotionOrientation initialize];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceRotated:)
                                                 name:MotionOrientationChangedNotification
                                               object:nil];
    
    [(AVCaptureVideoPreviewLayer *)[self.cameraView layer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    capturePipeline = [[VYBCapturePipeline alloc] init];
    [capturePipeline setDelegate:self callbackQueue:dispatch_get_main_queue()];
    
    [super viewDidLoad];
    
    // set images for two different states for our custom button
    [self.activityButton setNormalImage:[UIImage imageNamed:@"capture_flame_off.png"]
                         highlightImage:[UIImage imageNamed:@"capture_flame_off_highlight.png"]];
    [self.activityButton setActiveImage:[UIImage imageNamed:@"capture_flame_on.png"]
                         highlightImage:[UIImage imageNamed:@"capture_flame_on_highlight.png"]];
    [self.activityButton setActive:NO];
    
    UILongPressGestureRecognizer *holdGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(holdGestureReceived:)];
    holdGesture.minimumPressDuration = 0.3;
    [self.recordButton addGestureRecognizer:holdGesture];
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
    
    // Hide status bar
    [self setNeedsStatusBarAppearanceUpdate];
    
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName
                                       value:@"Capture Screen"];
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker
     send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // Show status bar
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)holdGestureReceived:(UIGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        if (!_isRecording) {
            [UIApplication sharedApplication].idleTimerDisabled = YES;
            
            if ( [[UIDevice currentDevice] isMultitaskingSupported] )
                _backgroundRecordingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];
            
            [[VYBMyVybeStore sharedStore] prepareNewVybe];
            
            [recordButton setUserInteractionEnabled:NO];
            
            [recordButton didStartRecording];
            
            [capturePipeline setRecordingOrientation:_captureOrientation];
            [capturePipeline startRecording];
            _isRecording = YES;
            [self syncUIWithRecordingStatus];
        }
    }
    else if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
        if (_isRecording) {
            [recordButton setUserInteractionEnabled:NO];
            [_timeBomb invalidate];
            [capturePipeline stopRecording];
        }
    }
}

- (void)recordingStopped {
    _isRecording = NO;
    [recordButton didStopRecording];
    [self syncUIWithRecordingStatus];
    [recordButton setUserInteractionEnabled:YES];

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
    [recordButton setUserInteractionEnabled:YES];
    _timeBomb = [NSTimer scheduledTimerWithTimeInterval:VYBE_LENGTH_SEC target:self selector:@selector(timer:) userInfo:nil repeats:NO];
}

- (void)capturePipelineRecordingWillStop:(VYBCapturePipeline *)pipeline {
    [recordButton setUserInteractionEnabled:NO];
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
    if (_isRecording) {
        [recordButton setUserInteractionEnabled:NO];
        _timeBomb = nil;
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
        [self.activityButton setTransform:transform];
        [recordButton setTransform:transform];
    } completion:nil];
}


- (BOOL)prefersStatusBarHidden {
    return YES;
}


#pragma mark - NSNotifications

- (void)remoteNotificationReceived:(id)sender {
}

- (void)applicationDidBecomeActiveNotificationReceived:(id)sender {    
    // Refresh fetch of feed and activity count when app is brought to foreground
    [VYBUtility fetchFreshVybeFeedWithCompletion:nil];
    //[VYBUtility getNewActivityCountWithCompletion:nil];
}

- (void)applicationDidEnterBackgroundNotificationReceived:(id)sender {
    // stop recording
    
    // clear out all
}

- (void)freshVybeCountChanged {
    NSInteger count = [[VYBCache sharedCache] freshVybes].count;
    [self.activityButton setActive:count];
}

- (void)activityCountChanged {

}

#pragma mark - Map

- (IBAction)mapButtonPressed:(id)sender {
    NSArray *freshVybes = [[VYBCache sharedCache] freshVybes];
    if (freshVybes && freshVybes.count > 0) {
        VYBMapViewController *mapVC = [[VYBMapViewController alloc] initWithNibName:@"VYBMapViewController" bundle:nil];
        [self presentViewController:mapVC animated:YES completion:^{
            [mapVC displayVybes:freshVybes];
        }];
    }
}

- (IBAction)checkButtonPressed:(id)sender {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
        if (!error) {
            _oldZoneFinder = [[VYBOldZoneFinder alloc] init];
            //_oldZoneFinder.numOfResults = 10;
            [_oldZoneFinder findZoneNearLocationInBackgroundWithLatitude:geoPoint.latitude longitude:geoPoint.longitude completionHandler:^(NSArray *results, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                });
                if (!error) {
                    [self displayCurrentZoneSuggestions:results];
                }
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            });
        }
    }];
}

- (void)displayCurrentZoneSuggestions:(NSArray *)suggestions {
    UIAlertController *checkInController = [UIAlertController alertControllerWithTitle:@"Check-in" message:@"Where are you vybing? :)" preferredStyle:UIAlertControllerStyleActionSheet];
    for (VYBZone *aZone in suggestions) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:aZone.name style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[VYBMyVybeStore sharedStore] setCurrZone:aZone];
            NSLog(@"You are in zone %@!", aZone.zoneID);
        }];
        [checkInController addAction:action];
    }
    if (checkInController.actions.count > 0) {
        VYBZone *currZone = [[VYBMyVybeStore sharedStore] currZone];
        if (currZone) {
            [checkInController setMessage:[NSString stringWithFormat:@"Your are in %@", currZone.name]];
        }
        
    } else {
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Unlock your zone" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            // choose a name/tag for zone.
        }];
        [checkInController addAction:action];
    }
    
    [self presentViewController:checkInController animated:YES completion:nil];
}

#pragma mark - ()


- (void)syncUIWithRecordingStatus {
    self.activityButton.hidden = _isRecording;
    flipButton.hidden = _isRecording;
    flashButton.hidden = _isRecording || _isFrontCamera;
}

- (IBAction)activityButtonPressed:(id)sender {
    VYBAppDelegate *appDel = (VYBAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDel moveToPage:VYBActivityPageIndex];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@"[Capture] Memory Warning");
}



@end
