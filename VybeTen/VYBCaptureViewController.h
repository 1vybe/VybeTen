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

#define ACCESS_KEY_ID   @"AKIAJVN4HPJ6VBOKP7XA"
#define SECRET_KEY      @"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"

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
