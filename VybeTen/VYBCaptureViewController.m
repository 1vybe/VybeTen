//
//  VYBCaptureViewController.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 21..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import "VYBCaptureViewController.h"
#import "VYBMenuViewController.h"
#import "VYBMyVybeStore.h"
#import "VYBConstants.h"
#import "VYBReplayViewController.h"
#import "VYBCaptureProgressView.h"
#import "VYBMainNavigationController.h"

@implementation VYBCaptureViewController {
    AVCaptureSession *session;
    AVCaptureDeviceInput *videoInput;
    AVCaptureMovieFileOutput *movieFileOutput;
   
    NSDate *startTime;
    NSTimer *recordingTimer;
    
    VYBVybe *newVybe;
    
    BOOL recording;
    BOOL frontCamera;
    
    UIView *overlayView;
}
@synthesize labelTimer, buttonFlip, buttonMenu, buttonFlash, flashLabel;

/*
// Fix orientation to landscapeRight
- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}
*/
- (void)loadView {
    // Retrieves this device's unique ID
    adId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    NSLog(@"UserID:%@", adId);
    //NSLog(@"%@", NSStringFromCGRect([[UIScreen mainScreen] bounds]));
    UIView *theView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view = theView;
}

- (void)setSession:(AVCaptureSession *)s withVideoInput:(AVCaptureDeviceInput *)vidInput withMovieFileOutput:(AVCaptureMovieFileOutput *)movieOutput{
    session = s;
    videoInput = vidInput;
    movieFileOutput = movieOutput;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Overlay alertView will be displayed when a user entered in a portrait mode
    //UIDevice *iphone = [UIDevice currentDevice];
    //[iphone beginGeneratingDeviceOrientationNotifications];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayOverlay:) name:UIDeviceOrientationDidChangeNotification object:iphone];
    
    recording = NO;
    frontCamera = NO;

    // Adding swipe gestures
    UITapGestureRecognizer * tapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(startRecording)];
    [self.view addGestureRecognizer:tapGesture];
    
    // Adding MENU button
    CGRect buttonMenuFrame = CGRectMake(self.view.bounds.size.height - 50, self.view.bounds.size.width - 50, 50, 50);    buttonMenu = [[UIButton alloc] initWithFrame:buttonMenuFrame];
    UIImage *menuImage = [UIImage imageNamed:@"button_menu.png"];
    [buttonMenu setContentMode:UIViewContentModeCenter];
    [buttonMenu setImage:menuImage forState:UIControlStateNormal];
    [buttonMenu addTarget:self action:@selector(goToMenu:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonMenu];
    // Adding FLIP button
    CGRect buttonFlipFrame = CGRectMake(0, 0, 50, 50);
    buttonFlip = [[UIButton alloc] initWithFrame:buttonFlipFrame];
    UIImage *flipImage = [UIImage imageNamed:@"button_flip.png"];
    [buttonFlip setContentMode:UIViewContentModeCenter];
    [buttonFlip setImage:flipImage forState:UIControlStateNormal];
    [buttonFlip addTarget:self action:@selector(flipCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonFlip];
    // Adding FLASH button
    CGRect flashFrame = CGRectMake(50, 0, 70, 50);
    buttonFlash = [[UIButton alloc] initWithFrame:flashFrame];
    UIImage *flashImage = [UIImage imageNamed:@"button_flash_on.png"];
    [buttonFlash setContentMode:UIViewContentModeLeft];
    [buttonFlash setImage:flashImage forState:UIControlStateNormal];
    [buttonFlash addTarget:self action:@selector(switchFlash:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonFlash];
    // Adding FLASH label
    flashFrame = CGRectMake(45, 0, 30, 50);
    flashLabel = [[UILabel alloc] initWithFrame:flashFrame];
    [flashLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:14]];
    [flashLabel setTextAlignment:NSTextAlignmentLeft];
    [flashLabel setTextColor:[UIColor whiteColor]];
    [flashLabel setText:@"OFF"];
    [self.buttonFlash addSubview:flashLabel];
    
    // Adding timer label
    labelTimer = [[VYBCaptureProgressView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.width - (48+10), self.view.bounds.size.height, 10)];
    [self.view addSubview:labelTimer];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

/**
 * Helper functions
 **/

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
    //NSInteger secondsSinceStart = (NSInteger)[[NSDate date] timeIntervalSinceDate:startTime];
    //int secondsLeft = 7 - (int)secondsSinceStart;
    //NSString *secondsPassed = [NSString stringWithFormat:@"00:%02d", secondsLeft];
    
    //labelTimer.text = secondsPassed;
    [labelTimer incrementBar];
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
        NSLog(@"Start recording");
        newVybe = [[VYBVybe alloc] initWithDeviceId:adId];
        //startTime = [newVybe timeStamp];
        // Of course, it is not uploaded to S3 yet
              
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:[newVybe videoPath]];
        [movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
        
        recordingTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(timer:) userInfo:nil repeats:YES];
        recording = YES; buttonFlip.hidden = recording; buttonMenu.hidden = recording; buttonFlash.hidden = recording;
    }
    
    /* Stop Recording */
    else {
        [movieFileOutput stopRecording];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self turnOffFlash];
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
        buttonFlash.hidden = NO;
    } else {
        videoInput = [self frontCameraInput];
        buttonFlash.hidden = YES;
    }
    
    [session addInput:videoInput];
    frontCamera = !frontCamera;
    
    // Setting orientation of AVCaptureMovieFileOutput AFTER a video input is added back to session
    AVCaptureConnection *movieConnection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    [movieConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];

    [session startRunning];
}

- (void)goToMenu:(id)sender {
    VYBMenuViewController *menuVC = [[VYBMenuViewController alloc] init];
    [[self navigationController] pushViewController:menuVC animated:NO];
}

- (void)removeOverlay:(UIView *)overlay {
    [overlay removeFromSuperview];
}

- (void)displayOverlay:(NSNotification *)note {
    UIDevice *device = [note object];
    if ( UIDeviceOrientationIsPortrait([device orientation]) ) {
        UIWindow *window = self.view.window;
        overlayView = [[UIView alloc] initWithFrame:window.bounds];
        [overlayView setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:1.0f]];
        [overlayView setUserInteractionEnabled:YES];
        
        [window addSubview:overlayView];
    } else if ( UIDeviceOrientationIsLandscape([device orientation]) ) {
        [self removeOverlay:overlayView];
    }
}


/**
 * Callback functions to conform to protocols
 **/

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    BOOL recordSuccess = YES;
    if ( [error code] != noErr ) {
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value)
            recordSuccess = [value boolValue];
    }
    
    if (recordSuccess) {
        NSLog(@"Record succes");
        // Prompt a review screen to save it or not
        VYBReplayViewController *replayVC = [[VYBReplayViewController alloc] init];
        [replayVC setVybe:newVybe];
        [replayVC setReplayURL:outputFileURL];

        [self.navigationController pushViewController:replayVC animated:NO];
    }

    startTime = nil;
    [recordingTimer invalidate];
    recordingTimer = nil;
    [labelTimer resetBar];
    recording = NO; buttonFlip.hidden = recording; buttonMenu.hidden = recording; buttonFlash.hidden = (recording || frontCamera);
    newVybe = nil;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
