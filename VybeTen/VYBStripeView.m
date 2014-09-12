//
//  VYBStripeView.m
//  VybeTen
//
//  Created by Mohammed Tangestani on 2014-09-11.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBStripeView.h"

@implementation VYBStripeView

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
    CGContextSetStrokeColorWithColor(context, COLOR_CONTROL_LINE.CGColor);
    CGContextSetFillColorWithColor(context, COLOR_CONTROL_LINE.CGColor);
    
    // Set the width of the pen mark
    CGContextSetLineWidth(context, 0.5);
    
    // Create a curved line path
    CGContextMoveToPoint(context, -1.0, bounds.size.height*0.625);
    CGContextAddLineToPoint(context, -1.0, bounds.size.height+1.0);
    CGContextAddLineToPoint(context, bounds.size.width+1.0, bounds.size.height+1.0);
    CGContextAddLineToPoint(context, bounds.size.width+1.0, bounds.size.height*0.625);
    CGContextClosePath(context);
    
    // Draw the path
    CGContextDrawPath(context, kCGPathFillStroke);
}


@end
