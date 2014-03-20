//
//  VYBCaptureProgressView.m
//  VybeTen
//
//  Created by jinsuk on 3/20/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBCaptureProgressView.h"

@implementation VYBCaptureProgressView {
    float width;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
        width = 0;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(context, 2.0);
    CGContextMoveToPoint(context, 0, 5.0);
    CGContextAddLineToPoint(context, width, 5.0);
    if (width > 0) {
        CGContextAddArc(context, width, 5.0, 2.0, 0, M_PI * 2, YES);
        CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    }
    CGContextDrawPath(context, kCGPathFillStroke);
}

- (void)incrementBar {
    width = width + self.bounds.size.width/(7*100);
    [self setNeedsDisplay];
}

- (void)resetBar {
    width = 0;
    [self setNeedsDisplay];
}


@end
