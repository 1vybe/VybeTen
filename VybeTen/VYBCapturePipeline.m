//
//  VYBCapturePipeline.m
//  VybeTen
//
//  Created by jinsuk on 10/7/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//


#import "VYBCapturePipeline.h"
#import "VYBCaptureRecorder.h"
#import "VYBUtility.h"

typedef NS_ENUM (NSInteger, VYBRecorderRecordingStatus) {
  VYBRecorderRecordingStatusIdle = 0,
  VYBRecorderRecordingStatusStartingRecording,
  VYBRecorderRecordingStatusRecording,
  VYBRecorderRecordingStatusStoppingRecording,
};

@interface VYBCapturePipeline ()  <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, VYBCaptureRecorderDelegate>

@property(nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef videoFormatDescription;
@property(nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef audioFormatDescription;

@end

@implementation VYBCapturePipeline {
  id<VYBCapturePipelineDelegate> _delegate;
  dispatch_queue_t _delegateCallbackQueue;
  
  AVCaptureSession *_session;
  dispatch_queue_t _sessionQueue;
  BOOL _sessionRunning;
  
  AVCaptureDeviceInput *_videoDeviceInput;
  AVCaptureVideoDataOutput *_videoDataOutput;
  
  AVCaptureConnection *_videoConnection;
  AVCaptureConnection *_audioConnection;

  dispatch_queue_t _videoDataOutputQueue;
  AVCaptureVideoOrientation _videoOrientation;
  UIBackgroundTaskIdentifier _pipelineBackgroundTask;

  BOOL _startsSessionWhenEnteredForeground;
  
  VYBCaptureRecorder *_recorder;
  VYBRecorderRecordingStatus _recordingStatus;
}

- (void)dealloc {
    
}

- (id)init {
  self = [super init];
  if (self) {
    _sessionQueue = dispatch_queue_create("capture session queue", DISPATCH_QUEUE_SERIAL);

    _videoDataOutputQueue = dispatch_queue_create("video data output queue", DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(_videoDataOutputQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
    
    self.recordingOrientation = AVCaptureVideoOrientationPortrait;
    
    _pipelineBackgroundTask = UIBackgroundTaskInvalid;
  }
  
  return self;
}

#pragma mark - Session

- (void)setDelegate:(id<VYBCapturePipelineDelegate>)delegate callbackQueue:(dispatch_queue_t)callbackQ {
  @synchronized (self) {
      _delegate = delegate;
      _delegateCallbackQueue = callbackQ;
  }
}

- (void)startRunning {
  dispatch_async(_sessionQueue, ^{
    [self setUpSession];
    
    [_session startRunning];
    _sessionRunning = YES;
  });
}

- (void)setUpSession {
  if (_session)
      return;
  
  _session = [[AVCaptureSession alloc] init];
  //TODO: for old devices like iphone4 sesison preset should be lower
  [_session setSessionPreset:AVCaptureSessionPreset1280x720];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionNotificationReceived:) name:nil object:_session];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForegroundNotificationReceived:) name:UIApplicationWillEnterForegroundNotification object:[UIApplication sharedApplication]];
  
  NSError *error = nil;
  [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeVideoRecording error:&error];
  [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
  
  // Adding audio device input to session
  AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
  AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
  if ([_session canAddInput:audioDeviceInput]) {
    [_session addInput:audioDeviceInput];
  }
  // Adding audio output to session
  AVCaptureAudioDataOutput *audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
  
  dispatch_queue_t audioOutputQueue = dispatch_queue_create("vybe audio data output queue", DISPATCH_QUEUE_SERIAL);
  [audioDataOutput setSampleBufferDelegate:self queue:audioOutputQueue];
  if ([_session canAddOutput:audioDataOutput]) {
    [_session addOutput:audioDataOutput];
  }
  _audioConnection = [audioDataOutput connectionWithMediaType:AVMediaTypeAudio];
  
  
  
  // Adding video device input to session
  AVCaptureDevice *videoDevice = [VYBCapturePipeline deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
  AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
  if ([_session canAddInput:videoDeviceInput]) {
    [_session addInput:videoDeviceInput];
  }
  _videoDeviceInput = videoDeviceInput;
  // Adding video output to session
  _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
  _videoDataOutput.alwaysDiscardsLateVideoFrames = NO;
  _videoDataOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
  [_videoDataOutput setSampleBufferDelegate:self queue:_videoDataOutputQueue];
  [_videoDataOutput setAlwaysDiscardsLateVideoFrames:NO];
  if ([_session canAddOutput:_videoDataOutput]) {
    [_session addOutput:_videoDataOutput];
  }
  _videoConnection = [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
  [_videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];

  return;
}

- (void)stopRunning {
  dispatch_async(_sessionQueue, ^{
    _sessionRunning = NO;
    
    [self stopRecording];
    
    [_session stopRunning];
    
    [self sessionDidStopRunning];
    
    [self cleanUpSession];
  });
}

- (void)sessionDidStopRunning {
  [self stopRecording];
  [self cleanUpPipeline];
}

- (void)cleanUpSession {
  if (_session) {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:_session];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:[UIApplication sharedApplication]];
    
    _session = nil;
  }
}

#pragma mark - Pipeline

- (void)setUpPipelineWithDescription:(CMFormatDescriptionRef)description {
  self.videoFormatDescription = description;
  
  [self videoPipelineWillStartRunning];
  
  dispatch_async(_delegateCallbackQueue, ^{
    [_delegate capturePipeline:self sessionPreviewReadyForDisplay:_session];
  });
}

- (void)cleanUpPipeline {
  // Session is already stopped so we know there is no more buffer coming in through videoDataOutput
  dispatch_async(_videoDataOutputQueue, ^{
    if ( !_videoFormatDescription )
      return;
    
    _videoFormatDescription = nil;
    
    [self videoPipelineDidFinishRunning];
  });
}

- (void)videoPipelineWillStartRunning {
  NSAssert(_pipelineBackgroundTask == UIBackgroundTaskInvalid, @"pipeline background task should NOT be active before the pipeline starts running");
  _pipelineBackgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
    NSLog(@"pipeline background task expired");
  }];
}

- (void)videoPipelineDidFinishRunning {
  NSAssert(_pipelineBackgroundTask != UIBackgroundTaskInvalid, @"pipeline background task should be active when the pipeline finishes running");
  
  [[UIApplication sharedApplication] endBackgroundTask:_pipelineBackgroundTask];
  _pipelineBackgroundTask = UIBackgroundTaskInvalid;
}


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
  
  CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
  
  if (connection == _videoConnection) {
    if (self.videoFormatDescription == nil) {
      [self setUpPipelineWithDescription:formatDescription];
    } else {
      @synchronized (self) {
        if (_recordingStatus == VYBRecorderRecordingStatusRecording) {
          [_recorder appendVideoSampleBuffer:sampleBuffer];
        }
      }
    }
  }
  
  else if (connection == _audioConnection) {
    if (self.audioFormatDescription == nil) {
      self.audioFormatDescription = formatDescription;
    } else {
      @synchronized (self) {
        if (_recordingStatus == VYBRecorderRecordingStatusRecording) {
          [_recorder appendAudioSampleBuffer:sampleBuffer];
        }
      }
    }
  }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
}


#pragma mark - Notifications

- (void)sessionNotificationReceived:(NSNotification *)notification {
  dispatch_async(_sessionQueue, ^{
    // session is interrupted when entered background and resumes (interruption ends) when entered foreground
    if ( [[notification name] isEqualToString:AVCaptureSessionWasInterruptedNotification] ) {
      [self sessionDidStopRunning];
      NSLog(@"session interrupted");
    }
    else if ( [[notification name] isEqualToString:AVCaptureSessionInterruptionEndedNotification] ) {
      NSLog(@"session interruption ended");
    }
    else if ( [[notification name] isEqualToString:AVCaptureSessionRuntimeErrorNotification] ) {
      [self sessionDidStopRunning];
      NSLog(@"session runtime error");
      
      NSError *error = [[notification userInfo] objectForKey:AVCaptureSessionErrorKey];
      switch (error.code) {
        case AVErrorDeviceIsNotAvailableInBackground:
          if (_sessionRunning) {
            _startsSessionWhenEnteredForeground = YES;
            NSLog(@"session will resume when entered foreground");
          }
          break;
        case AVErrorMediaServicesWereReset:
          [self handleRecoverableSessionError:error];
          break;
        default:
          [self handleNonRecoverableSessionError:error];
          break;
      }
    }
    else if ( [[notification name] isEqualToString:AVCaptureSessionDidStartRunningNotification] ) {
      NSLog(@"session started");
    }
    else if ( [[notification name] isEqualToString:AVCaptureSessionDidStopRunningNotification] ) {
      NSLog(@"session stopped");
    }
  });
}

- (void)applicationWillEnterForegroundNotificationReceived:(id)sender {
  dispatch_async(_sessionQueue, ^{
    if (_startsSessionWhenEnteredForeground) {
      if (_sessionRunning)
        [_session startRunning];
      
      _startsSessionWhenEnteredForeground = NO;
    }
  });
}


#pragma mark - Recording

- (void)startRecording {
  @synchronized (self) {
    if (_recordingStatus != VYBRecorderRecordingStatusIdle) {
      @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"WTF Already recording" userInfo:nil];
      return;
    }
    
    dispatch_async(_sessionQueue, ^{
      [self setTorchMode:([self isFlashOn]) ? AVCaptureTorchModeOn : AVCaptureTorchModeOff forDevice:[_videoDeviceInput device]];
    });
    _recordingStatus = VYBRecorderRecordingStatusStartingRecording;
    
    _recorder = [[VYBCaptureRecorder alloc] init];
    dispatch_queue_t recorderCallbackQueue = dispatch_queue_create("recorder callback queue", DISPATCH_QUEUE_SERIAL);
    [_recorder setDelegate:self callbackQueue:recorderCallbackQueue];
    
    [_recorder prepareRecordingWithAudioTrackDescription:self.audioFormatDescription
                                   videoTrackDescription:self.videoFormatDescription
                                          videoTransform:[VYBUtility getTransformFromOrientation:self.recordingOrientation]];
  }
}

- (void)stopRecording {
  @synchronized (self) {
    if (_recordingStatus != VYBRecorderRecordingStatusRecording) {
      return;
    }
    
    dispatch_async(_sessionQueue, ^{
      [self setTorchMode:AVCaptureTorchModeOff forDevice:[_videoDeviceInput device]];
    });
    
    _recordingStatus = VYBRecorderRecordingStatusStoppingRecording;
    dispatch_async(_delegateCallbackQueue, ^{
      [_delegate capturePipelineRecordingWillStop:self];
    });
    [_recorder stopRecording];
  }
}

#pragma mark - VYBCaptureRecorderDelegate

- (void)captureRecorderDidStartRecording:(VYBCaptureRecorder *)recorder {
  @synchronized (self) {
    if (_recordingStatus != VYBRecorderRecordingStatusStartingRecording) {
      @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"something occured during preparing recorder" userInfo:nil];
      return;
    }
    _recordingStatus = VYBRecorderRecordingStatusRecording;
    
    dispatch_async(_delegateCallbackQueue, ^{
      [_delegate capturePipelineRecordingDidStart:self];
    });
  }
}

- (void)captureRecorderDidFinishRecording:(VYBCaptureRecorder *)recorder {
  @synchronized (self) {
    if (_recordingStatus != VYBRecorderRecordingStatusStoppingRecording) {
      @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"something happened before finish recording" userInfo:nil];
    }
    _recordingStatus = VYBRecorderRecordingStatusIdle;
    
    dispatch_async(_delegateCallbackQueue, ^{
      [_delegate capturePipelineRecordingDidStop:self];
    });
  }
}

- (void)captureRecorder:(VYBCaptureRecorder *)recorder didFailWithError:(NSError *)error {
  dispatch_async(_delegateCallbackQueue, ^{
    [_delegate capturePipeline:self recordingDidFailWithError:error];
  });
}

#pragma mark - Error handling

- (void)handleRecoverableSessionError:(NSError *)error {
  if (_sessionRunning)
    [_session startRunning];
}

- (void)handleNonRecoverableSessionError:(NSError *)error {
  _sessionRunning = NO;
  [self cleanUpSession];
  
  if (_delegate) {
    dispatch_async(_delegateCallbackQueue, ^{
      [_delegate capturePipeline:self didStopWithError:error];
    });
  }
}

- (void)flipCameraWithCompletion:(void (^)())completionBlock {
  dispatch_async(_sessionQueue, ^{
    AVCaptureDevicePosition currentPosition = [[_videoDeviceInput device] position];
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
    
    AVCaptureDevice *videoDevice = [VYBCapturePipeline deviceWithMediaType:AVMediaTypeVideo preferringPosition:prefferedPosition];
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
    [_session beginConfiguration];
    [_session removeInput:_videoDeviceInput];
    if ( [_session canAddInput:videoDeviceInput] ) {
      [_session addInput:videoDeviceInput];
    }
    _videoDeviceInput = videoDeviceInput;
    _videoConnection = [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    // Video should be mirrored if coming from the front camera
    [_videoConnection setVideoMirrored:[videoDevice position] == AVCaptureDevicePositionFront];
    // Re-fixing videoOutput connection orientation to portrait because adding a new videoInput the orientation to landscape by default
    [_videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    [_session commitConfiguration];
    if (completionBlock)
      completionBlock();
  });
}

#pragma mark - ()

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

- (void)setTorchMode:(AVCaptureTorchMode)torchMode forDevice:(AVCaptureDevice *)device
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

@end
