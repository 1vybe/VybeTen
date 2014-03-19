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

@interface VYBCaptureViewController : UIViewController <AVCaptureFileOutputRecordingDelegate> {
    NSString *adId;
}
@property (nonatomic) UILabel *labelTimer;
@property (nonatomic) UIButton *buttonFlip;
@property (nonatomic) UIButton *buttonMenu;
- (void)setSession:(AVCaptureSession *)s withVideoInput:(AVCaptureDeviceInput *)vidInput withMovieFileOutput:(AVCaptureMovieFileOutput *)movieOutput;
- (void)startRecording;
- (AVCaptureDeviceInput *)frontCameraInput;
- (AVCaptureDeviceInput *)backCameraInput;

@end
