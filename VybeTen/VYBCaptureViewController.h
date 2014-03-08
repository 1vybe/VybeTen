//
//  VYBCaptureViewController.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 21..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <AWSS3/AWSS3.h>

@interface VYBCaptureViewController : UIViewController <AVCaptureFileOutputRecordingDelegate, AmazonServiceRequestDelegate> {
    IBOutlet UIButton *flipButton;
    IBOutlet UIButton *menuButton;
    IBOutlet UILabel *timerLabel;
}
@property (nonatomic) AmazonS3Client *s3;

- (void)setSession:(AVCaptureSession *)s withVideoInput:(AVCaptureDeviceInput *)vidInput withMovieFileOutput:(AVCaptureMovieFileOutput *)movieOutput;
- (void)startRecording;
- (IBAction)flipCamera:(id)sender;
- (IBAction)goToMenu:(id)sender;
- (AVCaptureDeviceInput *)frontCameraInput;
- (AVCaptureDeviceInput *)backCameraInput;


@end
