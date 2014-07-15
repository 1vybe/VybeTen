//
//  VYBCameraView.h
//  VybeTen
//
//  Created by jinsuk on 7/14/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVCaptureSession;
@interface VYBCameraView : UIView

@property (nonatomic) AVCaptureSession *session;

@end
