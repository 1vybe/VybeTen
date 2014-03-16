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
    IBOutlet UIButton *flipButton;
    IBOutlet UIButton *menuButton;
    IBOutlet UILabel *timerLabel;
    NSString *adId;
}

- (void)setSession:(AVCaptureSession *)s withVideoInput:(AVCaptureDeviceInput *)vidInput withMovieFileOutput:(AVCaptureMovieFileOutput *)movieOutput;
- (void)startRecording;
- (IBAction)flipCamera:(id)sender;
- (IBAction)goToMenu:(id)sender;
- (AVCaptureDeviceInput *)frontCameraInput;
- (AVCaptureDeviceInput *)backCameraInput;

@end
