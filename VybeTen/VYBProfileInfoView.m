//
//  VYBProfileInfoView.m
//  VybeTen
//
//  Created by jinsuk on 8/22/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBProfileInfoView.h"

@implementation VYBProfileInfoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    // Initialization code]
        [self layoutIfNeeded];
        self.backgroundColor = [UIColor greenColor];
    }
    return self;
}

- (IBAction)watchAllButtonPressed:(id)sender {
    if (self.delegate) {
        if ( [self.delegate respondsToSelector:@selector(watchAllButtonPressed:)] ) {
            [self.delegate performSelector:@selector(watchAllButtonPressed:) withObject:nil];
        }
    }
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    //Get the CGContext from this view
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //Set the stroke (pen) color
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    //Set the width of the pen mark
    CGContextSetLineWidth(context, 1.0);
    
    // Draw a line
    //Start at this point
    CGContextMoveToPoint(context, 0.0, 0.0);
    
    //Give instructions to the CGContext
    //(move "pen" around the screen)
//    CGContextAddLineToPoint(context, 50.0, 50.0);
//    CGContextAddLineToPoint(context, 50.0, 150.0);
//    CGContextAddLineToPoint(context, 150.0, 150.0);
    CGContextAddLineToPoint(context, 50.0, 50.0);
    CGContextAddLineToPoint(context, 100.0, 50.0);
    CGContextAddLineToPoint(context, 100.0, 100.0);
    
    //Draw it
    CGContextStrokePath(context);
}


@end
