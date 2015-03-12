//
//  VYBRecordButton.m
//  Vybe
//
//  Created by Jinsu Kim on 3/12/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

#import "VYBRecordButton.h"
#import "VYBPizzaLayer.h"

@interface VYBRecordButton ()
@property (nonatomic) IBInspectable CGFloat radius;
@property (nonatomic) IBInspectable CGFloat borderLineWidth;
@end

const CGFloat _fRadius = 48.0f;
const CGFloat _fStrokeWidth = 4.0f;
const CGFloat _fBlackStrokeWidth = 1.0f;

@implementation VYBRecordButton {
  NSTimer *_timer;
  
  CAShapeLayer *_backgroundLayer;
  VYBPizzaLayer *_redBorderLayer;
//  CAShapeLayer *_blackBorderLayer;
  CALayer *_foregroundLayer;
  
  CABasicAnimation *_bigger;
  
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
  _redBorderLayer = [VYBPizzaLayer layer];
//  _blackBorderLayer = [CAShapeLayer layer];
  _foregroundLayer = [CALayer layer];
  
  
  [self.layer addSublayer:_backgroundLayer];
  [self.layer addSublayer:_redBorderLayer];
//  [self.layer addSublayer:_blackBorderLayer];
  [self.layer addSublayer:_foregroundLayer];
}

- (void)layoutSubviews {
  _backgroundLayer.frame = self.bounds;
  _backgroundLayer.path = [self circleWithRadius:_fRadius];
  _backgroundLayer.fillColor = [UIColor colorWithWhite:0.5 alpha:0.5].CGColor;
  _backgroundLayer.strokeColor = [UIColor whiteColor].CGColor;
  _backgroundLayer.lineWidth = _fStrokeWidth;
  
  _redBorderLayer.frame = self.bounds;
  _redBorderLayer.startAngle = -M_PI_2;
  _redBorderLayer.endAngle = _redBorderLayer.startAngle;
  _redBorderLayer.radius = _fRadius;
  _redBorderLayer.strokeColor = [UIColor redColor];
  _redBorderLayer.strokeWidth = _fStrokeWidth;
  _redBorderLayer.fillColor = [UIColor clearColor];
  _redBorderLayer.rasterizationScale = [UIScreen mainScreen].scale;
  _redBorderLayer.shouldRasterize = YES;
  
//  _blackBorderLayer.frame = self.bounds;
//  _blackBorderLayer.path = [self circleWithRadius:_fRadius + _fStrokeWidth/2.0 + _fBlackStrokeWidth/2.0];
//  _blackBorderLayer.fillColor = [UIColor clearColor].CGColor;
//  _blackBorderLayer.strokeColor = [UIColor blackColor].CGColor;
//  _blackBorderLayer.lineWidth = _fBlackStrokeWidth;
//  _blackBorderLayer.rasterizationScale = [UIScreen mainScreen].scale;
//  _blackBorderLayer.shouldRasterize = YES;
  
  _fgWidth = 92.0f;
  _fgHeight = 92.0f;
  _foregroundLayer.frame = CGRectInset(self.bounds, (self.bounds.size.width - _fgWidth)/2.0, (self.bounds.size.height - _fgHeight)/2.0);
  _foregroundLayer.contents = (id)[self getContentsWithNamed:@"Capture_Sun"];
//  _foregroundLayer.contentsGravity = kCAGravityResizeAspect;
}


- (void)didStartRecording {
  
  const CGFloat bigRadius = 56;
  const CGFloat thickLineWidth = 6.0f;
  
  
  [CATransaction begin];                                  // red circle animation
  [CATransaction setValue:[NSNumber numberWithFloat:15.0f] forKey:kCATransactionAnimationDuration];
  //CABasicAnimation *redArc = [CABasicAnimation animationWithKeyPath:@"path"];
  //redArc.fillMode = kCAFillModeForwards;
  //redArc.toValue = (id)[self arcWithRadius:_oRadius percentage:1.0];
  //_redBorderLayer.lineWidth = thickLineWidth;
  _redBorderLayer.endAngle = 3 * M_PI_2;
  
  [CATransaction begin];              // growing animation
  [CATransaction setValue:[NSNumber numberWithFloat:2.0f] forKey:kCATransactionAnimationDuration];
  CABasicAnimation *bgGrowing = [CABasicAnimation animationWithKeyPath:@"path"];
  // animation effect does not reverse
  bgGrowing.fillMode = kCAFillModeForwards;
  // animation layer is not removed
  bgGrowing.removedOnCompletion = NO;
  bgGrowing.toValue = (id)[self circleWithRadius:bigRadius];
  [_backgroundLayer addAnimation:bgGrowing forKey:bgGrowing.keyPath];
  _backgroundLayer.lineWidth = thickLineWidth;
  
  // give a slightly more weight on red stroke
  _redBorderLayer.strokeWidth = thickLineWidth + 0.5;
  _redBorderLayer.radius = bigRadius;
  
//  CABasicAnimation *borderGrowing = [CABasicAnimation animationWithKeyPath:@"path"];
//  // animation effect does not reverse
//  borderGrowing.fillMode = kCAFillModeForwards;
//  // animation layer is not removed
//  borderGrowing.removedOnCompletion = NO;
//  borderGrowing.toValue = (id)[self circleWithRadius:bigRadius + thickLineWidth/2.0 + _fBlackStrokeWidth/2.0];
//  [_blackBorderLayer addAnimation:borderGrowing forKey:borderGrowing.keyPath];
  
  [CATransaction begin]; // sun animation
  [CATransaction setValue:[NSNumber numberWithFloat:0.5f] forKey:kCATransactionAnimationDuration];
  _foregroundLayer.contents = (id)[self getContentsWithNamed:@"Capture_Sun"];
  [CATransaction commit]; // sun animation
  
  [CATransaction commit];             // growing animation
  
  [CATransaction commit];                                 // red circle animation
}

- (void)didStopRecording {
  
  // Remove growing animation
  [_backgroundLayer removeAllAnimations];
  _backgroundLayer.path = [self circleWithRadius:_fRadius];
  _backgroundLayer.lineWidth = _fStrokeWidth;
  
  _redBorderLayer.endAngle = _redBorderLayer.startAngle;
  _redBorderLayer.strokeWidth = _fStrokeWidth;
  _redBorderLayer.radius = _fRadius;
  
//  [_blackBorderLayer removeAllAnimations];
//  _blackBorderLayer.path = [self circleWithRadius:_fRadius + _fStrokeWidth/2 + _fBlackStrokeWidth/2];
  
  _foregroundLayer.contents = (id)[self getContentsWithNamed:@"Capture_Sun"];
}

- (CGPathRef)circleWithRadius:(CGFloat)radius {
  UIBezierPath *circlePath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width/2.0 - radius, self.bounds.size.height/2.0 - radius, radius * 2, radius * 2)];
  
  return circlePath.CGPath;
}

- (CGImageRef)getContentsWithNamed:(NSString *)imgName {
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  return [UIImage imageNamed:imgName inBundle:bundle compatibleWithTraitCollection:self.traitCollection].CGImage;
  
}

@end
