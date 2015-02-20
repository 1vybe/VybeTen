//
//  PFImageView+Shield.m
//  Vybe
//
//  Created by Jinsu Kim on 2/20/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

#import "PFImageView+Shield.h"

@implementation PFImageView (Shield)
- (void)makeCircle {
  CALayer *lyr = self.layer;
  lyr.masksToBounds = YES;
  lyr.cornerRadius = self.bounds.size.width / 2; // assumes image is a square
}

- (void)makeCircleWithBorderColor:(UIColor *) color Width:(CGFloat) width {
  [self makeCircle];
  CALayer *lyr = self.layer;
  lyr.borderWidth = width;
  lyr.borderColor = [color CGColor];
}
@end
