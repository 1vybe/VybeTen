//
//  VYBVybeCell.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 26..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBVybeCell.h"

@implementation VYBVybeCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setVideoPath:(NSString *)path {
    videoPath = path;
}

- (void)setThumbnailPath:(NSString *)path {
    thumbnailPath = path;
}

- (void)setDate:(NSDate *)d {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd HH:mm:ss"];
    date = [dateFormatter stringFromDate:d];
}

- (void)setContentView {
    UIImageView *thumbImgView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:thumbnailPath]];
    NSLog(@"thumbImgView FRAME width:%f height:%f", thumbImgView.frame.size.width, thumbImgView.frame.size.height);
    NSLog(@"thumbImgView BOUNDS width:%f height:%f", thumbImgView.bounds.size.width, thumbImgView.bounds.size.height);

    // Rotate the thumbnail image
    CGAffineTransform rotate = CGAffineTransformMakeRotation(-M_PI_2);
    thumbImgView.transform = rotate;
    // Crop the image to circle
    CALayer *layer = thumbImgView.layer;
    [layer setCornerRadius:thumbImgView.frame.size.width/2];
    [layer setMasksToBounds:YES];
    [self.contentView addSubview:thumbImgView];
}

- (NSString *)getDate {
    return date;
}

@end
