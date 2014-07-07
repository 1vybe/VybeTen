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

@class VYBTribe;
@protocol VYBCaptureViewControllerDelegate;
@interface VYBCaptureViewController : UIViewController <AVCaptureFileOutputRecordingDelegate> {
    NSString *adId;
}

@property (nonatomic) id<VYBCaptureViewControllerDelegate> delegate;
@property (nonatomic) UIButton *recordButton;
@property (nonatomic) UILabel *countLabel;
@property (nonatomic) UIButton *flipButton;
@property (nonatomic) UIButton *flashButton;
@property (nonatomic) UILabel *flashLabel;
@property (nonatomic, strong) VYBCaptureButton *captureButton;

//- (void)startRecording;
//- (AVCaptureDeviceInput *)frontCameraInput;
//- (AVCaptureDeviceInput *)backCameraInput;

@end
@protocol VYBCaptureViewControllerDelegate <NSObject>

@optional
- (void)capturedVybe:(PFObject *)aVybe;
@end
