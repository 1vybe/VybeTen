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
#import "VYBLabel.h"
#import "VYBCaptureViewController.h"
#import "VYBMenuViewController.h"
#import "VYBMyVybeStore.h"
#import "VYBConstants.h"
#import "VYBReplayViewController.h"
#import "VYBSyncTribeViewController.h"
#import "UINavigationController+Fade.h"
#import "JSBadgeView.h"
#import "VYBCache.h"
#import "VYBUtility.h"

@implementation VYBCaptureViewController {
    AVCaptureSession *session;
    AVCaptureDeviceInput *videoInput;
    AVCaptureMovieFileOutput *movieFileOutput;
    AVCaptureVideoPreviewLayer *cameraInputLayer;
    AVCaptureConnection *movieConnection;
    
    NSDate *startTime;
    NSTimer *recordingTimer;
    
    BOOL recording;
    BOOL frontCamera;
    
    VYBMyVybe *currVybe;
    
    UIImageView *overlayView;
    JSBadgeView *badgeView;
    
    NSInteger _pageIndex;
}

@synthesize syncButton, syncLabel, recordButton, countLabel, flipButton, menuButton, flashButton, flashLabel, notificationButton;
@synthesize defaultSync;
@synthesize transitionController;

static void * XXContext = &XXContext;

+ (VYBCaptureViewController *)captureViewControllerForPageIndex:(NSInteger)pageIndex {
    if (pageIndex >= 0 && pageIndex < 2) {
        return [[self alloc] initWithPageIndex:pageIndex];
    }
    return nil;
}

- (id)initWithPageIndex:(NSInteger)pageIndex {
    self = [super init];
    if (self) {
        _pageIndex = pageIndex;
        session = [[AVCaptureSession alloc] init];
        movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        session = [[AVCaptureSession alloc] init];
        movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    }
    
    return self;
}

- (NSInteger)pageIndex {
    return _pageIndex;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBSyncViewControllerDidChangeSyncTribe object:nil];
}

- (void)viewDidLoad
{
    //[super viewDidLoad];
    UIView *theView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view = theView;
    [self.view setBackgroundColor:[UIColor clearColor]];
    
    [self setUpCameraSession];

    [session startRunning];

    
    // NSNotification for changing SYNC label
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeSyncTribeLabel:) name:VYBSyncViewControllerDidChangeSyncTribe object:nil];
    
    transitionController = [[TransitionDelegate alloc] init];
    

    recording = NO;
    frontCamera = NO;
    
    // Adding MENU button
    CGRect buttonFrame = CGRectMake(self.view.bounds.size.height - 50, 0, 50, 50);
    menuButton = [[UIButton alloc] initWithFrame:buttonFrame];
    UIImage *menuImage = [UIImage imageNamed:@"button_menu.png"];
    [menuButton setContentMode:UIViewContentModeCenter];
    [menuButton setImage:menuImage forState:UIControlStateNormal];
    [menuButton addTarget:self action:@selector(goToMenu:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:menuButton];
    
    // Adding SYNC button
    buttonFrame = CGRectMake(0, self.view.bounds.size.width - 50, 50, 50);
    syncButton = [[UIButton alloc] initWithFrame:buttonFrame];
    UIImage *syncNoneImg = [UIImage imageNamed:@"button_sync_none.png"];
    UIImage *syncImg = [UIImage imageNamed:@"button_sync.png"];
    [syncButton setImage:syncNoneImg forState:UIControlStateNormal];
    [syncButton setImage:syncImg forState:UIControlStateSelected];
    [syncButton setContentMode:UIViewContentModeLeft];
    [syncButton addTarget:self action:@selector(changeSync:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:syncButton];
    
    // Adding SYNC label
    buttonFrame = CGRectMake(50, self.view.bounds.size.width - 50, 150, 50);
    syncLabel = [[VYBLabel alloc] initWithFrame:buttonFrame];
    [syncLabel setTextColor:[UIColor whiteColor]];
    [syncLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20]];
    //[syncLabel setTextAlignment:NSTextAlignmentLeft];
    [syncLabel resignFirstResponder];
    [self.view addSubview:syncLabel];
    PFObject *tribe = [[VYBCache sharedCache] syncTribeForUser:[PFUser currentUser]];
    if (tribe) {
        [syncLabel setText:tribe[kVYBTribeNameKey]];
        [syncButton setSelected:YES];
    } else {
        [syncLabel setText:@"(select)"];
        [syncButton setSelected:NO];
    }
    
    // Adding RECORD button
    buttonFrame = CGRectMake(self.view.bounds.size.height - 70, (self.view.bounds.size.width - 60)/2, 60, 60);
    recordButton = [[UIButton alloc] initWithFrame:buttonFrame];
    UIImage *captureButtonImg = [UIImage imageNamed:@"button_record.png"];
    [recordButton setBackgroundImage:captureButtonImg forState:UIControlStateNormal];
    //[recordButton.titleLabel setFont:[UIFont fontWithName:@"Montreal-Regular" size:24]];
    //[recordButton setTintColor:[UIColor whiteColor]];
    [recordButton addTarget:self action:@selector(startRecording) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:recordButton];
    // Adding COUNT label to RECORD button
    buttonFrame = CGRectMake(0, 0, 60, 60);
    countLabel = [[VYBLabel alloc] initWithFrame:buttonFrame];
    [countLabel setTextColor:[UIColor whiteColor]];
    [countLabel setTextAlignment:NSTextAlignmentCenter];
    [countLabel setFont:[UIFont fontWithName:@"Montreal-Regular" size:24.0f]];
    [countLabel setUserInteractionEnabled:NO];
    [recordButton addSubview:countLabel];
    
    // Adding NOTIFICATION button
    buttonFrame = CGRectMake(0, 0, 50, 50);
    notificationButton = [[UIButton alloc] initWithFrame:buttonFrame];
    UIImageView *notificationImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"button_notification.png"]];
    [notificationButton addSubview:notificationImgView];
    notificationImgView.center = notificationButton.center;
    [notificationButton addTarget:self action:@selector(notificationPressed:) forControlEvents:UIControlEventTouchUpInside];
    /* TODO: Uncomment this */
    //[self.view addSubview:notificationButton];
    [notificationImgView setUserInteractionEnabled:NO];
    badgeView = [[JSBadgeView alloc] initWithParentView:notificationImgView alignment:JSBadgeViewAlignmentTopRight];
    // Register this class as an observer for notification change
    [[VYBMyVybeStore sharedStore] addObserver:self forKeyPath:@"numVybes" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:XXContext];
    //adgeView.badgeText = @"3";
    
    // Adding FLIP button
    buttonFrame = CGRectMake((self.view.bounds.size.height - 120)/2, 0, 50, 50);
    flipButton = [[UIButton alloc] initWithFrame:buttonFrame];
    UIImage *flipImage = [UIImage imageNamed:@"button_flip.png"];
    [flipButton setContentMode:UIViewContentModeCenter];
    [flipButton setImage:flipImage forState:UIControlStateNormal];
    [flipButton addTarget:self action:@selector(flipCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:flipButton];
    
    // Adding FLASH button
    buttonFrame = CGRectMake((self.view.bounds.size.height-120)/2 + 50, 0, 70, 50);
    flashButton = [[UIButton alloc] initWithFrame:buttonFrame];
    UIImage *flashImage = [UIImage imageNamed:@"button_flash_on.png"];
    [flashButton setContentMode:UIViewContentModeLeft];
    [flashButton setImage:flashImage forState:UIControlStateNormal];
    [flashButton addTarget:self action:@selector(switchFlash:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:flashButton];
    
    // Adding FLASH label
    buttonFrame = CGRectMake(40, 0, 30, 50);
    flashLabel = [[VYBLabel alloc] initWithFrame:buttonFrame];
    [flashLabel setFont:[UIFont fontWithName:@"Montreal-Regular" size:14]];
    [flashLabel setTextAlignment:NSTextAlignmentLeft];
    [flashLabel setTextColor:[UIColor whiteColor]];
    [flashLabel setText:@"OFF"];
    [self.flashButton addSubview:flashLabel];

    //self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [self turnOffFlash];
}

- (void)viewWillAppear:(BOOL)animated {
     syncButton.hidden = recording; syncLabel.hidden = recording; flipButton.hidden = recording; menuButton.hidden = recording; notificationButton.hidden = recording; flashButton.hidden = (recording || frontCamera);
}

- (void)changeSyncTribeLabel:(NSNotificationCenter *)note {
    [syncButton setSelected:YES];
    NSString *newTribeName = [[[VYBCache sharedCache] syncTribeForUser:[PFUser currentUser]] objectForKey:kVYBTribeNameKey];
    [syncLabel setText:newTribeName];
}

/**
 * Helper functions related to camera setup
 **/

- (void)setUpCameraSession {
    // Video input from a camera is playing in background
    // Setup for video capturing session
    [session setSessionPreset:AVCaptureSessionPresetMedium];
    // Add video input from camera
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil];
    if ( [session canAddInput:videoInput] )
        [session addInput:videoInput];
    // Setup preview layer
    cameraInputLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [cameraInputLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    // Display preview layer
    CALayer *rootLayer = [self.view layer];
    [rootLayer setMasksToBounds:YES];
    [cameraInputLayer setFrame:CGRectMake(0, 0, rootLayer.bounds.size.height, rootLayer.bounds.size.width)]; // width and height are switched in landscape mode
    [rootLayer insertSublayer:cameraInputLayer atIndex:0];
    // Add audio input from mic
    AVCaptureDevice *inputDeviceAudio = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *deviceAudioInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDeviceAudio error:nil];
    if ( [session canAddInput:deviceAudioInput] )
        [session addInput:deviceAudioInput];
    // Add movie file output
    /* Orientation must be set AFTER FileOutput is added to session */
    Float64 totalSeconds = 7;
    int32_t preferredTimeScale = 30;
    CMTime maxDuration = CMTimeMakeWithSeconds(totalSeconds, preferredTimeScale);
    movieFileOutput.maxRecordedDuration = maxDuration;
    movieFileOutput.minFreeDiskSpaceLimit = 1024 * 512;
    if ( [session canAddOutput:movieFileOutput] )
        [session addOutput:movieFileOutput];
    movieConnection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft) {
        [[cameraInputLayer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        [movieConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    } else if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight) {
        [[cameraInputLayer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
        [movieConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
    }

}

- (AVCaptureDeviceInput *)frontCameraInput {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionFront) {
            AVCaptureDeviceInput *frontVideoInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
            return frontVideoInput;
        }
    }
    return nil;
}

- (AVCaptureDeviceInput *)backCameraInput {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) {
            AVCaptureDeviceInput *backVideoInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
            return backVideoInput;
        }
    }
    return nil;
}

- (void)timer:(NSTimer *)timer {
    NSInteger secondsSinceStart = (NSInteger)[[NSDate date] timeIntervalSinceDate:startTime];
    int secondsLeft = 7 - (int)secondsSinceStart;
    NSString *secondsPassed = [NSString stringWithFormat:@"%d", secondsLeft];
    [countLabel setText:secondsPassed];
}

- (BOOL)hasTorch {
    return [[videoInput device] hasTorch];
}

/**
 * Actions that are triggered by buttons 
 **/

- (void)startRecording {
    /* Start Recording */
    if (!recording) {
        startTime = [NSDate date];

        currVybe = [[VYBMyVybe alloc] init];
        [currVybe setTimeStamp:startTime];
        
        [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
            if (error || !geoPoint) {
                NSLog(@"Cannot retrive current location at this moment.");
            } else {
                [currVybe setGeoTagFrom:geoPoint];
            }
        }];

        [movieConnection setVideoMirrored:frontCamera];
        
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:[currVybe videoFilePath]];
        [movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
        
        recordingTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timer:) userInfo:nil repeats:YES];
        // Change record button to act as a counter
        UIImage *recordButtonEmptyImg = [UIImage imageNamed:@"button_record_empty.png"];
        [recordButton setBackgroundImage:recordButtonEmptyImg forState:UIControlStateNormal];
        
        recording = YES; syncButton.hidden = recording; syncLabel.hidden = recording; flipButton.hidden = recording; menuButton.hidden = recording; notificationButton.hidden = recording; flashButton.hidden = recording;
    }
    
    /* Stop Recording */
    else {
        [movieFileOutput stopRecording];
    }
}

- (void)notificationPressed:(id)sender {
    NSLog(@"NOTI PRESED");
}

- (void)changeSync:(id)sender {
    VYBSyncTribeViewController *syncVC = [[VYBSyncTribeViewController alloc] init];
    [self presentViewController:syncVC animated:NO completion:nil];
}

- (void)switchFlash:(id)sender {
    AVCaptureDevice *device = [videoInput device];
    [session beginConfiguration];
    [device lockForConfiguration:nil];
    
    // Switch flash on/off
    if ([device torchMode] == AVCaptureTorchModeOn) {
        [device setTorchMode:AVCaptureTorchModeOff];
        [self.flashLabel setText:@"OFF"];
    }
    else {
        [device setTorchMode:AVCaptureTorchModeOn];
        [self.flashLabel setText:@"ON"];
    }
    
    [device unlockForConfiguration];
    [session commitConfiguration];
}

- (void)turnOffFlash {
    AVCaptureDevice *device = [videoInput device];
    [session beginConfiguration];
    [device lockForConfiguration:nil];
    if ( [device isTorchModeSupported:AVCaptureTorchModeOff]) {
        [device setTorchMode:AVCaptureTorchModeOff];
        [self.flashLabel setText:@"OFF"];
    }
    [device unlockForConfiguration];
    [session commitConfiguration];
}

- (void)flipCamera:(id)sender {
    [self turnOffFlash];
    [session stopRunning];
    [session removeInput:videoInput];
    if (frontCamera) {
        videoInput = [self backCameraInput];
        flashButton.hidden = NO;
    } else {
        videoInput = [self frontCameraInput];
        flashButton.hidden = YES;
    }
    
    [session addInput:videoInput];
    frontCamera = !frontCamera;
    
    // Setting orientation of AVCaptureMovieFileOutput AFTER a video input is added back to session
    movieConnection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft) {
        [movieConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    } else if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight) {
        [movieConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
    }
    
    [session startRunning];
}

- (void)goToMenu:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}



#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    BOOL recordSuccess = YES;
    if ( [error code] != noErr ) {
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value)
            recordSuccess = [value boolValue];
    }
    
    if (recordSuccess) {
        // Saves a thumbmnail to local
        [VYBUtility saveThumbnailImageForVybeWithFilePath:currVybe.uniqueFileName];
        
        // Prompt a review screen to save it or not
        VYBReplayViewController *replayVC = [[VYBReplayViewController alloc] init];
        [replayVC setCurrVybe:currVybe];
        [self presentViewController:replayVC animated:NO completion:nil];
    }

    startTime = nil;
    [recordingTimer invalidate];
    recordingTimer = nil;
    // Reset record button image back to original
    [countLabel setText:@""];
    UIImage *recordButtonImg = [UIImage imageNamed:@"button_record.png"];
    [recordButton setBackgroundImage:recordButtonImg forState:UIControlStateNormal];
    [recordButton setTitle:@"" forState:UIControlStateNormal];
    
    recording = NO;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == XXContext) {
        if ( [keyPath isEqualToString:@"numVybes"] ) {
            NSNumber *newCount = (NSNumber *)[change objectForKey:NSKeyValueChangeNewKey];
            NSString *count = [NSString stringWithFormat:@"%@", newCount];
            badgeView.badgeText = count;
        }
    }
    //[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
