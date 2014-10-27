//
//  VYBCaptureButton.m
//  VybeTen
//
//  Created by jinsuk on 7/6/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBCaptureButton.h"
@interface VYBCaptureButton ()
@property (nonatomic) IBInspectable CGFloat radius;
@property (nonatomic) IBInspectable CGFloat borderLineWidth;
@end

const CGFloat _iRadius = 42.5f;
const CGFloat _iLineWidth = 4.0f;

@implementation VYBCaptureButton {
    NSTimer *_timer;
    BOOL _isRecording;
    
    CAShapeLayer *_backgroundLayer;
    CAShapeLayer *_redBorderLayer;
    CALayer *_foregroundLayer;
    
    CGFloat _fgWidth;
    CGFloat _fgHeight;
    
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setUpView];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpView];
    }
    return self;
}

- (void)setUpView {
    [self setBackgroundColor:[UIColor clearColor]];
    [self setOpaque:NO];
    
    _backgroundLayer = [CAShapeLayer layer];
    _foregroundLayer = [CALayer layer];
    _redBorderLayer = [CAShapeLayer layer];
    
    [self.layer addSublayer:_backgroundLayer];
    [self.layer addSublayer:_foregroundLayer];
    [self.layer addSublayer:_redBorderLayer];
}

- (void)layoutSubviews {
    _backgroundLayer.frame = self.bounds;
    _backgroundLayer.path = [self circleWithRadius:_radius];
    _backgroundLayer.fillColor = [UIColor colorWithWhite:0.5 alpha:0.5].CGColor;
    _backgroundLayer.strokeColor = [UIColor whiteColor].CGColor;
    _backgroundLayer.lineWidth = _borderLineWidth;
    
    _redBorderLayer.strokeColor = [UIColor redColor].CGColor;
    
    _fgWidth = 50.0f;
    _fgHeight = 50.0f;
    _foregroundLayer.frame = CGRectInset(self.bounds, (self.bounds.size.width - _fgWidth)/2.0, (self.bounds.size.height - _fgHeight)/2.0);
    _foregroundLayer.contentsGravity = kCAGravityResizeAspect;
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    _foregroundLayer.contents = (id)[UIImage imageNamed:@"capture_record_flyingV.png" inBundle:bundle compatibleWithTraitCollection:self.traitCollection].CGImage;
}


- (void)didStartRecording {
    _isRecording = YES;
    
    const CGFloat bigRadius = 47.5;
    const CGFloat thickLineWidth = 6.0f;
    
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        // CAShapeLayer's path needs to be set after animation is completed because CABasicAnimation does not actually change the properties of presented layer.
        //_backgroundLayer.path = [self circleWithRadius:bigRadius];
        
    }];
    [CATransaction setValue:[NSNumber numberWithFloat:3.0f] forKey:kCATransactionAnimationDuration];
    CABasicAnimation *bigger = [CABasicAnimation animationWithKeyPath:@"path"];
    bigger.removedOnCompletion = NO;
    bigger.fromValue = (id)[self circleWithRadius:_iRadius];
    bigger.toValue = (id)[self circleWithRadius:bigRadius];
    [_backgroundLayer addAnimation:bigger forKey:bigger.keyPath];

    _backgroundLayer.lineWidth = thickLineWidth;
    [CATransaction commit];
}

- (void)didStopRecording {
    _isRecording = NO;
    
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        _backgroundLayer.path = [self circleWithRadius:_iRadius];
    }];
    [CATransaction setValue:[NSNumber numberWithFloat:2.0f] forKey:kCATransactionAnimationDuration];
    CABasicAnimation *bigger = [CABasicAnimation animationWithKeyPath:@"path"];
    bigger.toValue = (id)[self circleWithRadius:_iRadius];
    [_backgroundLayer addAnimation:bigger forKey:bigger.keyPath];

    _backgroundLayer.lineWidth = _iLineWidth;
    [CATransaction commit];
}

- (CGPathRef)circleWithRadius:(CGFloat)radius {
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2.0 - radius, self.bounds.size.height/2.0 - radius, radius * 2, radius * 2)];
    
    return circlePath.CGPath;
}

#pragma mark - CABasicAnimationDelegate








/*
- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextClearRect(ctx, rect);

    // Draw white transparent inncer circle
    CGRect inncerCircle = CGRectMake(rect.size.width/2 - _radius, rect.size.height/2 - _radius, _radius * 2, _radius * 2);
    CGContextAddEllipseInRect(ctx, inncerCircle);
    CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:1.0 alpha:0.5].CGColor);
    CGContextDrawPath(ctx, kCGPathFill);
    
    CGMutablePathRef arc = CGPathCreateMutable();
    CGPathMoveToPoint(arc, NULL, rect.size.width / 2, rect.size.height/2 - _radius + _borderLineWidth/2);
    CGPathAddArc(arc, NULL, rect.size.width / 2, rect.size.height / 2, _radius - _borderLineWidth/2, -M_PI_2, 3 * M_PI_2, NO);
    CGPathRef strokedArc = CGPathCreateCopyByStrokingPath(arc, NULL, _borderLineWidth, kCGLineCapButt, kCGLineJoinMiter, 10);
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextAddPath(ctx, strokedArc);
    CGContextDrawPath(ctx, kCGPathFill);

    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    if (_isRecording) {
        UIImage *foregroundImage = [UIImage imageNamed:@"capture_record_sun.png" inBundle:bundle compatibleWithTraitCollection:self.traitCollection];
        CGRect foregroundBox = CGRectMake((rect.size.width - foregroundImage.size.width)/2.0, (rect.size.height - foregroundImage.size.height)/2.0, foregroundImage.size.width, foregroundImage.size.height);
        [foregroundImage drawInRect:foregroundBox];
        
    } else {
        UIImage *foregroundImage = [UIImage imageNamed:@"capture_record_flyingV.png" inBundle:bundle compatibleWithTraitCollection:self.traitCollection];
        CGRect foregroundBox = CGRectMake((rect.size.width - foregroundImage.size.width)/2.0, (rect.size.height - foregroundImage.size.height)/2.0, foregroundImage.size.width, foregroundImage.size.height);
        [foregroundImage drawInRect:foregroundBox];
    }
    
    
    
    
    // black transparent outter arc
     
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
