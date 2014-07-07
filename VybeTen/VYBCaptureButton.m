//
//  VYBCaptureButton.m
//  VybeTen
//
//  Created by jinsuk on 7/6/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBCaptureButton.h"

@implementation VYBCaptureButton {
    CGPoint startLocation;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.center = CGPointMake(0, 0);
        self.backgroundColor = [UIColor redColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    UIBezierPath *circlePath = [UIBezierPath bezierPath];
    [circlePath addArcWithCenter:self.center radius:35.0 startAngle:0.0 endAngle:2.0 * M_PI clockwise:NO];
    [[UIColor greenColor] setFill];
    [circlePath fill];
    CGContextFillPath(ctx);
}


@end
