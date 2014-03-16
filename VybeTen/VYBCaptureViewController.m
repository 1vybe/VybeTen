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

// Fix orientation to landscapeRight
- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        recording = NO;
        frontCamera = NO;
        // Retrieves this device's unique ID
        adId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    }
    return self;
}

- (void)setSession:(AVCaptureSession *)s withVideoInput:(AVCaptureDeviceInput *)vidInput withMovieFileOutput:(AVCaptureMovieFileOutput *)movieOutput{
    session = s;
    videoInput = vidInput;
    movieFileOutput = movieOutput;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Adding swipe gestures
    UITapGestureRecognizer * tapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(startRecording)];
    [self.view addGestureRecognizer:tapGesture];

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
    NSInteger secondsSinceStart = (NSInteger)[[NSDate date] timeIntervalSinceDate:startTime];
    int secondsLeft = 7 - (int)secondsSinceStart;
    NSString *secondsPassed = [NSString stringWithFormat:@"00:%02d", secondsLeft];
    
    timerLabel.text = secondsPassed;
}

/**
 * Actions that are triggered by buttons 
 **/

- (void)startRecording {
    /* Start Recording */
    if (!recording) {
        NSLog(@"Start recording");
        newVybe = [[VYBVybe alloc] init];
        // Of course, it is not uploaded to S3 yet
        [newVybe setUpStatus:UPFRESH];
        
        startTime = [NSDate date];
        [newVybe setTimeStamp:startTime];


        // Path to save in the application's document directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *vybePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"[%@]%@", adId, startTime]];
        [newVybe setVybeKey:[NSString stringWithFormat:@"[%@]%@.mov", adId, startTime]];
        [newVybe setVybePath:vybePath];
        NSLog(@"Saving a vybe at:%@", [newVybe videoPath]);
        
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:[newVybe videoPath]];
        [movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
        
        recordingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timer:) userInfo:nil repeats:YES];
        recording = YES; flipButton.hidden = recording; menuButton.hidden = recording;
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

- (IBAction)flipCamera:(id)sender {
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

- (IBAction)goToMenu:(id)sender {
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

        // Prompt a review screen to save it or not
        VYBReplayViewController *replayVC = [[VYBReplayViewController alloc] init];
        [replayVC setVybe:newVybe];
        [replayVC setReplayURL:outputFileURL];

        [self.navigationController pushViewController:replayVC animated:NO];
    }

    startTime = nil;
    [recordingTimer invalidate];
    recordingTimer = nil;
    timerLabel.text = @"00:07";
    recording = NO; flipButton.hidden = recording; menuButton.hidden = recording;
    newVybe = nil;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
