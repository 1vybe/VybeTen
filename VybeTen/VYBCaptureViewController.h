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

@interface VYBCaptureViewController : GAITrackedViewController <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) IBOutlet UIButton *flipButton;
@property (nonatomic, strong) IBOutlet UIButton *flashButton;
@property (nonatomic, strong) IBOutlet UIButton *hubButton;
@property (nonatomic, strong) IBOutlet UIButton *activityButton;
@property (nonatomic, strong) IBOutlet UILabel *activityCountLabel;

- (IBAction)hubButtonPressed:(id)sender;
- (IBAction)activityButtonPressed:(id)sender;
- (IBAction)flipButtonPressed:(id)sender;
- (IBAction)flashButtonPressed:(id)sender;
//@property (nonatomic) UIButton *mapViewButton;
@property (nonatomic, strong) VYBCaptureButton *captureButton;

@end