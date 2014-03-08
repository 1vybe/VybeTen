//
//  VYBCaptureViewController.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 21..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import <AWSRuntime/AWSRuntime.h>
#import "VYBCaptureViewController.h"
#import "VYBMenuViewController.h"
#import "VYBMyVybeStore.h"
#import "VYBConstants.h"

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
@synthesize s3 = _s3;

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
    
    // Initialize S3 client
    @try {
        self.s3 = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
        self.s3.endpoint = [AmazonEndpoints s3Endpoint:US_WEST_2];
    } @catch (AmazonServiceException *exception) {
        NSLog(@"FAILURE: %@", exception);
    }

    
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
        newVybe = [[VYBVybe alloc] init];
        // Of course, it is not uploaded to S3 yet
        [newVybe setUploaded:NO];
        
        startTime = [NSDate date];
        [newVybe setTimeStamp:startTime];


        // Path to save in the application's document directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *vybePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", startTime]];
        [newVybe setVybePath:vybePath];
        
        
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:[newVybe videoPath]];
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
        [generate setAppliesPreferredTrackTransform:YES]; /* To transform the snapshot to be in the orientation the video was taken with */
        NSError *err = NULL;
        CMTime time = CMTimeMake(1, 60);
        CGImageRef imgRef = [generate copyCGImageAtTime:time actualTime:NULL error:&err];
        UIImage *thumb = [[UIImage alloc] initWithCGImage:imgRef];
        NSData *thumbData = UIImageJPEGRepresentation(thumb, 1);
        NSURL *thumbURL = [[NSURL alloc] initFileURLWithPath:[newVybe thumbnailPath]];
        [thumbData writeToURL:thumbURL atomically:YES];
        
        // Save the capture vybe
        [[VYBMyVybeStore sharedStore] addVybe:newVybe];
        
        // Upload it to AWS S3
        NSData *videoData = [NSData dataWithContentsOfURL:outputFileURL];
        [self processDelegateUpload:videoData];
    }
    
    startTime = nil;
    [recordingTimer invalidate];
    recordingTimer = nil;
    timerLabel.text = @"00:07";
    recording = NO; flipButton.hidden = recording; menuButton.hidden = recording;
    newVybe = nil;
}

/**
 * Functions related to uploading to AWS S3
 **/
- (void)processDelegateUpload:(NSData *)video {
    // First genereate a unique device ID
    NSString *keyString = [NSString stringWithFormat:@"%@.mov", [newVybe timeStamp]];
    S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:keyString inBucket:@"vybes"];
    
    por.contentType = @"video/quicktime";
    por.data = video;
    por.delegate = self;
    
    @try {
        [self.s3 putObject:por];
    }@catch (AmazonServiceException *exception) {
        NSLog(@"Upload Failed: %@", exception);
    }
    NSLog(@"uploading started");
}

- (void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response {
    NSLog(@"upload success");
    VYBVybe *lastVybe = [[[VYBMyVybeStore sharedStore] myVybes] lastObject];
    [lastVybe setUploaded:YES];
}

- (void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"upload failed: %@", error);
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
