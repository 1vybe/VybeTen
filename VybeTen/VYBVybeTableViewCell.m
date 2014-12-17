//
//  VYBVybeTableViewCell.m
//  VybeTen
//
//  Created by jinsuk on 8/22/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBVybeTableViewCell.h"
#import "VYBAppDelegate.h"

@implementation VYBVybeTableViewCell {
  BOOL _unlocked;
}

- (void)awakeFromNib
{
//  int radius = self.thumbnailImageView.bounds.size.width / 2;
//  UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, self.thumbnailImageView.bounds.size.width, self.thumbnailImageView.bounds.size.height) cornerRadius:0];
//  UIBezierPath *circlePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 2.0*radius, 2.0*radius) cornerRadius:radius];
//  [path appendPath:circlePath];
//  [path setUsesEvenOddFillRule:YES];
//  
//  CAShapeLayer *fillLayer = [CAShapeLayer layer];
//  fillLayer.path = path.CGPath;
//  fillLayer.fillRule = kCAFillRuleEvenOdd;
//  fillLayer.fillColor = [UIColor whiteColor].CGColor;
//  fillLayer.opacity = 1.0;
//  [self.thumbnailImageView.layer addSublayer:fillLayer];
}

- (UIEdgeInsets)layoutMargins
{
  return UIEdgeInsetsZero;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
  [super setHighlighted:highlighted animated:animated];
  
  if (highlighted) {
    if ([self.reuseIdentifier isEqualToString:@"UnwatchedActiveLocationCell"]) {
      [self.contentView setBackgroundColor:[UIColor colorWithRed:227/255.0 green:227/255.0 blue:227/255.0 alpha:1.0]];
      [self.unwatchedBarView setImage:[UIImage imageNamed:@"TransparentImage"]];
      
      [self.locationLabel setTextColor:[UIColor whiteColor]];
      [self.timestampLabel setTextColor:[UIColor whiteColor]];
    }
    if ([self.reuseIdentifier isEqualToString:@"ActiveLocationCell"] || [self.reuseIdentifier isEqualToString:@"FeaturedLocationCell"]) {
        [self.contentView setBackgroundColor:[UIColor colorWithRed:227/255.0 green:227/255.0 blue:227/255.0 alpha:1.0]];
      [self.locationLabel setTextColor:[UIColor whiteColor]];
      [self.timestampLabel setTextColor:[UIColor whiteColor]];
    }
    if ([self.reuseIdentifier isEqualToString:@"MyVybeCell"]) {
      [self.contentView setBackgroundColor:[UIColor colorWithRed:166/255.0 green:185/255.0 blue:232/255.0 alpha:1.0]];
      [self.timestampLabel setTextColor:[UIColor whiteColor]];
    }
  }
  else {
    if ([self.reuseIdentifier isEqualToString:@"UnwatchedActiveLocationCell"]) {
      [self.unwatchedBarView setImage:[UIImage imageNamed:@"UnwatchedBar"]];
      [self.contentView setBackgroundColor:[UIColor whiteColor]];
      [self.locationLabel setTextColor:[UIColor colorWithRed:74/255.0 green:74/255.0 blue:74/255.0 alpha:1.0]];
      [self.timestampLabel setTextColor:[UIColor colorWithRed:146/255.0 green:146/255.0 blue:146/255.0 alpha:1.0]];
    }
    if ([self.reuseIdentifier isEqualToString:@"ActiveLocationCell"] || [self.reuseIdentifier isEqualToString:@"FeaturedLocationCell"]) {
      [self.contentView setBackgroundColor:[UIColor whiteColor]];
      [self.locationLabel setTextColor:[UIColor colorWithRed:74/255.0 green:74/255.0 blue:74/255.0 alpha:1.0]];
      [self.timestampLabel setTextColor:[UIColor colorWithRed:146/255.0 green:146/255.0 blue:146/255.0 alpha:1.0]];
    }
    if ([self.reuseIdentifier isEqualToString:@"MyVybeCell"]) {
      [self.contentView setBackgroundColor:[UIColor colorWithRed:249/255.0 green:249/255.0 blue:249/255.0 alpha:1.0]];
      [self.timestampLabel setTextColor:[UIColor colorWithRed:146/255.0 green:146/255.0 blue:146/255.0 alpha:1.0]];
    }
  }
}

- (void)prepareForReuse {
  [super prepareForReuse];
    
  [self setSelected:NO];
  [self setHighlighted:NO];
}


@end
