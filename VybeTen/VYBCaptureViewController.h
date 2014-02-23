//
//  VYBCaptureViewController.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 21..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface VYBCaptureViewController : UIViewController <AVCaptureFileOutputRecordingDelegate>

- (IBAction)startRecording:(id)sender;
- 

@end
