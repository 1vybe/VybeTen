
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
#import "VYBCaptureViewController.h"
#import "VYBHomeViewController.h"
#import "VYBReplayViewController.h"
#import "VYBSyncTribeViewController.h"
#import "VYBLabel.h"
#import "VYBMyVybeStore.h"
#import "VYBConstants.h"
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
    
    //UIImageView *overlayView;
}

@synthesize recordButton, countLabel, flipButton, flashButton, flashLabel;

static void * XXContext = &XXContext;

- (id)init {
    self = [super init];
    if (self) {
        session = [[AVCaptureSession alloc] init];
        movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    NSLog(@"CaptureVC deallocated");
}

- (void)viewDidLoad
{
    //[super viewDidLoad];
    UIView *theView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view = theView;
    [self.view setBackgroundColor:[UIColor clearColor]];
    
    // Hide status bar
    [self setNeedsStatusBarAppearanceUpdate];
    
    // Device orientation detection
    UIDevice *iphone = [UIDevice currentDevice];
    [iphone beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIDeviceOrientationDidChangeNotification object:iphone];

    recording = NO;
    frontCamera = NO;
    
    // Adding DISMISS button
    CGRect buttonFrame = CGRectMake(self.view.bounds.size.height - 60, 0, 50, 50);
   
    // Adding RECORD button
    buttonFrame = CGRectMake(self.view.bounds.size.height - 70, (self.view.bounds.size.width - 60)/2, 60, 60);
    recordButton = [[UIButton alloc] initWithFrame:buttonFrame];
    UIImage *captureButtonImg = [UIImage imageNamed:@"button_record.png"];
    [recordButton setBackgroundImage:captureButtonImg forState:UIControlStateNormal];
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
    
    // Adding FLIP button
    buttonFrame = CGRectMake((self.view.bounds.size.height - 120)/2, 0, 50, 50);
    flipButton = [[UIButton alloc] initWithFrame:buttonFrame];
    UIImage *flipImage = [UIImage imageNamed:@"button_switch_cam.png"];
    [flipButton setContentMode:UIViewContentModeCenter];
    [flipButton setImage:flipImage forState:UIControlStateNormal];
    [flipButton addTarget:self action:@selector(flipCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:flipButton];
    
    // Adding FLASH button
    buttonFrame = CGRectMake((self.view.bounds.size.height-120)/2 + 50, 0, 70, 50);
    flashButton = [[UIButton alloc] initWithFrame:buttonFrame];
    UIImage *flashImage = [UIImage imageNamed:@"button_flash.png"];
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
    
    [self setUpCameraSession];
    
    [session startRunning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self turnOffFlash];
}

- (void)viewWillAppear:(BOOL)animated {
     flipButton.hidden = recording; flashButton.hidden = (recording || frontCamera);
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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self adjustToOrientation:[[UIDevice currentDevice] orientation]];
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
        
        recording = YES; flipButton.hidden = recording; flashButton.hidden = recording;
    }
    
    /* Stop Recording */
    else {
        [movieFileOutput stopRecording];
    }
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

- (void)dismissButtonPressed:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
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
        
        [[VYBMyVybeStore sharedStore] addVybe:currVybe];
        [[VYBMyVybeStore sharedStore] uploadVybe:currVybe];
        
        if (self.delegate) {
            [self.delegate capturedVybe:[currVybe parseObjectVybe]];
        }
        [self.navigationController popToRootViewControllerAnimated:YES];
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


#pragma mark - DeviceOrientation

- (void)deviceOrientationChanged:(NSNotification *)note {
    UIDevice *device = [note object];
    [self adjustToOrientation:[device orientation]];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (void)adjustToOrientation:(UIDeviceOrientation)orientation {
    if (orientation == UIDeviceOrientationLandscapeLeft) {
        [[cameraInputLayer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        [movieConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    } else if (orientation == UIDeviceOrientationLandscapeRight) {
        [[cameraInputLayer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
        [movieConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
    }
    
    [self displayMessageToRotate:orientation];
}

- (void)displayMessageToRotate:(UIDeviceOrientation)orientation {
    /*
    if (overlayView) {
        [overlayView removeFromSuperview];
    }
    if (UIDeviceOrientationIsPortrait(orientation)) {
        overlayView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        [overlayView setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.8f]];
        [overlayView setUserInteractionEnabled:YES];
        [overlayView setContentMode:UIViewContentModeCenter];
        [overlayView setImage:[UIImage imageNamed:@"screen_warning_rotate.png"]];
        [self.view addSubview:overlayView];
    }
    */
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
