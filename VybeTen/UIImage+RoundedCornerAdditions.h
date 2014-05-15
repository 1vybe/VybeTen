//
//  UIImage+RoundedCornerAdditions.h
//  VybeTen
//
//  Created by jinsuk on 5/15/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (RoundedCorner)
- (UIImage *)roundedCornerImage:(NSInteger)cornerSize borderSize:(NSInteger)borderSize;
@end
