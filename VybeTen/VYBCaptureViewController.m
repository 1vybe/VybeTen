
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
#import "VYBAppDelegate.h"
#import "VYBPlayerViewController.h"
#import "VYBCaptureViewController.h"
#import "VYBReplayViewController.h"
#import "VYBLabel.h"
#import "VYBMyVybeStore.h"
#import "VYBConstants.h"
#import "VYBCache.h"
#import "VYBUtility.h"


@implementation VYBCaptureViewController {
    NSInteger pageIndex;
    
    AVCaptureSession *session;
    AVCaptureDeviceInput *videoInput;
    AVCaptureMovieFileOutput *movieFileOutput;
    AVCaptureVideoPreviewLayer *cameraInputLayer;
    AVCaptureConnection *movieConnection;
    
    NSDate *startTime;
    NSTimer *recordingTimer;
    
    BOOL frontCamera;
    BOOL flashOn;
    
    VYBMyVybe *currVybe;
}

@synthesize flipButton, flashButton;

static void * XXContext = &XXContext;

- (void)dealloc {
    session = nil;
    movieFileOutput = nil;
    
    NSLog(@"CaptureVC deallocated");
}

+ (VYBCaptureViewController *)captureViewControllerForPageIndex:(NSInteger)idx {
    if (idx >= 0 && idx < 2) {
        return [[self alloc] initWithPageIndex:idx];
    }
    return nil;
}

- (id)init {
    self = [super init];
    if (self) {
        session = [[AVCaptureSession alloc] init];
        movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    }
    
    return self;
}

- (id)initWithPageIndex:(NSInteger)idx {
    self = [self init];
    if (self) {
        pageIndex = idx;
    }
    
    return self;
}

- (NSInteger)pageIndex {
    return pageIndex;
}


- (void)viewDidLoad
{
    //[super viewDidLoad];
    UIView *theView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view = theView;
    [self.view setBackgroundColor:[UIColor clearColor]];
    
#if DEBUG
    UISwipeGestureRecognizer *swipeUp=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeUp)];
    swipeUp.direction=UISwipeGestureRecognizerDirectionUp;
    [self.view addGestureRecognizer:swipeUp];
#endif
    
    // Hide status bar
    [self setNeedsStatusBarAppearanceUpdate];
    
    // Device orientation detection
    UIDevice *iphone = [UIDevice currentDevice];
    [iphone beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIDeviceOrientationDidChangeNotification object:iphone];
    
    // Adding CAPTURE button
    self.captureButton = [[VYBCaptureButton alloc] initWithFrame:CGRectMake(0, 0, 144, 144)];
    
    CGRect buttonFrame = CGRectMake(0, self.view.bounds.size.width - 70, 70, 70);
    self.viewButton = [[UIButton alloc] initWithFrame:buttonFrame];
    [self.viewButton setImage:[UIImage imageNamed:@"button_local_view.png"] forState:UIControlStateNormal];
    [self.viewButton addTarget:self action:@selector(viewButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.viewButton setContentMode:UIViewContentModeLeft];
    [self.view addSubview:self.viewButton];

    
    // Adding FLIP button
    buttonFrame = CGRectMake(self.view.bounds.size.height - 70, self.view.bounds.size.width - 70, 70, 70);
    flipButton = [[UIButton alloc] initWithFrame:buttonFrame];
    [flipButton setImage:[UIImage imageNamed:@"button_camera_front.png"] forState:UIControlStateNormal];
    [flipButton setImage:[UIImage imageNamed:@"button_camera_back.png"] forState:UIControlStateSelected];
    [flipButton setContentMode:UIViewContentModeCenter];
    [flipButton addTarget:self action:@selector(flipCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:flipButton];
    flipButton.selected = frontCamera;
    
    // Adding FLASH button
    buttonFrame = CGRectMake(self.view.bounds.size.height - 70, 0, 70, 70);
    flashButton = [[UIButton alloc] initWithFrame:buttonFrame];
    [flashButton setImage:[UIImage imageNamed:@"button_flash_on.png"] forState:UIControlStateNormal];
    [flashButton setImage:[UIImage imageNamed:@"button_flash_off.png"] forState:UIControlStateSelected];
    [flashButton setContentMode:UIViewContentModeLeft];
    [flashButton addTarget:self action:@selector(switchFlash:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:flashButton];
    flashButton.selected = flashOn;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [session stopRunning];
    [session removeInput:videoInput];
    [session removeOutput:movieFileOutput];
    [self turnOffFlash];
}



/**
 * Helper functions related to camera setup
 **/

- (void)setUpCameraSession {
    // Video input from a camera is playing in background
    // Setup for video capturing session
    [session setSessionPreset:AVCaptureSessionPresetMedium];
    [session startRunning];

    // Add video input from camera
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil];
    if ( [session canAddInput:videoInput] ) {
        [session addInput:videoInput];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Cannot load camera at the moment" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    // Setup preview layer
    cameraInputLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [cameraInputLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    // Display preview layer
    CALayer *rootLayer = [self.view layer];
    [rootLayer setMasksToBounds:YES];
    [cameraInputLayer setFrame:CGRectMake(0, 0, rootLayer.bounds.size.width, rootLayer.bounds.size.height)];
    [rootLayer insertSublayer:cameraInputLayer atIndex:0];
    // Add audio input from mic
    AVCaptureDevice *inputDeviceAudio = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *deviceAudioInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDeviceAudio error:nil];
    if ( [session canAddInput:deviceAudioInput] )
        [session addInput:deviceAudioInput];
    // Add movie file output
    /* Orientation must be set AFTER FileOutput is added to session */
    Float64 totalSeconds = VYBE_LENGTH_SEC;
    int32_t preferredTimeScale = 30;
    CMTime maxDuration = CMTimeMakeWithSeconds(totalSeconds, preferredTimeScale);
    movieFileOutput.maxRecordedDuration = maxDuration;
    movieFileOutput.minFreeDiskSpaceLimit = 1024 * 512;
    if ( [session canAddOutput:movieFileOutput] ) {
        [session addOutput:movieFileOutput];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Cannot record at the moment" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    movieConnection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setUpCameraSession];
    
    frontCamera = NO;
    flashOn = NO;
    flipButton.selected = frontCamera;
    flashButton.selected = flashOn;
    
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
    double secondsSinceStart = [[NSDate date] timeIntervalSinceDate:startTime];
    
    // less than 3.0 because of a delay in drawing. This guarantees user hold until red circle is full to pass the minimum
    if (secondsSinceStart >= 2.89) {
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
}

- (BOOL)hasTorch {
    return [[videoInput device] hasTorch];
}


- (void)switchFlash:(id)sender {
    flashOn = !flashOn;
    
    AVCaptureDevice *device = [videoInput device];
    [session beginConfiguration];
    [device lockForConfiguration:nil];
    
    // Switch flash on/off
    if ([device torchMode] == AVCaptureTorchModeOn) {
        [device setTorchMode:AVCaptureTorchModeOff];
        //flashButton.selected = YES;
    }
    else {
        [device setTorchMode:AVCaptureTorchModeOn];
        //flashButton.selected = NO;
    }
    
    flashButton.selected = flashOn;
    
    [device unlockForConfiguration];
    [session commitConfiguration];
}

- (void)turnOffFlash {
    AVCaptureDevice *device = [videoInput device];
    [session beginConfiguration];
    [device lockForConfiguration:nil];
    if ( [device isTorchModeSupported:AVCaptureTorchModeOff]) {
        [device setTorchMode:AVCaptureTorchModeOff];
        flashOn = NO;
        flashButton.selected = flashOn;
    }
    [device unlockForConfiguration];
    [session commitConfiguration];
    
}

- (void)flipCamera:(id)sender {
    [self turnOffFlash];
    [session stopRunning];
    [session removeInput:videoInput];
    [session startRunning];

    if (frontCamera) {
        videoInput = [self backCameraInput];
        flashButton.hidden = NO;
    } else {
        videoInput = [self frontCameraInput];
        flashButton.hidden = YES;
    }
    
    if ([session canAddInput:videoInput]) {
        [session addInput:videoInput];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Cannot load front camera at the moment" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
    frontCamera = !frontCamera;
    flipButton.selected = frontCamera;
    
    // Setting orientation of AVCaptureMovieFileOutput AFTER a video input is added back to session
    movieConnection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft) {
        [movieConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    } else if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight) {
        [movieConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
    }
    
}

#pragma mark - UIResponder

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view addSubview:self.captureButton];
    self.captureButton.center = [[touches anyObject] locationInView:self.view];
    [self.captureButton setNeedsDisplay];

    [self syncUIWithRecordingStatus:YES];
    [self startRecording];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
    CGPoint pt = [[touches anyObject] locationInView:self.view];
    self.captureButton.center = pt;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [movieFileOutput stopRecording];
    [self.captureButton removeFromSuperview];
    [self syncUIWithRecordingStatus:NO];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

- (void)startRecording {
    startTime = [NSDate date];
    currVybe = [[VYBMyVybe alloc] init];
    [currVybe setTimeStamp:startTime];
    
    [movieConnection setVideoMirrored:frontCamera];
    
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:[currVybe videoFilePath]];
    
    [movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
}


#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {

    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
        if (error || !geoPoint) {
            NSLog(@"Cannot retrive current location at this moment.");
        } else {
            [currVybe setGeoTagFrom:geoPoint];
        }
    }];

    recordingTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(timer:) userInfo:nil repeats:YES];
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    
    BOOL recordSuccess = YES;
    if ( [error code] != noErr ) {
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value)
            recordSuccess = [value boolValue];
    }
    
    if (recordSuccess) {
        NSDate *now = [NSDate date];
        double secondsSinceStart = [now timeIntervalSinceDate:startTime];

        if (secondsSinceStart >= 3.0) {
            VYBReplayViewController *replayVC = [[VYBReplayViewController alloc] init];
            [replayVC setCurrVybe:currVybe];
            [self.navigationController pushViewController:replayVC animated:NO];
        }
        else {
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:&error];
            if (error) {
                NSLog(@"Cached my vybe was NOT deleted");
            }
        }
    }
    
    startTime = nil;
    [recordingTimer invalidate];
    recordingTimer = nil;
    
    // If screen is switched to Player screen automatically by timer, remove capture button.
    if (self.captureButton.superview) {
        [self.captureButton removeFromSuperview];
    }
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

#pragma mark - ()

- (void)syncUIWithRecordingStatus:(BOOL)status {
    flipButton.hidden = status; flashButton.hidden = (status || frontCamera);
    [self.flipButton setNeedsDisplay];
    [self.flashButton setNeedsDisplay];
}

#if DEBUG
- (void)swipeUp {
    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];
    [self.navigationController pushViewController:playerVC animated:NO];
}
#endif

- (void)viewButtonPressed:(id)sender {
    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];
    [self.navigationController pushViewController:playerVC animated:NO];
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
