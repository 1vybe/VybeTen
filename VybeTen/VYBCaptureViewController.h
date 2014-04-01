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
@class VYBCaptureProgressView;

@interface VYBCaptureViewController : UIViewController <AVCaptureFileOutputRecordingDelegate> {
    NSString *adId;
}
@property (nonatomic) VYBCaptureProgressView *labelTimer;
@property (nonatomic) UIButton *buttonFlip;
@property (nonatomic) UIButton *buttonMenu;
@property (nonatomic) UIButton *buttonFlash;
- (void)setSession:(AVCaptureSession *)s withVideoInput:(AVCaptureDeviceInput *)vidInput withMovieFileOutput:(AVCaptureMovieFileOutput *)movieOutput;
- (void)startRecording;
- (AVCaptureDeviceInput *)frontCameraInput;
- (AVCaptureDeviceInput *)backCameraInput;

@end
