//
//  VYBCaptureRecorder.h
//  VybeTen
//
//  Created by jinsuk on 10/9/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol VYBCaptureRecorderDelegate;

@interface VYBCaptureRecorder : NSObject
- (void)setDelegate:(id<VYBCaptureRecorderDelegate>)delegate callbackQueue:(dispatch_queue_t)callbackQ;
- (void)prepareRecordingWithAudioTrackDescription:(CMFormatDescriptionRef)audioDescription
                          videoTrackDescription:(CMFormatDescriptionRef)videoDescription videoTransform:(CGAffineTransform)transform;
- (void)stopRecording;
- (void)appendVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer;


@end

@protocol VYBCaptureRecorderDelegate <NSObject>
@required
- (void)captureRecorderDidStartRecording:(VYBCaptureRecorder *)recorder;
- (void)captureRecorder:(VYBCaptureRecorder *)recorder didFailWithError:(NSError *)error;
- (void)captureRecorderDidFinishRecording:(VYBCaptureRecorder *)recorder;
@end
