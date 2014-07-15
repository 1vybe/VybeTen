
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
#import "VYBCameraView.h"
#import "VYBLabel.h"
#import "VYBMyVybeStore.h"
#import "VYBConstants.h"
#import "VYBCache.h"
#import "VYBUtility.h"

@interface VYBCaptureViewController () <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, weak) VYBCameraView *cameraView;

@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoInput;
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;

@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;
@property (nonatomic, readonly, getter = isSessionRunningAndDeviceAuthorized) BOOL sessionRunningAndDeviceAuthorized;
@property (nonatomic) id runtimeErrorHandlingObserver;

@end

@implementation VYBCaptureViewController {

    //AVCaptureVideoPreviewLayer *cameraInputLayer;
    //AVCaptureConnection *movieConnection;
    
    NSDate *startTime;
    NSTimer *recordingTimer;
    
    BOOL flashOn;
    BOOL isFrontCamera;
    
    VYBMyVybe *currVybe;
}

@synthesize flipButton, flashButton;

static void * RecordingContext = &RecordingContext;
static void * SessionRunningAndDeviceAuthorizedContext = &SessionRunningAndDeviceAuthorizedContext;

- (void)dealloc {
    self.session = nil;
    NSLog(@"CaptureVC deallocated");
}

+ (NSSet *)keyPathsForValuesAffectingSessionRunningAndDeviceAuthorized
{
	return [NSSet setWithObjects:@"session.running", @"deviceAuthorized", nil];
}


- (BOOL)isSessionRunningAndDeviceAuthorized {
    return [[self session] isRunning] && [self isDeviceAuthorized];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    [self setSession:session];
    
    VYBCameraView *cameraView = [[VYBCameraView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.height, self.view.bounds.size.width)];
    [self setCameraView:cameraView];
    [(AVCaptureVideoPreviewLayer *)[cameraView layer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [cameraView setSession:session];
    [self.view addSubview:cameraView];
    
    [self checkDeviceAuthorizationStatus];
    
    dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    [self setSessionQueue:sessionQueue];
    
    dispatch_async(sessionQueue, ^{
        [self setBackgroundRecordingID:UIBackgroundTaskInvalid];
        
        [[self session] setSessionPreset:AVCaptureSessionPresetMedium];

        NSError *error = nil;
        
        AVCaptureDevice *videoDevice = [VYBCaptureViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        
        if (error) {
            NSLog(@"video device input was NOT created");
        }
        
        if ([session canAddInput:videoDeviceInput]) {
            [session addInput:videoDeviceInput];
            [self setVideoInput:videoDeviceInput];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[(AVCaptureVideoPreviewLayer *)[[self cameraView] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)[self interfaceOrientation]];
            });
        }
        
        AVCaptureDevice *audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
        AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
        
        if (error) {
            NSLog(@"audio device input was NOT created");
        }
        
        if ([session canAddInput:audioInput]) {
            [session addInput:audioInput];
        }
        
        AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
        if ([session canAddOutput:movieFileOutput]) {
            [session addOutput:movieFileOutput];

            Float64 totalSeconds = VYBE_LENGTH_SEC;
            int32_t preferredTimeScale = 30;
            CMTime maxDuration = CMTimeMakeWithSeconds(totalSeconds, preferredTimeScale);
            movieFileOutput.maxRecordedDuration = maxDuration;
            movieFileOutput.minFreeDiskSpaceLimit = 1024 * 512;

            AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            if ([connection isVideoStabilizationSupported])
                [connection setEnablesVideoStabilizationWhenAvailable:YES];
            
            [connection setVideoOrientation:(AVCaptureVideoOrientation)[self interfaceOrientation]];

            [self setMovieFileOutput:movieFileOutput];
        }
    });
    
    // Hide status bar
    [self setNeedsStatusBarAppearanceUpdate];
    
    /*
    // Device orientation detection
    UIDevice *iphone = [UIDevice currentDevice];
    [iphone beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIDeviceOrientationDidChangeNotification object:iphone];
    */
    
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
    
    // Adding FLASH button
    buttonFrame = CGRectMake(self.view.bounds.size.height - 70, 0, 70, 70);
    flashButton = [[UIButton alloc] initWithFrame:buttonFrame];
    [flashButton setImage:[UIImage imageNamed:@"button_flash_on.png"] forState:UIControlStateNormal];
    [flashButton setImage:[UIImage imageNamed:@"button_flash_off.png"] forState:UIControlStateSelected];
    [flashButton setContentMode:UIViewContentModeLeft];
    [flashButton addTarget:self action:@selector(switchFlash:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:flashButton];
    
}

- (void)viewWillAppear:(BOOL)animated {
    dispatch_async([self sessionQueue], ^{
        [self addObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:SessionRunningAndDeviceAuthorizedContext];
        
        [self addObserver:self forKeyPath:@"movieFileOutput.recording" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:RecordingContext];
        
        __weak VYBCaptureViewController *weakSelf = self;
        [self setRuntimeErrorHandlingObserver:[[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureSessionRuntimeErrorNotification object:[self session] queue:nil usingBlock:^(NSNotification *note) {
			VYBCaptureViewController *strongSelf = weakSelf;
			dispatch_async([strongSelf sessionQueue], ^{
				// Manually restarting the session since it must have been stopped due to an error.
				[[strongSelf session] startRunning];
			});
		}]];
        
		[[self session] startRunning];
    });
    
    flashButton.selected = flashOn;
    flipButton.selected = isFrontCamera;
}

- (void)viewWillDisappear:(BOOL)animated {
 	dispatch_async([self sessionQueue], ^{
		[[self session] stopRunning];

		[[NSNotificationCenter defaultCenter] removeObserver:[self runtimeErrorHandlingObserver]];
		
		[self removeObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" context:SessionRunningAndDeviceAuthorizedContext];
		[self removeObserver:self forKeyPath:@"movieFileOutput.recording" context:RecordingContext];
	});

}


+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
	AVCaptureDevice *captureDevice = [devices firstObject];
	
	for (AVCaptureDevice *device in devices)
	{
		if ([device position] == position)
		{
			captureDevice = device;
			break;
		}
	}
	
	return captureDevice;
}


- (void)switchFlash:(id)sender {
    flashOn = !flashOn;
    flashButton.selected = flashOn;
}


+ (void)setTorchMode:(AVCaptureTorchMode)torchMode forDevice:(AVCaptureDevice *)device
{
	if ([device hasTorch] && [device isTorchModeSupported:torchMode])
	{
        NSLog(@"Hello");
		NSError *error = nil;
		if ([device lockForConfiguration:&error])
		{
            [device setTorchMode:torchMode];
			[device unlockForConfiguration];
		}
		else
		{
			NSLog(@"%@", error);
		}
	} else {
        NSLog(@"THAT'S RIGHT");
    }
}

- (void)flipCamera:(id)sender {
    [[self flipButton] setEnabled:NO];
    [[self viewButton] setEnabled:NO];
    
    dispatch_async([self sessionQueue], ^{
        AVCaptureDevice *currentVideoDevice = [[self videoInput] device];
        AVCaptureDevicePosition currentPosition = [currentVideoDevice position];
        AVCaptureDevicePosition prefferedPosition = AVCaptureDevicePositionUnspecified;
        
        switch (currentPosition) {
            case AVCaptureDevicePositionUnspecified:
                prefferedPosition = AVCaptureDevicePositionBack;
                break;
            case AVCaptureDevicePositionBack:
                prefferedPosition = AVCaptureDevicePositionFront;
                break;
            case AVCaptureDevicePositionFront:
                prefferedPosition = AVCaptureDevicePositionBack;
                break;
        }
        
        AVCaptureDevice *videoDevice = [VYBCaptureViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:prefferedPosition];
        AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
        
        [[self session] beginConfiguration];
        
        [[self session] removeInput:[self videoInput]];
        if ( [[self session] canAddInput:videoInput] ) {
            [[self session] addInput:videoInput];
            [self setVideoInput:videoInput];
            
        } else {
            [[self session] addInput:[self videoInput]];
        }
        [[self session] commitConfiguration];
        
        // Video should be mirrored if coming from the front camera
        [[[self movieFileOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoMirrored:[videoDevice position] == AVCaptureDevicePositionFront];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            isFrontCamera = [videoDevice position] == AVCaptureDevicePositionFront;
            [[self flipButton] setSelected:isFrontCamera];
            [self flashButton].hidden = isFrontCamera;
            [[self viewButton] setEnabled:YES];
            [[self flipButton] setEnabled:YES];
        });
        
    });
    
}

#pragma mark - UIResponder

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([self isDeviceAuthorized]) {
        [self.view addSubview:self.captureButton];
        self.captureButton.center = [[touches anyObject] locationInView:self.view];
        [self.captureButton setNeedsDisplay];
        
        [self startRecording];
    }
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
    CGPoint pt = [[touches anyObject] locationInView:self.view];
    self.captureButton.center = pt;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    dispatch_async([self sessionQueue], ^{
        [self.movieFileOutput stopRecording];
    });
    
    [self.captureButton removeFromSuperview];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

- (void)startRecording {
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
    
    if (recordingTimer) {
        [recordingTimer invalidate];
        recordingTimer = nil;
    }
    recordingTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(timer:) userInfo:nil repeats:YES];

    dispatch_async([self sessionQueue], ^{
        if ([[UIDevice currentDevice] isMultitaskingSupported])
        {
            // Setup background task. This is needed because the captureOutput:didFinishRecordingToOutputFileAtURL: callback is not received until AVCam returns to the foreground unless you request background execution time. This also ensures that there will be time to write the file to the assets library when AVCam is backgrounded. To conclude this background execution, -endBackgroundTask is called in -recorder:recordingDidFinishToOutputFileURL:error: after the recorded file has been saved.
            [self setBackgroundRecordingID:[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil]];
        }

        [[[self movieFileOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[(AVCaptureVideoPreviewLayer *)[[self cameraView] layer] connection] videoOrientation]];

        // Turning OFF flash for video recording
        if (flashOn) {
            [VYBCaptureViewController setTorchMode:AVCaptureTorchModeOn forDevice:[[self videoInput] device]];
        } else {
            [VYBCaptureViewController setTorchMode:AVCaptureTorchModeOff forDevice:[[self videoInput] device]];
        }
        
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:[currVybe videoFilePath]];
        [self.movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
    });
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


#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    // If screen is switched to Player screen automatically by timer, remove capture button.
    if (self.captureButton.superview) {
        [self.captureButton removeFromSuperview];
    }

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
    
    UIBackgroundTaskIdentifier backgroundRecordingID = [self backgroundRecordingID];
	[self setBackgroundRecordingID:UIBackgroundTaskInvalid];
    
    if (backgroundRecordingID != UIBackgroundTaskInvalid)
        [[UIApplication sharedApplication] endBackgroundTask:backgroundRecordingID];

}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == RecordingContext)
	{
		BOOL isRecording = [change[NSKeyValueChangeNewKey] boolValue];
        if (!isRecording) {
            [VYBCaptureViewController setTorchMode:AVCaptureTorchModeOff forDevice:[[self videoInput] device]];
        }
        
		dispatch_async(dispatch_get_main_queue(), ^{
			if (isRecording)
			{
                [self syncUIWithRecordingStatus:YES];
			}
			else
			{
                [self syncUIWithRecordingStatus:NO];
			}
		});
	}
	else if (context == SessionRunningAndDeviceAuthorizedContext)
	{
        
    }
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark - DeviceOrientation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[[(AVCaptureVideoPreviewLayer *)[[self cameraView] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)toInterfaceOrientation];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

/*
- (void)adjustToOrientation:(UIDeviceOrientation)orientation {
    if (orientation == UIDeviceOrientationLandscapeLeft) {
        [[(AVCaptureVideoPreviewLayer *)[[self cameraView] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)orientation];
        //[movieConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    } else if (orientation == UIDeviceOrientationLandscapeRight) {
        [[(AVCaptureVideoPreviewLayer *)[[self cameraView] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)orientation];
        //[movieConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
    }
    
    //[self displayMessageToRotate:orientation];
}

- (void)displayMessageToRotate:(UIDeviceOrientation)orientation {
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
}
*/


#pragma mark - ()

- (void)checkDeviceAuthorizationStatus {
    NSString *mediaType = AVMediaTypeVideo;
    
    [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        if (granted) {
            [self setDeviceAuthorized:YES];
        } else {
            //Not granted access to mediaType
			dispatch_async(dispatch_get_main_queue(), ^{
				[[[UIAlertView alloc] initWithTitle:nil
											message:@"Please change privacy settings for Vybe to access your camera."
										   delegate:self
								  cancelButtonTitle:@"OK"
								  otherButtonTitles:nil] show];
				[self setDeviceAuthorized:NO];
			});
        }
    }];
}

- (void)syncUIWithRecordingStatus:(BOOL)status {
    self.viewButton.hidden = status; flipButton.hidden = status; flashButton.hidden = status || isFrontCamera;
}

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
