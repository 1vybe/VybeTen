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

@interface VYBCaptureViewController : GAITrackedViewController <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic) UIButton *flipButton;
@property (nonatomic) UIButton *flashButton;
@property (nonatomic) UIButton *privateViewButton;
@property (nonatomic) VYBLabel *privateCountLabel;
@property (nonatomic) UIButton *publicViewButton;
@property (nonatomic, strong) VYBCaptureButton *captureButton;

@end