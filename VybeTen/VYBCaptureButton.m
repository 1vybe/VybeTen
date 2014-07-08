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
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    self.passedMin = NO;
    //NSLog(@"capturebutton moved to superview");
}

- (void)drawRect:(CGRect)rect
{
    CGRect innerCircle = CGRectMake(32, 32, 80, 80);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 2.0);
    CGContextSetStrokeColorWithColor(context,
                                     [UIColor redColor].CGColor);
    CGContextAddEllipseInRect(context, innerCircle);
    CGContextStrokePath(context);
    
    if (self.passedMin) {
        CGRect outterCircle = CGRectMake(2, 2, 140, 140);
        CGContextSetStrokeColorWithColor(context,
                                         [UIColor greenColor].CGColor);
        CGContextAddEllipseInRect(context, outterCircle);
        CGContextStrokePath(context);
    }
}


@end
