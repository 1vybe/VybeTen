//
//  VYBVybeTableViewCell.m
//  VybeTen
//
//  Created by jinsuk on 8/22/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBVybeTableViewCell.h"
#import "VYBAppDelegate.h"

@implementation VYBVybeTableViewCell

- (void)awakeFromNib
{
  // Initialization code
}

- (UIEdgeInsets)layoutMargins
{
  return UIEdgeInsetsZero;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse {
  [super prepareForReuse];
  
  if ([self.reuseIdentifier isEqualToString:@"ZoneCell"]) {
    self.timestampLabel.textColor = [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1.0];
    self.locationLabel.textColor = [UIColor colorWithRed:74.0/255.0 green:74.0/255.0 blue:74.0/255.0 alpha:1.0];
    self.listBarImageView.image = [UIImage imageNamed:@"ListBar.png"];
  }
}

@end
