//
//  VYBVybeCell.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 26..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBVybeCell.h"

@implementation VYBVybeCell
@synthesize thumbnailImageView = _thumbnailImageView;

- (void)customize {
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    // Rotate the thumbnail image
    CGAffineTransform rotate = CGAffineTransformMakeRotation(M_PI_2);
    _thumbnailImageView.transform = rotate;
    // Crop the image to circle
    CALayer *layer = _thumbnailImageView.layer;
    [layer setCornerRadius:_thumbnailImageView.frame.size.width/2];
    [layer setMasksToBounds:YES];
}

@end
