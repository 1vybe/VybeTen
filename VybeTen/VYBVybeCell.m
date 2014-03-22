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
@synthesize labelTitle = _labelTitle;

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

- (void)customizeWithTitle:(NSString *)title {
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    // Rotate the thumbnail image
    CGAffineTransform rotate = CGAffineTransformMakeRotation(M_PI_2);
    //_thumbnailImageView.transform = rotate;
    UILabel *labelTitle = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.bounds.size.width/2 - 80, self.contentView.bounds.size.height/2 - 20, 160, 40)];
    [labelTitle setText:title];
    [labelTitle setTextColor:[UIColor whiteColor]];
    [labelTitle setTextAlignment:NSTextAlignmentCenter];
    [self.contentView addSubview:labelTitle];
    [labelTitle setTransform:rotate];
    _labelTitle = labelTitle;
}

- (void)prepareForReuse {
    [_labelTitle removeFromSuperview];
}


@end
