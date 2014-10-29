//
//  VYBButton.h
//  VybeTen
//
//  Created by jinsuk on 10/28/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VYBActiveButton : UIButton
- (void)setActive:(BOOL)active;
- (void)setNormalImage:(UIImage *)image highlightImage:(UIImage *)hImage;
- (void)setActiveImage:(UIImage *)image highlightImage:(UIImage *)hImage;
@end
