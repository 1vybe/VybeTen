//
//  VYBCaptureViewController.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 21..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "GAITrackedViewController.h"
#import "VYBCameraView.h"

@protocol VYBCapturePipelineDelegate;
@interface VYBCaptureViewController : UIViewController

@property (nonatomic, weak) IBOutlet VYBCameraView *cameraView;

@end