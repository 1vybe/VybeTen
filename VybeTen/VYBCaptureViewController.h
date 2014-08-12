//
//  VYBCaptureViewController.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 21..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "VYBCaptureButton.h"
#import "GAITrackedViewController.h"


@class VYBTribe;
@class VYBLabel;

@interface VYBCaptureViewController : GAITrackedViewController <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic) UIButton *flipButton;
@property (nonatomic) UIButton *flashButton;
@property (nonatomic) UIButton *publicViewButton;
@property (nonatomic) UIButton *privateViewButton;
@property (nonatomic) VYBLabel *privateViewCountLabel;
//@property (nonatomic) UIButton *mapViewButton;
@property (nonatomic, strong) VYBCaptureButton *captureButton;

@end