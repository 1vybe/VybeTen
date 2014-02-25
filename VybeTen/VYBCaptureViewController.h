//
//  VYBCaptureViewController.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 21..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface VYBCaptureViewController : UIViewController <AVCaptureFileOutputRecordingDelegate> {
    IBOutlet UIButton *flipButton;
    IBOutlet UIButton *menuButton;
    IBOutlet UILabel *timerLabel;
}

- (IBAction)flipCamera:(id)sender;
- (IBAction)startRecording:(id)sender;
- (AVCaptureDeviceInput *)frontCameraInput;
- (AVCaptureDeviceInput *)backCameraInput;


@end
