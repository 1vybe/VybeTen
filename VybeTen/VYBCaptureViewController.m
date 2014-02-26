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
#import "VYBVybeStore.h"
#import "VYBVybe.h"

@interface VYBCaptureViewController ()

@end

@implementation VYBCaptureViewController {
    AVCaptureMovieFileOutput *movieFileOutput;
    NSString *outputPath;
    NSTimer *recordingTimer;
    BOOL recording;
    
    VYBVybe *newVybe;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        recording = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup for video capturing session
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    [session setSessionPreset:AVCaptureSessionPresetHigh];

    
    // Add video input from camera
    AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:nil];
    if ( [session canAddInput:deviceInput] )
        [session addInput:deviceInput];
    
    
    // Setup preview layer
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [[previewLayer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    // Add audio input from mic
    
    // Add movie file output
    // Orientation must be set AFTER FileOutput is added to session
    movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    Float64 totalSeconds = 7;
    int32_t preferredTimeScale = 30;
    CMTime maxDuration = CMTimeMakeWithSeconds(totalSeconds, preferredTimeScale);
    movieFileOutput.maxRecordedDuration = maxDuration;
    movieFileOutput.minFreeDiskSpaceLimit = 1024 * 512;
    if ( [session canAddOutput:movieFileOutput] )
        [session addOutput:movieFileOutput];
    AVCaptureConnection *movieConnection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    [movieConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
 
    
    // Display preview layer
    CALayer *rootLayer = [[self view] layer];
    [rootLayer setMasksToBounds:YES];
    [previewLayer setFrame:CGRectMake(0, 0, rootLayer.bounds.size.width, rootLayer.bounds.size.height)];
    [rootLayer insertSublayer:previewLayer atIndex:0];
    
    
    [session startRunning];
}

- (IBAction)startRecording:(id)sender {
    // Start Recording
    // Display the remaining time from 7 seconds
    if (!recording) {
        NSDate *date = [NSDate date];
        NSLog(@"Recording Started. Date: %@", date);
    
        newVybe = [[VYBVybe alloc] init];
        [newVybe setTimeStamp:date];
        
        // Path to save in the application's document directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *recordedFileName = nil;
        recordedFileName = [NSString stringWithFormat:@"%@.mov", date];
        NSString *documentsDirectory = [paths objectAtIndex:0];
        outputPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", recordedFileName]];
        NSLog(@"Video will be saved to %@", outputPath);
        
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
        [movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
        //recordingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(VideoRecording) userInfo:nil repeats:YES];
        
        recording = YES;
    }
    
    // Stop Recording
    // Save the vybe automatically and keep recording
    else {
        NSLog(@"Recodring Stopped.");
        [movieFileOutput stopRecording];
        
        recording = NO;
        
        //TODO: Animated effect to show that the captured vybe is saved and shrinked into menu button
        //TODO: Bring up a new control view with Cancel/ Done/ Replay/ Timestamp
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    NSLog(@"DidFinishRecording called");
    BOOL recordSuccess = YES;
    if ( [error code] != noErr ) {
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value)
            recordSuccess = [value boolValue];
    }
    
    if (recordSuccess)
        NSLog(@"Record SUCCESS");
    
    AVCaptureConnection *videoConnection = nil;
    for ( AVCaptureConnection *connection in [movieFileOutput connections] ) {
        for ( AVCaptureInputPort *port in [connection inputPorts] ) {
            if ( [[port mediaType] isEqual:AVMediaTypeVideo] )
                videoConnection = connection;
        }
    }

    [newVybe setVideoPath:outputPath];
    
    // Generating and saving a thumbnail for the captured vybe
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:outputFileURL options:nil];
    AVAssetImageGenerator *generate = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    NSError *err = NULL;
    CMTime time = CMTimeMake(1, 60);
    CGImageRef imgRef = [generate copyCGImageAtTime:time actualTime:NULL error:&err];
    UIImage *thumb = [[UIImage alloc] initWithCGImage:imgRef];
    [newVybe setThumbnailImg:thumb];
    
    
    [[VYBVybeStore sharedStore] addVybe:newVybe];


    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    if ( [library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputFileURL] )
        [library writeVideoAtPathToSavedPhotosAlbum:outputFileURL completionBlock:nil];
    [library writeImageToSavedPhotosAlbum:imgRef metadata:nil completionBlock:nil];
    
    recording = NO;
    newVybe = nil;
}


@end
