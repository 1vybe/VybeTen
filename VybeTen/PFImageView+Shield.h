//
//  PFImageView+Shield.h
//  Vybe
//
//  Created by Jinsu Kim on 2/20/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

#import "PFImageView.h"

@interface PFImageView (Shield)
- (void)makeCircle;
- (void)makeCircleWithBorderColor:(UIColor *) color Width:(CGFloat) width;
@end
