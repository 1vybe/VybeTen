//
//  VYBButton.m
//  VybeTen
//
//  Created by jinsuk on 10/28/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBActiveButton.h"

@interface VYBActiveButton ()

@property (nonatomic, copy) UIImage *normalImage;
@property (nonatomic, copy) UIImage *normalImageHighlight;
@property (nonatomic, copy) UIImage *activeImage;
@property (nonatomic, copy) UIImage *activeImageHighlight;

@end

@implementation VYBActiveButton {
//BOOL _isActive;
}

- (void)setActive:(BOOL)active {
    //_isActive = active;
    if (active) {
        [self setImage:_activeImage forState:UIControlStateNormal];
        [self setImage:_activeImageHighlight forState:UIControlStateHighlighted];
    }
    else {
        [self setImage:_normalImage forState:UIControlStateNormal];
        [self setImage:_normalImageHighlight forState:UIControlStateHighlighted];
    }
}
- (void)setActiveImage:(UIImage *)image highlightImage:(UIImage *)hImage {
    _activeImage = image;
    _activeImageHighlight = hImage;
}

- (void)setNormalImage:(UIImage *)image highlightImage:(UIImage *)hImage {
    _normalImage = image;
    _normalImageHighlight = hImage;
}

@end
