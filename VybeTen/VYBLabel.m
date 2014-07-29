//
//  VYBLabel.m
//  VybeTen
//
//  Created by jinsuk on 4/13/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBLabel.h"

@implementation VYBLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/* Drop shadow on the text */
- (void)drawTextInRect:(CGRect)rect {
    CGSize myShadowOffset = CGSizeMake(0, 0);
    CGFloat colorValues[] = {0, 0, 0, 1.0};
   
    
    CGContextRef myContext = UIGraphicsGetCurrentContext();
    CGContextSaveGState(myContext);
    
    CGColorSpaceRef myColorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef myColor = CGColorCreate(myColorSpace, colorValues);
    CGContextSetShadowWithColor(myContext, myShadowOffset, 2, myColor);
    
    [super drawTextInRect:rect];
    
    CGColorRelease(myColor);
    CGColorSpaceRelease(myColorSpace);
    CGContextRestoreGState(myContext);
}

@end
