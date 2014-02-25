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
#import "VYBVybeStore.h"
#import "VYBVybe.h"

@interface VYBCaptureViewController ()

@end

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
    }
    return self;
}

- (void)setSession:(AVCaptureSession *)s WithVideoInput:(AVCaptureDeviceInput *)vidInput WithMovieFileOutput:(AVCaptureMovieFileOutput *)movieOutput{
    session = s;
    videoInput = vidInput;
    movieFileOutput = movieOutput;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    
    NSString *secondsPassed = [NSString stringWithFormat:@"00:%02d", 7 - secondsSinceStart];
    
    timerLabel.text = secondsPassed;
}


/**
 * Actions that are triggered by buttons 
 **/

- (IBAction)startRecording:(id)sender {
    // Start Recording
    // Display the remaining time from 7 seconds
    if (!recording) {
        newVybe = [[VYBVybe alloc] init];

        startTime = [NSDate date];
        NSLog(@"Recording Started. Date: %@", startTime);
        [newVybe setTimeStamp:startTime];

        // Path to save in the application's document directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *vybePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", startTime]];
        [newVybe setVybePath:vybePath];

        
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:[newVybe getVideoPath]];
        [movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
        
        recordingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timer:) userInfo:nil repeats:YES];
        recording = YES; flipButton.hidden = recording; menuButton.hidden = recording;
    }
    
    // Stop Recording
    // Save the vybe automatically and keep recording
    else {
        NSLog(@"Recodring Stopped.");
        [movieFileOutput stopRecording];
        
        startTime = nil;
        [recordingTimer invalidate];
        recordingTimer = nil;
        timerLabel.text = @"00:07";
        recording = NO; flipButton.hidden = recording; menuButton.hidden = recording;

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
    [[self navigationController] pushViewController:menuVC animated:YES];
}


/**
 * Callback functions to conform to protocols
 **/

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    NSLog(@"DidFinishRecording called");
    BOOL recordSuccess = YES;
    if ( [error code] != noErr ) {
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value)
            recordSuccess = [value boolValue];
    }
    
    if (recordSuccess) {
        AVCaptureConnection *videoConnection = nil;
        for ( AVCaptureConnection *connection in [movieFileOutput connections] ) {
            for ( AVCaptureInputPort *port in [connection inputPorts] ) {
                if ( [[port mediaType] isEqual:AVMediaTypeVideo] )
                    videoConnection = connection;
            }
        }
        
        // Generating and saving a thumbnail for the captured vybe
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:outputFileURL options:nil];
        AVAssetImageGenerator *generate = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        NSError *err = NULL;
        CMTime time = CMTimeMake(1, 60);
        CGImageRef imgRef = [generate copyCGImageAtTime:time actualTime:NULL error:&err];
        UIImage *thumb = [[UIImage alloc] initWithCGImage:imgRef];
        NSData *thumbData = UIImageJPEGRepresentation(thumb, 1);
        NSString *thumbPath = [newVybe getThumbnailPath];
        NSURL *thumbURL = [[NSURL alloc] initFileURLWithPath:thumbPath];
        [thumbData writeToURL:thumbURL atomically:YES];
        
        [[VYBVybeStore sharedStore] addVybe:newVybe];
        
        // Save the video and snapshot in a device's photo album
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if ( [library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputFileURL] )
            [library writeVideoAtPathToSavedPhotosAlbum:outputFileURL completionBlock:nil];
        [library writeImageToSavedPhotosAlbum:imgRef metadata:nil completionBlock:nil];
        
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
