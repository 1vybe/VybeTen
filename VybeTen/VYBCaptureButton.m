//
//  VYBCaptureButton.m
//  VybeTen
//
//  Created by jinsuk on 7/6/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBCaptureButton.h"

@implementation VYBCaptureButton {
    double smallRadius;
    double largeRaduis;
    double thinLineWidth;
    double thickLineWidth;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.center = CGPointMake(0, 0);
        self.backgroundColor = [UIColor clearColor];
        self.minPercentage = 0.0;
        self.maxPercentage = 0.0;
        
        smallRadius = 46.0;
        largeRaduis = 58.0;
        
        thinLineWidth = 6.0;
        thickLineWidth = 12.0;
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
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    // Draw white transparent inncer circle
    CGMutablePathRef arc = CGPathCreateMutable();
    CGRect inncerCircle = CGRectMake(rect.size.width/2 - smallRadius, rect.size.height/2 - smallRadius, smallRadius * 2, smallRadius * 2);
    CGContextAddEllipseInRect(ctx, inncerCircle);
    CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:1.0 alpha:0.5].CGColor);
    CGContextDrawPath(ctx, kCGPathFill);
    
    // black transparent outter arc
    arc = CGPathCreateMutable();
    CGPathMoveToPoint(arc, NULL, rect.size.width / 2, rect.size.height/2 - smallRadius - thickLineWidth/2);
    CGPathAddArc(arc, NULL, rect.size.width / 2, rect.size.height / 2, smallRadius + thickLineWidth/2, -M_PI_2, 3 * M_PI_2, NO);
    CGPathRef strokedArc = CGPathCreateCopyByStrokingPath(arc, NULL, thickLineWidth, kCGLineCapButt, kCGLineJoinMiter, 10);
    CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:0.0 alpha:0.5].CGColor);
    CGContextAddPath(ctx, strokedArc);
    CGContextDrawPath(ctx, kCGPathFill);
    
    // orange arc for minimum
    arc = CGPathCreateMutable();
    CGPathMoveToPoint(arc, NULL, rect.size.width / 2, rect.size.height / 2 - smallRadius - thinLineWidth/2);
    CGPathAddArc(arc, NULL, rect.size.width / 2, rect.size.height / 2, smallRadius + thinLineWidth/2, 3 * M_PI_2, 3 * M_PI_2 - self.minPercentage * 4 * M_PI_2, YES);
    strokedArc = CGPathCreateCopyByStrokingPath(arc, NULL, thinLineWidth, kCGLineCapButt, kCGLineJoinMiter, 10);
    CGContextAddPath(ctx, strokedArc);
    CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:243.0/255.0 green:122.0/255.0 blue:32.0/255.0 alpha:0.9].CGColor);
    CGContextDrawPath(ctx, kCGPathFill);
        
    if (self.passedMin) {
        // green arc for maximum
        arc = CGPathCreateMutable();
        CGPathMoveToPoint(arc, NULL, rect.size.width / 2, rect.size.height / 2 - smallRadius - thickLineWidth/2);
        CGPathAddArc(arc, NULL, rect.size.width / 2, rect.size.height / 2,
                     smallRadius + thickLineWidth/2, -M_PI_2, -M_PI_2 + M_PI_2 * self.maxPercentage * 4, NO);
        strokedArc = CGPathCreateCopyByStrokingPath(arc, NULL, thickLineWidth, kCGLineCapButt, kCGLineJoinMiter, 10);
        CGContextAddPath(ctx, strokedArc);
        CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:105.0/255.0 green:188.0/255.0 blue:69.0/255.0 alpha:0.9].CGColor);
        CGContextDrawPath(ctx, kCGPathFill);
    }
    
}


@end
