//
//  VYBCameraView.m
//  VybeTen
//
//  Created by jinsuk on 7/14/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBCameraView.h"
#import <AVFoundation/AVFoundation.h>

@implementation VYBCameraView

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)session {
    return [(AVCaptureVideoPreviewLayer *)[self layer] session];
}

- (void)setSession:(AVCaptureSession *)session {
    [(AVCaptureVideoPreviewLayer *)[self layer] setSession:session];
}

@end
