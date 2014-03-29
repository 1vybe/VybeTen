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
}
@synthesize labelTimer, buttonFlip, buttonMenu;

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
    
    recording = NO;
    frontCamera = NO;

    // Adding swipe gestures
    UITapGestureRecognizer * tapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(startRecording)];
    [self.view addGestureRecognizer:tapGesture];
    
    /* NOTE: Origin for menu button is (0, 0) */
    // Adding menu button
    CGRect buttonMenuFrame = CGRectMake(self.view.bounds.size.height - 50, self.view.bounds.size.width - 50, 50, 50);    buttonMenu = [[UIButton alloc] initWithFrame:buttonMenuFrame];
    UIImage *menuImage = [UIImage imageNamed:@"button_menu.png"];
    [buttonMenu setContentMode:UIViewContentModeCenter];
    [buttonMenu setImage:menuImage forState:UIControlStateNormal];
    [buttonMenu addTarget:self action:@selector(goToMenu:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonMenu];
    // Adding flip button
    CGRect buttonFlipFrame = CGRectMake(0, self.view.bounds.size.width - 50, 50, 50);
    buttonFlip = [[UIButton alloc] initWithFrame:buttonFlipFrame];
    UIImage *flipImage = [UIImage imageNamed:@"button_flip.png"];
    [buttonFlip setContentMode:UIViewContentModeCenter];
    [buttonFlip setImage:flipImage forState:UIControlStateNormal];
    [buttonFlip addTarget:self action:@selector(flipCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonFlip];
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
        recording = YES; buttonFlip.hidden = recording; buttonMenu.hidden = recording;
    }
    
    /* Stop Recording */
    else {
        [movieFileOutput stopRecording];
        
        /*
        startTime = nil;
        [recordingTimer invalidate];
        recordingTimer = nil;
        timerLabel.text = @"00:07";
        recording = NO; flipButton.hidden = recording; menuButton.hidden = recording;
         */
        //TODO: Animated effect to show that the captured vybe is saved and shrinked into menu button
        //TODO: Bring up a new control view with Cancel/ Done/ Replay/ Timestamp
    }
}

- (void)flipCamera:(id)sender {
    [session stopRunning];
    [session removeInput:videoInput];
    if (frontCamera)
        videoInput = [self backCameraInput];
    else
        videoInput = [self frontCameraInput];
    
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
    recording = NO; buttonFlip.hidden = recording; buttonMenu.hidden = recording;
    newVybe = nil;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
