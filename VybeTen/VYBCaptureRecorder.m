//
//  VYBCaptureRecorder.m
//  VybeTen
//
//  Created by jinsuk on 10/9/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "VYBCaptureRecorder.h"
#import "VYBUtility.h"

#import "VybeTen-Swift.h"

typedef NS_ENUM (NSInteger,VYBRecorderStatus) {
    VYBRecorderStatusIdle = 0,
    //VYBRecorderStatusStartingRecording,
    VYBRecorderStatusRecording,
    VYBRecorderStatusStoppingRecording,
    //VYBRecorderStatusRecordingFinished,
    //VYBRecorderStatusRecordingFailed,
};

@implementation VYBCaptureRecorder {
    id<VYBCaptureRecorderDelegate> _delegate;
    dispatch_queue_t _delegateCallbackQueue;
    
    AVAssetWriter *_assetWriter;
    dispatch_queue_t _assetWriterQueue;
    AVAssetWriterInput *_videoWriterInput;
    AVAssetWriterInput *_audioWriterInput;
    BOOL _sessionStarted;
    
    VYBRecorderStatus _status;
}

- (void)dealloc {
    
}

- (id)init {
    self = [super init];
    if (self) {
        _assetWriterQueue = dispatch_queue_create("recorder asset writing queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)setDelegate:(id<VYBCaptureRecorderDelegate>)delegate callbackQueue:(dispatch_queue_t)callbackQ {
    @synchronized (self) {
        _delegate = delegate;
        _delegateCallbackQueue = callbackQ;
    }
}

- (void)prepareRecordingWithAudioTrackDescription:(CMFormatDescriptionRef)audioDescription
                          videoTrackDescription:(CMFormatDescriptionRef)videoDescription
                                 videoTransform:(CGAffineTransform)transform {
    @synchronized (self) {
        if (_status != VYBRecorderStatusIdle) {
			@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Recorder is already preparing" userInfo:nil];
            return;
        }
    }
    
    //CFRetain(videoDescription);
    //CFRetain(audioDescription);
    
    // writer setup queue
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSError *error = nil;
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:[[[MyVybeStore sharedInstance] currVybe] videoFilePath]];
        _assetWriter = [[AVAssetWriter alloc] initWithURL:outputURL fileType:AVFileTypeMPEG4 error:&error];
        NSParameterAssert(_assetWriter);
        
        // Add video input
        NSDictionary *videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [NSNumber numberWithDouble:700.0*1024.0], AVVideoAverageBitRateKey,
                                               nil ];
        NSNumber *width = [NSNumber numberWithInt:270];
        NSNumber *height = [NSNumber numberWithInt:480];
        NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                       AVVideoCodecH264, AVVideoCodecKey,
                                       width, AVVideoWidthKey,
                                       height, AVVideoHeightKey,
                                       videoCompressionProps, AVVideoCompressionPropertiesKey,
                                       nil];
        _videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
        NSParameterAssert(_videoWriterInput);
        _videoWriterInput.expectsMediaDataInRealTime = YES;
        if ( [_assetWriter canAddInput:_videoWriterInput] ) {
            [_assetWriter addInput:_videoWriterInput];
        }
        //NOTE: When writing a file by AVAssetWriter, we need to change its input's transform to set video orientation (not by setting videoOrientation of AVCaptureConnection
        _videoWriterInput.transform = transform;
        
        // Release
        //CFRelease(videoDescription);
        
        // Add the audio input
        AudioChannelLayout acl;
        bzero( &acl, sizeof(acl));
        acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
        
        NSDictionary* audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [ NSNumber numberWithInt: kAudioFormatMPEG4AAC ], AVFormatIDKey,
                                   [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
                                   [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
                                   [ NSNumber numberWithInt: 256000 ], AVEncoderBitRateKey,
                                   [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                                   nil];

        _audioWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
        _audioWriterInput.expectsMediaDataInRealTime = YES;
        NSParameterAssert(_audioWriterInput);
        if ( [_assetWriter canAddInput:_audioWriterInput] ) {
            [_assetWriter addInput:_audioWriterInput];
        }
        
        //CFRelease(audioDescription);
        
        BOOL success = [_assetWriter startWriting];
        
        @synchronized (self) {
            if (success && !error) {
                _status = VYBRecorderStatusRecording;
                dispatch_async(_delegateCallbackQueue, ^{
                    [_delegate captureRecorderDidStartRecording:self];
                });
            } else {
                //_status = VYBRecorderStatusRecordingFailed;
                dispatch_async(_delegateCallbackQueue, ^{
                    [_delegate captureRecorder:self didFailWithError:error];
                });
            }
        }
    });
}

- (void)appendVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    [self appendSampleBuffer:sampleBuffer withMediaType:AVMediaTypeVideo];
}

- (void)appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    [self appendSampleBuffer:sampleBuffer withMediaType:AVMediaTypeAudio];
}

- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer withMediaType:(NSString *)mediaType {
    if (!sampleBuffer) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Cannot write nil sample buffer" userInfo:nil];
        return;
    }
    
    @synchronized (self) {
        if (_status < VYBRecorderStatusRecording) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Not ready to record yet" userInfo:nil];
            return;
        }
    }
    
    CFRetain(sampleBuffer);
    dispatch_async(_assetWriterQueue, ^{
        @synchronized (self) {
            if (_status > VYBRecorderStatusRecording) {
                CFRelease(sampleBuffer);
                return;
            }
            
            if (!_sessionStarted) {
                [_assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                _sessionStarted = YES;
            }
            
            AVAssetWriterInput *writerInput = ( [mediaType isEqualToString:AVMediaTypeVideo] ) ? _videoWriterInput : _audioWriterInput;
            if ( writerInput.readyForMoreMediaData ) {
                BOOL success = [writerInput appendSampleBuffer:sampleBuffer];
                if (!success) {
                    NSError *error = _assetWriter.error;
                    @synchronized (self) {
                        dispatch_async(_delegateCallbackQueue, ^{
                            [_delegate captureRecorder:self didFailWithError:error];
                        });
                    }
                }
            } else {
                // writer input is not ready for media data. drop the sample buffer
            }
            CFRelease(sampleBuffer);
        }
    });
}

- (void)stopRecording {
    @synchronized (self) {
        if (_status != VYBRecorderStatusRecording) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"recorder must be recording before stopping" userInfo:nil];
        }
        
        _status = VYBRecorderStatusStoppingRecording;
        dispatch_async(_assetWriterQueue, ^{
            [_assetWriter finishWritingWithCompletionHandler:^{
                NSError *error = _assetWriter.error;
                dispatch_async(_delegateCallbackQueue, ^{
                    if (error) {
                        [_delegate captureRecorder:self didFailWithError:error];
                    } else {
                        [_delegate captureRecorderDidFinishRecording:self];
                    }
                });

            }];
        });
    }
}

- (void)cleanUpAssetWriter {
    
}

@end
