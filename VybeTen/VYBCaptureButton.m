//
//  VYBCaptureButton.m
//  VybeTen
//
//  Created by jinsuk on 7/6/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBCaptureButton.h"

@implementation VYBCaptureButton {
    UIImageView *_backgroundImage;
    UIImageView *_foregroundImage;
    
    double smallRadius;
    double largeRaduis;
    double thinLineWidth;
    double thickLineWidth;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _backgroundImage = [[UIImageView alloc] initWithFrame:self.bounds];
        [_backgroundImage setContentMode:UIViewContentModeCenter];
        [_backgroundImage setImage:[UIImage imageNamed:@"capture_record_bg_normal.png"]];
        [self addSubview:_backgroundImage];
        
        _foregroundImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60.0, 60.0)];
        [_foregroundImage setContentMode:UIViewContentModeScaleAspectFit];
        [_foregroundImage setImage:[UIImage imageNamed:@"capture_record_flyingV.png"]];
        [self addSubview:_foregroundImage];
        _foregroundImage.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        
        [self setBackgroundColor:[UIColor clearColor]];
        
        self.minPercentage = 0.5;
        self.maxPercentage = 0.0;
        
        smallRadius = 46.0;
        largeRaduis = 58.0;
        
        thinLineWidth = 6.0;
        thickLineWidth = 12.0;
    }
    return self;
}

- (void)didStartRecording {
    [_foregroundImage setImage:[UIImage imageNamed:@"capture_record_sun.png"]];
    [UIView transitionWithView:_backgroundImage duration:3.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [_backgroundImage setImage:[UIImage imageNamed:@"capture_record_bg_pressed.png"]];
    } completion:nil];
}

- (void)didStopRecording {
    [_foregroundImage setImage:[UIImage imageNamed:@"capture_record_flyingV.png"]];
    [UIView transitionWithView:_backgroundImage duration:3.0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [_backgroundImage setImage:[UIImage imageNamed:@"capture_record_bg_normal.png"]];
    } completion:nil];
}

/*
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
*/

@end
