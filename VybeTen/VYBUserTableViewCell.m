//
//  VYBUserTableViewCell.m
//  VybeTen
//
//  Created by jinsuk on 8/21/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBUserTableViewCell.h"

@implementation VYBUserTableViewCell

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setFreshVybeCount:(NSInteger)freshVybeCount {
    _freshVybeCount = freshVybeCount;

    self.watchNewButton.hidden = !_freshVybeCount;
    
    [self.watchNewButton setTitle:[NSString stringWithFormat:@"%ld", (long)_freshVybeCount] forState:UIControlStateNormal];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

@end
