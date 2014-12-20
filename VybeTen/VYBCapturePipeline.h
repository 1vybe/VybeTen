//
//  VYBCapturePipeline.h
//  VybeTen
//
//  Created by jinsuk on 10/7/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol VYBCapturePipelineDelegate;
@interface VYBCapturePipeline : NSObject
@property (nonatomic) AVCaptureVideoOrientation recordingOrientation;
- (void)setDelegate:(id<VYBCapturePipelineDelegate>)delegate callbackQueue:(dispatch_queue_t)callbackQ;
- (void)startRunning;
- (void)stopRunning;
- (void)startRecording;
- (void)stopRecording;

- (void)setFocusPoint:(CGPoint)point;
- (void)flipCameraWithCompletion:(void (^)())completionBlock;
@property (nonatomic, getter=isFlashOn) BOOL flashOn;
@end

@protocol VYBCapturePipelineDelegate <NSObject>
@required
// Session
- (void)capturePipeline:(VYBCapturePipeline *)pipeline sessionPreviewReadyForDisplay:(AVCaptureSession *)session;
- (void)capturePipeline:(VYBCapturePipeline *)pipeline didStopWithError:(NSError *)error;

// Recording
- (void)capturePipelineRecordingDidStart:(VYBCapturePipeline *)pipeline;
- (void)capturePipelineRecordingWillStop:(VYBCapturePipeline *)pipeline;
- (void)capturePipelineRecordingDidStop:(VYBCapturePipeline *)pipeline;
- (void)capturePipeline:(VYBCapturePipeline *)pipeline recordingDidFailWithError:(NSError *)error;
@end
