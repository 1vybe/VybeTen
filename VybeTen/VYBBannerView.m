//
//  VYBBannerView.m
//  VybeTen
//
//  Created by Mohammed Tangestani on 2014-09-08.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBBannerView.h"

@implementation VYBBannerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code]
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGRect bounds = self.bounds;
    
    // Get the CGContext from this view
    CGContextRef context = UIGraphicsGetCurrentContext();

    // Set the stroke and fill colors
    CGContextSetStrokeColorWithColor(context, self.strokeColor.CGColor);
    CGContextSetFillColorWithColor(context, self.fillColor.CGColor);
    
    // Set the width of the pen mark
    CGContextSetLineWidth(context, 0.5);
    
    // Create a curved line path
    CGContextMoveToPoint(context, -1.0, -1.0);
    CGContextAddLineToPoint(context, -1.0, bounds.size.height*0.2);
    CGContextAddCurveToPoint(context, bounds.size.width*0.4, bounds.size.height*0.4,
                                      bounds.size.width*0.6, bounds.size.height*0.4,
                                      bounds.size.width+1.0, bounds.size.height*0.2);
    CGContextAddLineToPoint(context, bounds.size.width+1.0, -1.0);
    CGContextClosePath(context);
    
    // Draw the path
    CGContextDrawPath(context, kCGPathFillStroke);
}


@end
