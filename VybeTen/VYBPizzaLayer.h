//
//  VYBPizzaLayer.h
//  VybeTen
//
//  Created by jinsuk on 10/27/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface VYBPizzaLayer : CALayer
@property (nonatomic) CGFloat startAngle;
@property (nonatomic) CGFloat endAngle;
@property (nonatomic) CGFloat radius;

@property (nonatomic) UIColor *fillColor;
@property (nonatomic) CGFloat strokeWidth;
@property (nonatomic) UIColor *strokeColor;
@end
