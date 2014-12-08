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
//  CAShapeLayer *maskLayer = [CAShapeLayer layer];
  
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
    if ([self.reuseIdentifier isEqualToString:@"ActiveLocationCell"]) {

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
    if ([self.reuseIdentifier isEqualToString:@"ActiveLocationCell"]) {
      [self.contentView setBackgroundColor:[UIColor whiteColor]];
      [self.locationLabel setTextColor:[UIColor colorWithRed:74/255.0 green:74/255.0 blue:74/255.0 alpha:1.0]];
      [self.timestampLabel setTextColor:[UIColor colorWithRed:146/255.0 green:146/255.0 blue:146/255.0 alpha:1.0]];
    }
    if ([self.reuseIdentifier isEqualToString:@"MyVybeCell"]) {
      [self.contentView setBackgroundColor:[UIColor colorWithRed:234/255.0 green:234/255.0 blue:234/255.0 alpha:1.0]];
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
