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
@protocol VYBCaptureViewControllerDelegate;
@interface VYBCaptureViewController : GAITrackedViewController <AVCaptureFileOutputRecordingDelegate> {
    NSString *adId;
}

@property (nonatomic) id<VYBCaptureViewControllerDelegate> delegate;

@property (nonatomic) UIButton *flipButton;
@property (nonatomic) UIButton *flashButton;
@property (nonatomic) UIButton *viewButton;
@property (nonatomic) UIButton *modeToggleButton;
@property (nonatomic, strong) VYBCaptureButton *captureButton;

@end

@protocol VYBCaptureViewControllerDelegate <NSObject>
@optional
- (void)capturedVybe:(PFObject *)aVybe;
@end
