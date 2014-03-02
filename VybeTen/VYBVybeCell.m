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
        [self setSelectionStyle:UITableViewCellSelectionStyleNone];
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
    // Crop Image to 180 x 180
    UIImageView *thumbImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 180.0f, 180.0f)];
    [thumbImgView setImage:[UIImage imageWithContentsOfFile:thumbnailPath]];
    // Move the thumbnail image so its center aligns with the center of a cell's cententView
    CGPoint centerCell = self.contentView.center;
    thumbImgView.center = centerCell;
    // Rotate the thumbnail image
    CGAffineTransform rotate = CGAffineTransformMakeRotation(M_PI_2);
    thumbImgView.transform = rotate;
    /* Crop the image to circle
    CALayer *layer = thumbImgView.layer;
    [layer setCornerRadius:thumbImgView.frame.size.width/2];
    [layer setMasksToBounds:YES];
    */
    
    NSLog(@"contentView frame %@", NSStringFromCGRect(self.contentView.frame));
    NSLog(@"contentView bounds %@", NSStringFromCGRect(self.contentView.bounds));

    NSLog(@"thumbImgView frame %@", NSStringFromCGRect(thumbImgView.frame));
    NSLog(@"thumbImgView bounds %@", NSStringFromCGRect(thumbImgView.bounds));

    [self.contentView addSubview:thumbImgView];
}

- (NSString *)getDate {
    return date;
}


@end
