//
//  VYBCaptureButton.m
//  VybeTen
//
//  Created by jinsuk on 7/6/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBCaptureButton.h"

@implementation VYBCaptureButton {
    double minRadius;
    double maxRadius;
    double lineWidth;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.center = CGPointMake(0, 0);
        self.backgroundColor = [UIColor clearColor];
        self.minPercentage = 0.0;
        self.maxPercentage = 0.0;
        
        //minRadius = 40.0;
        maxRadius = 45.0;
        lineWidth = 30.0;
    }
    return self;
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    self.passedMin = NO;
    self.minPercentage = 0.0;
    self.maxPercentage = 0.0;
}

- (void)drawRect:(CGRect)rect
{
    if (!self.passedMin) {
        CGMutablePathRef arc = CGPathCreateMutable();
        CGPathMoveToPoint(arc, NULL, rect.size.width / 2, rect.size.height / 2 - maxRadius);
        CGPathAddArc(arc, NULL, rect.size.width / 2, rect.size.height / 2, maxRadius, -M_PI_2, -M_PI_2 + self.minPercentage * 4 * M_PI_2, NO);
        CGPathRef strokedArc = CGPathCreateCopyByStrokingPath(arc, NULL, lineWidth, kCGLineCapButt, kCGLineJoinMiter, 10);
        
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextAddPath(ctx, strokedArc);
        CGContextSetFillColorWithColor(ctx, [UIColor redColor].CGColor);
        CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
        CGContextDrawPath(ctx, kCGPathFillStroke);
    }
    else {
        CGMutablePathRef arc = CGPathCreateMutable();
        CGPathMoveToPoint(arc, NULL, rect.size.width / 2, rect.size.height / 2 - maxRadius);
        CGPathAddArc(arc, NULL, rect.size.width / 2, rect.size.height / 2, maxRadius, -M_PI_2, 3 * M_PI_2, NO);
        CGPathRef strokedArc = CGPathCreateCopyByStrokingPath(arc, NULL, lineWidth, kCGLineCapButt, kCGLineJoinMiter, 10);
    
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextAddPath(ctx, strokedArc);
        CGContextSetFillColorWithColor(ctx, [UIColor redColor].CGColor);
        CGContextDrawPath(ctx, kCGPathFill);
        
        arc = CGPathCreateMutable();
        CGPathMoveToPoint(arc, NULL, rect.size.width / 2, rect.size.height / 2 - maxRadius);
        if (self.maxPercentage >= 1.0) {
            CGPathAddArc(arc, NULL, rect.size.width / 2, rect.size.height / 2,
                         maxRadius, -M_PI_2,  3 * M_PI_2, NO);
        }else {
            CGPathAddArc(arc, NULL, rect.size.width / 2, rect.size.height / 2,
                         maxRadius, -M_PI_2,  -M_PI_2 + self.maxPercentage * 4 * M_PI_2, NO);
        }
        strokedArc = CGPathCreateCopyByStrokingPath(arc, NULL, lineWidth, kCGLineCapButt, kCGLineJoinMiter, 10);
        CGContextAddPath(ctx, strokedArc);
        CGContextSetFillColorWithColor(ctx, [UIColor greenColor].CGColor);
        CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
        CGContextDrawPath(ctx, kCGPathFillStroke);
    }
    
}


@end
