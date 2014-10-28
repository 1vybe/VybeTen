//
//  VYBPizzaLayer.m
//  VybeTen
//
//  Created by jinsuk on 10/27/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBPizzaLayer.h"

@implementation VYBPizzaLayer

@dynamic startAngle, endAngle, radius;
@synthesize fillColor, strokeColor, strokeWidth;

- (id<CAAction>)actionForKey:(NSString *)event {
    if ([event isEqualToString:@"startAngle"] || [event isEqualToString:@"endAngle"] || [event isEqualToString:@"radius"]) {
        return [self makeAnimationForKey:event];
    }
    return [super actionForKey:event];
}

- (id)initWithLayer:(id)layer {
    self = [super initWithLayer:layer];
    if (self) {
        VYBPizzaLayer *other = (VYBPizzaLayer *)layer;
        self.startAngle = other.startAngle;
        self.endAngle = other.endAngle;
        self.radius = other.radius;
        self.fillColor = other.fillColor;
        self.strokeWidth = other.strokeWidth;
        self.strokeColor = other.strokeColor;
    }
    return self;
}

+ (BOOL)needsDisplayForKey:(NSString *)key {
    if ([key isEqualToString:@"startAngle"] || [key isEqualToString:@"endAngle"] || [key isEqualToString:@"radius"]) {
        return YES;
    }
    return [super needsDisplayForKey:key];
}

-(CABasicAnimation *)makeAnimationForKey:(NSString *)key {
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:key];
    anim.fromValue = [[self presentationLayer] valueForKey:key];
    //anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    //anim.duration = 0.5;
    
    return anim;
}

- (void)drawInContext:(CGContextRef)ctx {
    CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    
    CGContextBeginPath(ctx);
    
    CGPoint p1 = CGPointMake(center.x + self.radius * cosf(self.startAngle), center.y + self.radius * sinf(self.startAngle));
    CGContextMoveToPoint(ctx, p1.x, p1.y);
    int clockwise = self.startAngle > self.endAngle;
    CGContextAddArc(ctx, center.x, center.y, self.radius, self.startAngle, self.endAngle, clockwise);
    //CGContextClosePath(ctx);
    
    CGContextSetFillColorWithColor(ctx, self.fillColor.CGColor);
    CGContextSetStrokeColorWithColor(ctx, self.strokeColor.CGColor);
    CGContextSetLineWidth(ctx, self.strokeWidth);
    
    CGContextDrawPath(ctx, kCGPathFillStroke);

}


@end
