//
//  VYBVybeCell.m
//  VybeTen
//
//  Customize delete button. Basically the button is hidden until the top layer slides down.
//
//  Created by Kim Jin Su on 2014. 2. 26..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBVybeCell.h"

@implementation VYBVybeCell {
    UILabel *labelTitle;
    UIButton *buttonDelete;
}   

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        // Initialization code
        self.opaque = NO;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.accessoryType = UITableViewCellAccessoryNone;
        self.clipsToBounds = NO;
        
        self.backgroundColor = [UIColor clearColor];
        
        self.imageView.frame = CGRectMake( 0.0f, 0.0f, 180.0f, self.contentView.frame.size.height);
        self.imageView.backgroundColor = [UIColor clearColor];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        // Rotate the thumbnail image counter-clockwise
        CGAffineTransform rotate = CGAffineTransformMakeRotation(-M_PI_2);
        self.imageView.transform = rotate;
        
        [self.contentView bringSubviewToFront:self.imageView];
    }
    
    return self;
}

#pragma mark - UIView

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = CGRectMake( 0.0f, 0.0f, self.contentView.frame.size.width, 200.0f);
}

/*
// For tribes in MyTribes
- (void)customizeWithTitle:(NSString *)title {
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    // Rotate the thumbnail image
    CGAffineTransform rotate = CGAffineTransformMakeRotation(-M_PI_2);
    UILabel *labelTitle = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.bounds.size.width/2 - 80, self.contentView.bounds.size.height/2 - 20, 160, 40)];
    [labelTitle setText:title];
    [labelTitle setTextColor:[UIColor whiteColor]];
    [labelTitle setTextAlignment:NSTextAlignmentCenter];
    [labelTitle setFont:[UIFont fontWithName:@"Montreal-Xlight" size:18]];
    [self.contentView addSubview:labelTitle];
    [labelTitle setTransform:rotate];
    self.labelTitle = labelTitle;
}
*/


@end
