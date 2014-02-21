//
//  VYBCaptureViewController.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 21..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "VYBCaptureViewController.h"

@interface VYBCaptureViewController () {
    AVCaptureMovieFileOutput *movieFileOutput;
}

@end

@implementation VYBCaptureViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Setup for video capturing session
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    [session setSessionPreset:AVCaptureSessionPresetHigh];
    
    AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:nil];
    if ( [session canAddInput:deviceInput] )
        [session addInput:deviceInput];
    
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [[previewLayer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    // Add movie file output
    movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    NSString *key = (NSString *)kCVPixelBufferBytesPerRowAlignmentKey;
    NSNumber *value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32ABGR];
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    
    [videoDataOutput setVideoSettings:videoSettings];
    
    Float64 totalSeconds = 7;
    int32_t preferredTimeScale = 30;
    CMTime maxDuration = CMTimeMakeWithSeconds(totalSeconds, preferredTimeScale);
    movieFileOutput.maxRecordedDuration = maxDuration;
    movieFileOutput.minFreeDiskSpaceLimit = 1024 * 512;
    
    // Setting for MovieFileOutput
    AVCaptureConnection *movieConnection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    [movieConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    // Set frame rate
    //CMTimeShow(captureConnection.videoMinFrameDuration);
    //CMTimeShow(captureConnection.videoMaxFrameDuration);
    
    if ( [session canAddOutput:movieFileOutput] )
        [session addOutput:movieFileOutput];
    [session addOutput:videoDataOutput];
    
    
    CALayer *rootLayer = [[self view] layer];
    [rootLayer setMasksToBounds:YES];
    [previewLayer setFrame:CGRectMake(0, 0, rootLayer.bounds.size.width, rootLayer.bounds.size.height)];
    [rootLayer insertSublayer:previewLayer atIndex:0];
    
    [session startRunning];
    
}

- (IBAction)startRecording:(id)sender {
    NSDate *date = [NSDate date];
    NSLog(@" date: %@", date);
    
    // Path to save in the application's document directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
    NSString *recordedFileName = nil;
    recordedFileName = [NSString stringWithFormat:@"%@.mov", date];
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *outputPath = [documentsDirectory stringByAppendingPathComponent:recordedFileName];
    NSLog(@"video will be saved to %@", outputPath);
    
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
    [movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    
    BOOL recordSuccess = YES;
    if ( [error code] != noErr ) {
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value)
            recordSuccess = [value boolValue];
    }
    
    AVCaptureConnection *videoConnection = nil;
    for ( AVCaptureConnection *connection in [movieFileOutput connections] ) {
        NSLog(@"%@", connection);
        for ( AVCaptureInputPort *port in [connection inputPorts] ) {
            NSLog(@"%@", port);
            if ( [[port mediaType] isEqual:AVMediaTypeVideo] )
                videoConnection = connection;
        }
    }
    
    NSData *videoData = [NSData dataWithContentsOfURL:outputFileURL];
    [videoData writeToFile:self.outputPath atomically:NO];
}

@end
