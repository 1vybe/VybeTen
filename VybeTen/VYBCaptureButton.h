//
//  VYBCaptureButton.h
//  VybeTen
//
//  Created by jinsuk on 7/6/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface VYBCaptureButton : UIView
@property (nonatomic) CGPoint center;
@property (nonatomic) BOOL passedMin;
@property (nonatomic) BOOL passedMax;
@property (nonatomic) double minPercentage;
@property (nonatomic) double maxPercentage;

- (void)didStartRecording;
- (void)didStopRecording;
//@property (nonatomic) CGPoint startLocation;
@end
