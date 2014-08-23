
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
#import <GAI.h>
#import <GAITracker.h>
#import <GAIFields.h>
#import <GAIDictionaryBuilder.h>
#import <MotionOrientation@PTEz/MotionOrientation.h>
#import "VYBAppDelegate.h"
#import "VYBCaptureViewController.h"
#import "VYBHubViewController.h"
#import "VYBFriendsViewController.h"
#import "VYBProfileViewController.h"
#import "VYBUserStore.h"
#import "VYBLogInViewController.h"
#import "VYBPlayerViewController.h"
#import "VYBReplayViewController.h"
#import "VYBPermissionViewController.h"
#import "VYBCameraView.h"
#import "VYBLabel.h"
#import "VYBMyVybeStore.h"
#import "VYBConstants.h"
#import "VYBCache.h"
#import "VYBUtility.h"

@interface VYBCaptureViewController () <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, strong) VYBMyVybe *currVybe;

@property (nonatomic, weak) VYBCameraView *cameraView;

@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) dispatch_queue_t assetWriterQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoInput;
@property (nonatomic) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic) AVCaptureAudioDataOutput *audioOutput;
@property (nonatomic) AVAssetWriter *videoWriter;
@property (nonatomic) AVAssetWriter *audioWriter;
@property (nonatomic, strong) AVAssetWriterInput *videoWriterInput;
@property (nonatomic) AVAssetWriterInput *audioWriterInput;


//@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;

@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;
@property (nonatomic, readonly, getter = isSessionRunningAndDeviceAuthorized) BOOL sessionRunningAndDeviceAuthorized;
@property (nonatomic) id runtimeErrorHandlingObserver;

@property (nonatomic, strong) VYBPermissionViewController *permissionVC;
@end

@implementation VYBCaptureViewController {

    NSDate *startTime;
    NSTimer *recordingTimer;
    CMTime lastSampleTime;
    
    BOOL flashOn;
    BOOL isFrontCamera;
    BOOL isRecording;
    
    CLLocationManager *locationManager;
    
    AVCaptureVideoOrientation lastOrientation;
}

@synthesize flipButton, flashButton;

static void * RecordingContext = &RecordingContext;
static void * SessionRunningAndDeviceAuthorizedContext = &SessionRunningAndDeviceAuthorizedContext;

- (void)dealloc {
    self.session = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBAppDelegateApplicationDidReceiveRemoteNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBAppDelegateApplicationDidBecomeActive object:nil];
    
    NSLog(@"CaptureVC deallocated");
}

- (id)init {
    self = [super init];
    if (self) {
        isRecording = NO;
    }
    return self;
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
    
    lastOrientation = AVCaptureVideoOrientationPortrait;
    
    if ([CLLocationManager locationServicesEnabled]) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy=kCLLocationAccuracyBest;
    }
    
    // AppDelegate Notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteNotificationReceived:) name:VYBAppDelegateApplicationDidReceiveRemoteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActiveNotificationReceived:) name:VYBAppDelegateApplicationDidBecomeActive object:nil];

    
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
     action:@selector(longPressDetected:)];
    longPressRecognizer.minimumPressDuration = 0.3;
    longPressRecognizer.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:longPressRecognizer];
    

    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    [self setSession:session];
    
    VYBCameraView *cameraView = [[VYBCameraView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    [self setCameraView:cameraView];
    [(AVCaptureVideoPreviewLayer *)[cameraView layer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [cameraView setSession:session];
    [self.view addSubview:cameraView];
    
    [self checkDeviceAuthorizationStatus];
    
    dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t assetWriterQueue = dispatch_queue_create("assetWriter queue", DISPATCH_QUEUE_SERIAL);
    [self setSessionQueue:sessionQueue];
    [self setAssetWriterQueue:assetWriterQueue];
    
    dispatch_async(sessionQueue, ^{
        [self setBackgroundRecordingID:UIBackgroundTaskInvalid];
        
        [[self session] setSessionPreset:AVCaptureSessionPreset640x480];
        
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
                [[(AVCaptureVideoPreviewLayer *)[[self cameraView] layer] connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];
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
        
        dispatch_queue_t queue = dispatch_queue_create("MyQueue", NULL);
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        if ([session canAddOutput:_videoOutput]) {
            [session addOutput:_videoOutput];

            _videoOutput.alwaysDiscardsLateVideoFrames = NO;
            _videoOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
            
            AVCaptureConnection *connection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
            if ([connection isVideoStabilizationSupported])
                [connection setEnablesVideoStabilizationWhenAvailable:YES];
            
            [connection setVideoOrientation:lastOrientation];
            [_videoOutput setSampleBufferDelegate:self queue:queue];
        }
        
        _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        if ([session canAddOutput:_audioOutput]) {
            [session addOutput:_audioOutput];
            [_audioOutput setSampleBufferDelegate:self queue:queue];
        }
        
    });
    
    // Hide status bar
    [self setNeedsStatusBarAppearanceUpdate];
    
    // Device orientation detection
    [MotionOrientation initialize];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceRotated:)
                                                 name:MotionOrientationChangedNotification
                                               object:nil];
    
    // Adding CAPTURE button
    self.captureButton = [[VYBCaptureButton alloc] initWithFrame:CGRectMake(0, 0, 144, 144)];
    
    // Adding PRIVATE button
    CGRect buttonFrame = CGRectMake(self.view.bounds.size.width - 70, self.view.bounds.size.height - 70, 70, 70);
    self.privateViewButton = [[UIButton alloc] initWithFrame:buttonFrame];
    [self.privateViewButton setImage:[UIImage imageNamed:@"button_private_view.png"] forState:UIControlStateNormal];
    //[self.privateViewButton setImage:[UIImage imageNamed:@"button_private_view_new.png"] forState:UIControlStateSelected];
    [self.privateViewButton addTarget:self action:@selector(privateViewButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.privateViewButton setContentMode:UIViewContentModeLeft];
    [self.view addSubview:self.privateViewButton];
    
    // Adding PRIVATE count label
    buttonFrame = CGRectMake(self.view.bounds.size.width - 70, self.view.bounds.size.height - 70, 70, 70);
    self.privateViewCountLabel = [[VYBLabel alloc] initWithFrame:buttonFrame];
    [self.privateViewCountLabel setTextAlignment:NSTextAlignmentCenter];
    [self.privateViewCountLabel setFont:[UIFont fontWithName:@"AvenirLTStd-Book.otf" size:20.0]];
    [self.privateViewCountLabel setTextColor:[UIColor whiteColor]];
    self.privateViewCountLabel.userInteractionEnabled = NO;
    //[self.view addSubview:self.privateViewCountLabel];

    // Adding HUB button
    buttonFrame = CGRectMake(0, self.view.bounds.size.height - 70, 70, 70);
    self.hubButton = [[UIButton alloc] initWithFrame:buttonFrame];
    [self.hubButton setImage:[UIImage imageNamed:@"button_hub.png"] forState:UIControlStateNormal];
    [self.hubButton addTarget:self action:@selector(hubButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.hubButton];
    
    // Adding FLIP button
    buttonFrame = CGRectMake(0, 0, 70, 70);
    flipButton = [[UIButton alloc] initWithFrame:buttonFrame];
    [flipButton setImage:[UIImage imageNamed:@"button_camera_front.png"] forState:UIControlStateNormal];
    [flipButton setImage:[UIImage imageNamed:@"button_camera_back.png"] forState:UIControlStateSelected];
    [flipButton setContentMode:UIViewContentModeCenter];
    [flipButton addTarget:self action:@selector(flipCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:flipButton];
    
    // Adding FLASH button
    buttonFrame = CGRectMake(self.view.bounds.size.width - 70, 0, 70, 70);
    flashButton = [[UIButton alloc] initWithFrame:buttonFrame];
    [flashButton setImage:[UIImage imageNamed:@"button_flash_on.png"] forState:UIControlStateNormal];
    [flashButton setImage:[UIImage imageNamed:@"button_flash_off.png"] forState:UIControlStateSelected];
    [flashButton setContentMode:UIViewContentModeLeft];
    [flashButton addTarget:self action:@selector(switchFlash:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:flashButton];
    
    if ([[VYBUserStore sharedStore] newPrivateVybeCount] > 0) {
        [self.privateViewButton setSelected:YES];
        [self.privateViewCountLabel setText:[NSString stringWithFormat:@"%d", (int)[[VYBUserStore sharedStore] newPrivateVybeCount]]];
    } else {
        [self.privateViewButton setSelected:NO];
        [self.privateViewCountLabel setText:@""];
    }
    
    if ( [[PFUser currentUser] objectForKey:@"tribe"] ) {
        PFObject *myTribe = [[PFUser currentUser] objectForKey:@"tribe"];
        [myTribe fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error) {
                PFRelation *members = [object relationForKey:kVYBTribeMembersKey];
                PFQuery *countQuery = [PFQuery queryWithClassName:kVYBVybeClassKey];
                [countQuery whereKey:kVYBVybeUserKey matchesQuery:[members query]];
                [countQuery whereKey:kVYBVybeUserKey notEqualTo:[PFUser currentUser]];
                [countQuery whereKey:kVYBVybeTimestampKey greaterThan:[[VYBUserStore sharedStore] lastWatchedVybeTimeStamp]];
                [countQuery whereKey:kVYBVybeTypePublicKey equalTo:[NSNumber numberWithBool:NO]];
                [countQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                    if (!error) {
                        if (number > 0) {
                            [self.privateViewButton setSelected:YES];
                            [self.privateViewCountLabel setText:[NSString stringWithFormat:@"%d", number]];
                            [[VYBUserStore sharedStore] setNewPrivateVybeCount:number];
                        }
                    }
                }];
            }
        }];
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self session] && ![[self session] isRunning]) {
        dispatch_async([self sessionQueue], ^{
            [self addObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:SessionRunningAndDeviceAuthorizedContext];
            
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
    }
    
    if ([[VYBUserStore sharedStore] newPrivateVybeCount] > 0) {
        self.privateViewButton.selected = YES;
        self.privateViewCountLabel.text = [NSString stringWithFormat:@"%d", (int)[[VYBUserStore sharedStore] newPrivateVybeCount]];
    } else {
        self.privateViewButton.selected = NO;
        self.privateViewCountLabel.text = @"";
    }
    
    flashButton.selected = flashOn;
    flipButton.selected = isFrontCamera;
    
    // Google Analytics
    self.screenName = @"Capture Screen";
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (![PFUser currentUser]) {
        VYBLogInViewController *logInVC = [[VYBLogInViewController alloc] init];
        [self presentViewController:logInVC animated:NO completion:nil];
    }
    else {
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
            self.permissionVC = [[VYBPermissionViewController alloc] init];
            [self presentViewController:self.permissionVC animated:NO completion:nil];
        }
        if([CLLocationManager authorizationStatus]==kCLAuthorizationStatusDenied){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location Access Denied"
                                                            message:@"Please go to Settings and turn on Location Service for this app."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }
    
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName
                                       value:@"Capture Screen"];
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker
     send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
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
    NSError *error;
    if ([captureDevice lockForConfiguration:&error]) {
        if ([captureDevice isLowLightBoostSupported]) {
            [captureDevice setAutomaticallyEnablesLowLightBoostWhenAvailable:YES];
        }
        if ([captureDevice isSmoothAutoFocusSupported]) {
            [captureDevice setSmoothAutoFocusEnabled:YES];
        }
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            [captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        [captureDevice unlockForConfiguration];

        
    } else {
        NSLog(@"Low light boost configuration failed: %@", error);
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
	}
}

- (void)flipCamera:(id)sender {
    [[self flipButton] setEnabled:NO];
    [[self privateViewButton] setEnabled:NO];
    [[self hubButton] setEnabled:NO];

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
        [[[self videoOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoMirrored:[videoDevice position] == AVCaptureDevicePositionFront];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            isFrontCamera = [videoDevice position] == AVCaptureDevicePositionFront;
            [[self flipButton] setSelected:isFrontCamera];
            [self flashButton].hidden = isFrontCamera;
            [[self privateViewButton] setEnabled:YES];
            [[self hubButton] setEnabled:YES];
            [[self flipButton] setEnabled:YES];
        });
        
    });
    
}

#pragma mark - UIResponder

- (void)longPressDetected:(UILongPressGestureRecognizer *)recognizer {
    if (!isRecording) {
        [self.view addSubview:self.captureButton];
        double rotation = 0;
        switch (lastOrientation) {
            case AVCaptureVideoOrientationPortrait:
                rotation = 0;
                break;
            case AVCaptureVideoOrientationPortraitUpsideDown:
                rotation = -M_PI;
                break;
            case AVCaptureVideoOrientationLandscapeLeft:
                rotation = M_PI_2;
                break;
            case AVCaptureVideoOrientationLandscapeRight:
                rotation = -M_PI_2;
                break;
            default:
                return;
        }
        self.captureButton.center = [recognizer locationInView:self.view];
        
        CGAffineTransform transform = CGAffineTransformMakeRotation(rotation);
        self.captureButton.transform = transform;
        
        [self startRecording];
    }
    
    if ([recognizer state] == UIGestureRecognizerStateChanged) {
        CGPoint pt = [recognizer locationInView:self.view];
        self.captureButton.center = pt;
    }
    
    if (([recognizer state] == UIGestureRecognizerStateEnded) || ([recognizer state] == UIGestureRecognizerStateCancelled)) {
        [self.captureButton removeFromSuperview];

        if (isRecording) {
            isRecording = NO;
            [self syncUIWithRecordingStatus:NO];
            if (_videoWriter.status == AVAssetWriterStatusWriting) {
                [_videoWriter finishWritingWithCompletionHandler:^{
                    _videoWriterInput = nil;
                    _videoWriter = nil;
                }];
                [self stopRecording];
            }
        }
    }
}

- (void)startRecording {
    isRecording = YES;
    [self syncUIWithRecordingStatus:YES];

    startTime = [NSDate date];
    self.currVybe = [[VYBMyVybe alloc] init];
    [self.currVybe setTimeStamp:startTime];
    
    [locationManager startUpdatingLocation];
    
    if (recordingTimer) {
        [recordingTimer invalidate];
        recordingTimer = nil;
    }
    recordingTimer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(timer:) userInfo:nil repeats:YES];
    
    if (![self setUpAssetWriter]) {
        return;
    }
    
    dispatch_async([self sessionQueue], ^{
        if ([[UIDevice currentDevice] isMultitaskingSupported])
        {
            // Setup background task. This is needed because the captureOutput:didFinishRecordingToOutputFileAtURL: callback is not received until AVCam returns to the foreground unless you request background execution time. This also ensures that there will be time to write the file to the assets library when AVCam is backgrounded. To conclude this background execution, -endBackgroundTask is called in -recorder:recordingDidFinishToOutputFileURL:error: after the recorded file has been saved.
            [self setBackgroundRecordingID:[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil]];
        }
        
        NSLog(@"[CAPTURE] shooting in orientation %d", (int)lastOrientation);
        [[[self videoOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:lastOrientation];
        
        // Turning flash for video recording
        if (flashOn) {
            [VYBCaptureViewController setTorchMode:AVCaptureTorchModeOn forDevice:[[self videoInput] device]];
        }
        
    });
}

- (BOOL)setUpAssetWriter {
    NSError *error = nil;
    
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:[self.currVybe videoFilePath]];
    _videoWriter = [AVAssetWriter assetWriterWithURL:outputURL fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(_videoWriter);
    
    // Add video input
    NSDictionary *videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithDouble:700.0*1024.0], AVVideoAverageBitRateKey,
                                           nil ];
    NSNumber *width, *height;
    if ((lastOrientation == AVCaptureVideoOrientationLandscapeLeft) || (lastOrientation == AVCaptureVideoOrientationLandscapeRight)) {
        width = [NSNumber numberWithInt:480];
        height = [NSNumber numberWithInt:360];
    } else {
        width = [NSNumber numberWithInt:360];
        height = [NSNumber numberWithInt:480];
    }
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   width, AVVideoWidthKey,
                                   height, AVVideoHeightKey,
                                   videoCompressionProps, AVVideoCompressionPropertiesKey,
                                   nil];
    
    _videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    NSParameterAssert(_videoWriterInput);
    _videoWriterInput.expectsMediaDataInRealTime = YES;
    
    
    // Add the audio input
    AudioChannelLayout acl;
    bzero( &acl, sizeof(acl));
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    
    NSDictionary* audioOutputSettings = nil;
    // Both type of audio inputs causes output video file to be corrupted.
    if( NO ) {
        // should work from iphone 3GS on and from ipod 3rd generation
        audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                               [ NSNumber numberWithInt: kAudioFormatMPEG4AAC ], AVFormatIDKey,
                               [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
                               [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
                               [ NSNumber numberWithInt: 64000 ], AVEncoderBitRateKey,
                               [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                               nil];
    } else {
        // should work on any device requires more space
        audioOutputSettings = [ NSDictionary dictionaryWithObjectsAndKeys:
                               [ NSNumber numberWithInt: kAudioFormatAppleLossless ], AVFormatIDKey,
                               [ NSNumber numberWithInt: 16 ], AVEncoderBitDepthHintKey,
                               [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
                               [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
                               [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                               nil ];
    }
    
    _audioWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
    
    _audioWriterInput.expectsMediaDataInRealTime = YES;
    
    [_videoWriter addInput:_videoWriterInput];
    [_videoWriter addInput:_audioWriterInput];
    
    return YES;
}

- (void)timer:(NSTimer *)timer {
    double secondsSinceStart = [[NSDate date] timeIntervalSinceDate:startTime];
    // less than 3.0 because of a delay in drawing. This guarantees user hold until red circle is full to pass the minimum
    if (secondsSinceStart >= VYBE_LENGTH_SEC) {
        [self.captureButton removeFromSuperview];
        
        isRecording = NO;
        [self syncUIWithRecordingStatus:NO];
        if (_videoWriter.status == AVAssetWriterStatusWriting) {
            [_videoWriter finishWritingWithCompletionHandler:^{
                _videoWriterInput = nil;
                _videoWriter = nil;
            }];
            [self stopRecording];
        }
    }
    else if (secondsSinceStart >= 2.89) {
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

- (void)stopRecording {
    NSDate *now = [NSDate date];
    double secondsSinceStart = [now timeIntervalSinceDate:startTime];
    
    if (secondsSinceStart >= 3.0) {
        VYBReplayViewController *replayVC = [[VYBReplayViewController alloc] init];
        [replayVC setCurrVybe:self.currVybe];
        [self.navigationController pushViewController:replayVC animated:NO];
    }
    else {
        NSError *error;
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:[self.currVybe videoFilePath]];
        [[NSFileManager defaultManager] removeItemAtURL:outputURL  error:&error];
        if (error) {
            NSLog(@"Failed to delete a vybe under 3 seconds");
        }
        NSLog(@"CP2");
    }

    startTime = nil;
    [recordingTimer invalidate];
    recordingTimer = nil;
    
    [VYBCaptureViewController setTorchMode:AVCaptureTorchModeOff forDevice:[[self videoInput] device]];
    
//    
//    UIBackgroundTaskIdentifier backgroundRecordingID = [self backgroundRecordingID];
//	[self setBackgroundRecordingID:UIBackgroundTaskInvalid];
//
//    if (backgroundRecordingID != UIBackgroundTaskInvalid)
//        [[UIApplication sharedApplication] endBackgroundTask:backgroundRecordingID];
//    

}


#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        return;
    }
    
    if (isRecording) {
        lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        if(_videoWriter.status != AVAssetWriterStatusWriting)
        {
            if ((_videoWriter.status != AVAssetWriterStatusFailed) && (_videoWriter.status != AVAssetWriterStatusCompleted)) {
                [_videoWriter startWriting];
                [_videoWriter startSessionAtSourceTime:lastSampleTime];
            }
        }

        if (captureOutput == _videoOutput) {
            [self appendVideoSampleBuffer:sampleBuffer];
        } else if (captureOutput == _audioOutput) {
            [self appendAudioSampleBuffer:sampleBuffer];
        }
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    
}


- (void)appendVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (isRecording) {
        if (_videoWriter.status > AVAssetWriterStatusWriting) {
            if( _videoWriter.status == AVAssetWriterStatusFailed )
                NSLog(@"Error: %@", _videoWriter.error);
            return;
        }
        
        if (![_videoWriterInput appendSampleBuffer:sampleBuffer]) {
            NSLog(@"cannot add VIDEO sample buffer");
        }
    }
}

- (void)appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (isRecording) {
        if (_videoWriter.status > AVAssetWriterStatusWriting) {
            if( _videoWriter.status == AVAssetWriterStatusFailed )
                NSLog(@"Error: %@", _videoWriter.error);
            return;
        }
        
        if (![_audioWriterInput appendSampleBuffer:sampleBuffer]) {
            NSLog(@"cannot add AUDIO sample buffer");
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == SessionRunningAndDeviceAuthorizedContext) {
        
    }
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark - CLLocationManagerDelegate 

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Failed to get current location");
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *currLocation = [locations lastObject];
    CLGeocoder *reverseGeocoder = [[CLGeocoder alloc] init];

    [self.currVybe setGeoTag:currLocation];

    [reverseGeocoder reverseGeocodeLocation:currLocation completionHandler:^(NSArray *placemarks, NSError *error)
     {
         CLPlacemark *myPlacemark = [placemarks objectAtIndex:0];
         NSString *city = myPlacemark.locality;
         [self.currVybe setLocationString:city];
         [[PFUser currentUser] setObject:city forKey:kVYBUserLastVybedLocationKey];
     }];
    
    [locationManager stopUpdatingLocation];
}

#pragma mark - DeviceOrientation

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


/* for iOS6 and below
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)deviceRotated:(NSNotification *)notification {
    UIDeviceOrientation currentOrientation = [MotionOrientation sharedInstance].deviceOrientation;

    double rotation = 0;
    switch (currentOrientation) {
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationUnknown:
            return;
        case UIDeviceOrientationPortrait:
            rotation = 0;
            lastOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            rotation = -M_PI;
            lastOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIDeviceOrientationLandscapeLeft:
            rotation = M_PI_2;
            lastOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationLandscapeRight:
            lastOrientation = AVCaptureVideoOrientationLandscapeRight;
            rotation = -M_PI_2;
            break;
    }
    
    CGAffineTransform transform = CGAffineTransformMakeRotation(rotation);
    [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.flipButton setTransform:transform];
        [self.flashButton setTransform:transform];
        [self.hubButton setTransform:transform];
        [self.privateViewButton setTransform:transform];
        [self.privateViewCountLabel setTransform:transform];
    } completion:nil];

}


- (BOOL)prefersStatusBarHidden {
    return YES;
}


#pragma mark - VYBAppDelegateNotification

- (void)remoteNotificationReceived:(id)sender {
    if ([[VYBUserStore sharedStore] newPrivateVybeCount] > 0) {
        [self.privateViewButton setSelected:YES];
        [self.privateViewCountLabel setText:[NSString stringWithFormat:@"%d", (int)[[VYBUserStore sharedStore] newPrivateVybeCount]]];
    }
}

- (void)applicationDidBecomeActiveNotificationReceived:(id)sender {    
    if ( [[PFUser currentUser] objectForKey:@"tribe"] ) {
        PFObject *myTribe = [[PFUser currentUser] objectForKey:@"tribe"];
        [myTribe fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error) {
                PFRelation *members = [object relationForKey:kVYBTribeMembersKey];
                PFQuery *countQuery = [PFQuery queryWithClassName:kVYBVybeClassKey];
                [countQuery whereKey:kVYBVybeUserKey matchesQuery:[members query]];
                [countQuery whereKey:kVYBVybeUserKey notEqualTo:[PFUser currentUser]];
                [countQuery whereKey:kVYBVybeTimestampKey greaterThan:[[VYBUserStore sharedStore] lastWatchedVybeTimeStamp]];
                [countQuery whereKey:kVYBVybeTypePublicKey equalTo:[NSNumber numberWithBool:NO]];
                [countQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                    if (!error) {
                        if (number > 0) {
                            [self.privateViewButton setSelected:YES];
                            [self.privateViewCountLabel setText:[NSString stringWithFormat:@"%d", number]];
                            [[VYBUserStore sharedStore] setNewPrivateVybeCount:number];
                        }
                    }
                }];
            }
        }];
    }
}

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
    self.privateViewButton.hidden = status;
    self.privateViewCountLabel.hidden = status;
    self.hubButton.hidden = status;
    flipButton.hidden = status;
    flashButton.hidden = status || isFrontCamera;
}

- (void)privateViewButtonPressed:(id)sender {
    VYBAppDelegate *appDel = (VYBAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDel moveToPage:VYBActivityPageIndex];
}

- (void)hubButtonPressed:(id)sender {
    VYBAppDelegate *appDel = (VYBAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDel moveToPage:VYBHubPageIndex];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@"[Capture] Memory Warning");
    dispatch_async([self sessionQueue], ^{
		[[self session] stopRunning];
        
		[[NSNotificationCenter defaultCenter] removeObserver:[self runtimeErrorHandlingObserver]];
		
		[self removeObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" context:SessionRunningAndDeviceAuthorizedContext];
	});

}



@end
