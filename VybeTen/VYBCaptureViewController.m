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
#import "VYBLabel.h"
#import "VYBCaptureViewController.h"
#import "VYBMenuViewController.h"
#import "VYBMyVybeStore.h"
#import "VYBConstants.h"
#import "VYBReplayViewController.h"
#import "VYBSyncTribeViewController.h"
#import "UINavigationController+Fade.h"
#import "JSBadgeView.h"
#import "VYBTribe.h"

@implementation VYBCaptureViewController {
    AVCaptureSession *session;
    AVCaptureDeviceInput *videoInput;
    AVCaptureMovieFileOutput *movieFileOutput;
   
    NSDate *startTime;
    NSTimer *recordingTimer;
    
    VYBVybe *newVybe;
    
    BOOL recording;
    BOOL frontCamera;
    
    UIImageView *overlayView;
    JSBadgeView *badgeView;
    
    CLLocationManager *locationManager;
}

@synthesize syncButton, syncLabel, recordButton, countLabel, flipButton, menuButton, flashButton, flashLabel, notificationButton;
@synthesize defaultSync;
@synthesize transitionController;

static void * XXContext = &XXContext;

- (id)init {
    self = [super init];
    if (self) {
        locationManager = [[CLLocationManager alloc] init];
        //NSLog(@"Let's invoke the location manager");
        [locationManager startUpdatingLocation];
        [locationManager stopUpdatingLocation];
    }
    return self;
}

- (void)loadView {
    // Retrieves this device's unique ID
    adId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    //NSLog(@"UserID:%@", adId);
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
    transitionController = [[TransitionDelegate alloc] init];
    
    // Overlay alertView will be displayed when a user entered in a portrait mode
    UIDevice *iphone = [UIDevice currentDevice];
    [iphone beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayOverlay:) name:UIDeviceOrientationDidChangeNotification object:iphone];
    
    recording = NO;
    frontCamera = NO;
    
    // Adding MENU button
    CGRect buttonFrame = CGRectMake(self.view.bounds.size.height - 50, 0, 50, 50);
    menuButton = [[UIButton alloc] initWithFrame:buttonFrame];
    UIImage *menuImage = [UIImage imageNamed:@"button_menu.png"];
    [menuButton setContentMode:UIViewContentModeCenter];
    [menuButton setImage:menuImage forState:UIControlStateNormal];
    [menuButton addTarget:self action:@selector(goToMenu:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:menuButton];
    
    // Adding SYNC button
    buttonFrame = CGRectMake(0, self.view.bounds.size.width - 50, 50, 50);
    syncButton = [[UIButton alloc] initWithFrame:buttonFrame];
    UIImage *syncNoneImg = [UIImage imageNamed:@"button_sync_none.png"];
    [syncButton setImage:syncNoneImg forState:UIControlStateNormal];
    [syncButton addTarget:self action:@selector(changeSync:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:syncButton];
    
    // Adding SYNC label
    buttonFrame = CGRectMake(50, self.view.bounds.size.width - 50, 150, 50);
    syncLabel = [[VYBLabel alloc] initWithFrame:buttonFrame];
    [syncLabel setTextColor:[UIColor whiteColor]];
    [syncLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20]];
    //[syncLabel setTextAlignment:NSTextAlignmentLeft];
    [self.view addSubview:syncLabel];
    if (defaultSync)
        [syncLabel setText:[defaultSync tribeName]];
    
    // Adding RECORD button
    buttonFrame = CGRectMake(self.view.bounds.size.height - 70, (self.view.bounds.size.width - 60)/2, 60, 60);
    recordButton = [[UIButton alloc] initWithFrame:buttonFrame];
    UIImage *captureButtonImg = [UIImage imageNamed:@"button_record.png"];
    [recordButton setBackgroundImage:captureButtonImg forState:UIControlStateNormal];
    //[recordButton.titleLabel setFont:[UIFont fontWithName:@"Montreal-Regular" size:24]];
    //[recordButton setTintColor:[UIColor whiteColor]];
    [recordButton addTarget:self action:@selector(startRecording) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:recordButton];
    // Adding COUNT label to RECORD button
    buttonFrame = CGRectMake(0, 0, 60, 60);
    countLabel = [[VYBLabel alloc] initWithFrame:buttonFrame];
    [countLabel setTextColor:[UIColor whiteColor]];
    [countLabel setTextAlignment:NSTextAlignmentCenter];
    [countLabel setFont:[UIFont fontWithName:@"Montreal-Regular" size:24.0f]];
    [countLabel setUserInteractionEnabled:NO];
    [recordButton addSubview:countLabel];
    
    // Adding NOTIFICATION button
    buttonFrame = CGRectMake(0, 0, 50, 50);
    notificationButton = [[UIButton alloc] initWithFrame:buttonFrame];
    UIImageView *notificationImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"button_notification.png"]];
    [notificationButton addSubview:notificationImgView];
    notificationImgView.center = notificationButton.center;
    [notificationButton addTarget:self action:@selector(notificationPressed:) forControlEvents:UIControlEventTouchUpInside];
    /* TODO: Uncomment this */
    //[self.view addSubview:notificationButton];
    [notificationImgView setUserInteractionEnabled:NO];
    badgeView = [[JSBadgeView alloc] initWithParentView:notificationImgView alignment:JSBadgeViewAlignmentTopRight];
    // Register this class as an observer for notification change
    [[VYBMyVybeStore sharedStore] addObserver:self forKeyPath:@"numVybes" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:XXContext];
    //adgeView.badgeText = @"3";
    
    // Adding FLIP button
    buttonFrame = CGRectMake((self.view.bounds.size.height - 120)/2, 0, 50, 50);
    flipButton = [[UIButton alloc] initWithFrame:buttonFrame];
    UIImage *flipImage = [UIImage imageNamed:@"button_flip.png"];
    [flipButton setContentMode:UIViewContentModeCenter];
    [flipButton setImage:flipImage forState:UIControlStateNormal];
    [flipButton addTarget:self action:@selector(flipCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:flipButton];
    
    // Adding FLASH button
    buttonFrame = CGRectMake((self.view.bounds.size.height-120)/2 + 50, 0, 70, 50);
    flashButton = [[UIButton alloc] initWithFrame:buttonFrame];
    UIImage *flashImage = [UIImage imageNamed:@"button_flash_on.png"];
    [flashButton setContentMode:UIViewContentModeLeft];
    [flashButton setImage:flashImage forState:UIControlStateNormal];
    [flashButton addTarget:self action:@selector(switchFlash:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:flashButton];
    
    // Adding FLASH label
    buttonFrame = CGRectMake(40, 0, 30, 50);
    flashLabel = [[VYBLabel alloc] initWithFrame:buttonFrame];
    [flashLabel setFont:[UIFont fontWithName:@"Montreal-Regular" size:14]];
    [flashLabel setTextAlignment:NSTextAlignmentLeft];
    [flashLabel setTextColor:[UIColor whiteColor]];
    [flashLabel setText:@"OFF"];
    [self.flashButton addSubview:flashLabel];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [self turnOffFlash];
}

- (void)viewWillAppear:(BOOL)animated {
     syncButton.hidden = recording; syncLabel.hidden = recording; flipButton.hidden = recording; menuButton.hidden = recording; notificationButton.hidden = recording; flashButton.hidden = (recording || frontCamera);
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
    NSString *secondsPassed = [NSString stringWithFormat:@"%d", secondsLeft];
    [countLabel setText:secondsPassed];
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
        if (defaultSync)
            [newVybe setTribeName:[defaultSync tribeName]];
        startTime = [newVybe timeStamp];
        
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:[newVybe videoPath]];
        [movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
        
        recordingTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timer:) userInfo:nil repeats:YES];
        // Change record button to act as a counter
        UIImage *recordButtonEmptyImg = [UIImage imageNamed:@"button_record_empty.png"];
        [recordButton setBackgroundImage:recordButtonEmptyImg forState:UIControlStateNormal];
        
        recording = YES; syncButton.hidden = recording; syncLabel.hidden = recording; flipButton.hidden = recording; menuButton.hidden = recording; notificationButton.hidden = recording; flashButton.hidden = recording;
    }
    
    /* Stop Recording */
    else {
        [movieFileOutput stopRecording];
    }
}

- (void)notificationPressed:(id)sender {
    NSLog(@"NOTI PRESED");
}

- (void)changeSync:(id)sender {
    VYBSyncTribeViewController *syncVC = [[VYBSyncTribeViewController alloc] init];
    [syncVC setCompletionBlock:^(VYBTribe *tribe){
        defaultSync = tribe;
        if (defaultSync) {
            UIImage *image = [UIImage imageNamed:@"button_sync.png"];
            [syncButton setImage:image forState:UIControlStateNormal];
            [syncLabel setText:[defaultSync tribeName]];
        }
    }];
    [self.navigationController pushFadeViewController:syncVC];
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
        flashButton.hidden = NO;
    } else {
        videoInput = [self frontCameraInput];
        flashButton.hidden = YES;
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
    menuVC.view.backgroundColor = [UIColor clearColor];
    menuVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    //[menuVC setTransitioningDelegate:transitionController];
    //menuVC.modalPresentationStyle = UIModalPresentationCurrentContext;
    //self.modalPresentationStyle = UIModalPresentationCurrentContext;
    [self.navigationController presentViewController:menuVC animated:YES completion:nil];
    
    syncButton.hidden = YES; syncLabel.hidden = YES; flipButton.hidden = YES; menuButton.hidden = YES; notificationButton.hidden = YES; flashButton.hidden = YES;
    
    //[self.navigationController pushFadeViewController:menuVC];
}

- (void)displayOverlay:(NSNotification *)note {
    UIDevice *device = [note object];
    if ( UIDeviceOrientationIsPortrait([device orientation]) ) {
        if (!overlayView) {
            UIWindow *window = self.view.window;
            overlayView = [[UIImageView alloc] initWithFrame:window.bounds];
            [overlayView setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.8f]];
            [overlayView setUserInteractionEnabled:YES];
            [overlayView setContentMode:UIViewContentModeCenter];
            [overlayView setImage:[UIImage imageNamed:@"screen_warning_rotate.png"]];
            [window addSubview:overlayView];
        }
    } else if ( UIDeviceOrientationIsLandscape([device orientation]) ) {
        [overlayView removeFromSuperview];
        overlayView = nil;
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
    // Reset record button image back to original
    [countLabel setText:@""];
    UIImage *recordButtonImg = [UIImage imageNamed:@"button_record.png"];
    [recordButton setBackgroundImage:recordButtonImg forState:UIControlStateNormal];
    [recordButton setTitle:@"" forState:UIControlStateNormal];
    
    recording = NO;
    newVybe = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == XXContext) {
        if ( [keyPath isEqualToString:@"numVybes"] ) {
            NSNumber *newCount = (NSNumber *)[change objectForKey:NSKeyValueChangeNewKey];
            NSString *count = [NSString stringWithFormat:@"%@", newCount];
            badgeView.badgeText = count;
        }
    }
    //[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
