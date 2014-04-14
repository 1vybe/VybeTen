//
//  VYBCaptureViewController.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 21..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <AdSupport/ASIdentifierManager.h>
#import "TransitionDelegate.h"

@class VYBTribe;

@interface VYBCaptureViewController : UIViewController <AVCaptureFileOutputRecordingDelegate> {
    NSString *adId;
}
@property (nonatomic) UIButton *recordButton;
@property (nonatomic) UILabel *countLabel;
@property (nonatomic) UIButton *flipButton;
@property (nonatomic) UIButton *menuButton;
@property (nonatomic) UIButton *flashButton;
@property (nonatomic) UIButton *notificationButton;
@property (nonatomic) UIButton *syncButton;
@property (nonatomic) UILabel *syncLabel;
@property (nonatomic) UILabel *flashLabel;
@property (nonatomic) VYBTribe *defaultSync;
@property (nonatomic, strong) TransitionDelegate *transitionController;

- (void)setSession:(AVCaptureSession *)s withVideoInput:(AVCaptureDeviceInput *)vidInput withMovieFileOutput:(AVCaptureMovieFileOutput *)movieOutput;
- (void)startRecording;
- (AVCaptureDeviceInput *)frontCameraInput;
- (AVCaptureDeviceInput *)backCameraInput;

@end
