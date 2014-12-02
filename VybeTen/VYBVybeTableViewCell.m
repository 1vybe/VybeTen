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
  // Initialization code
}

- (UIEdgeInsets)layoutMargins
{
  return UIEdgeInsetsZero;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
  [super setSelected:selected animated:animated];
  
  if (selected) {
    NSLog(@"cell selected!");
  }
  
  // Configure the view for the selected state
}

- (void)setUnlocked:(BOOL)unlocked {
  _unlocked = unlocked;
  
  if (unlocked) {
    [self.timestampLabel setTextColor:[UIColor colorWithRed:92/255.0 green:140/255.0 blue:242/255.0 alpha:1.0]];
  }
  else {
    [self.timestampLabel setTextColor:[UIColor colorWithRed:248/255.0 green:123/255.0 blue:78/255.0 alpha:1.0]];
  }
}
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
  [super setHighlighted:highlighted animated:animated];
  
  if (highlighted) {
    if ([self.reuseIdentifier isEqualToString:@"UnwatchedActiveLocationCell"]) {
      [self.contentView setBackgroundColor:[UIColor colorWithRed:234/255.0 green:215/255.0 blue:171/255.0 alpha:1.0]];
      [self.unwatchedBarView setBackgroundColor:[UIColor whiteColor]];
      [self.locationLabel setTextColor:[UIColor whiteColor]];
      [self.timestampLabel setTextColor:[UIColor whiteColor]];
    }
    if ([self.reuseIdentifier isEqualToString:@"ActiveLocationCell"]) {
      if (_unlocked) {
        [self.contentView setBackgroundColor:[UIColor colorWithRed:175/255.0 green:192/255.0 blue:230/255.0 alpha:1.0]];
      }
      else {
        [self.contentView setBackgroundColor:[UIColor colorWithRed:231/255.0 green:180/255.0 blue:164/255.0 alpha:1.0]];
      }
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
      [self.contentView setBackgroundColor:[UIColor whiteColor]];
   
      [self.locationLabel setTextColor:[UIColor colorWithRed:74/255.0 green:74/255.0 blue:74/255.0 alpha:1.0]];
      
      [self setUnlocked:_unlocked];

      [self.unwatchedBarView setBackgroundColor:[UIColor colorWithRed:255/255.0 green:213/255.0 blue:75/255.0 alpha:1.0]];
    }
    if ([self.reuseIdentifier isEqualToString:@"ActiveLocationCell"]) {
      
      [self.contentView setBackgroundColor:[UIColor whiteColor]];
      
      [self.locationLabel setTextColor:[UIColor colorWithRed:74/255.0 green:74/255.0 blue:74/255.0 alpha:1.0]];
      
      [self setUnlocked:_unlocked];
    }
    if ([self.reuseIdentifier isEqualToString:@"MyVybeCell"]) {
      [self.contentView setBackgroundColor:[UIColor colorWithRed:229/255.0 green:229/255.0 blue:229/255.0 alpha:1.0]];
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
