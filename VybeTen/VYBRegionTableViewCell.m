//
//  VYBRegionTableViewCell.m
//  VybeTen
//
//  Created by jinsuk on 8/19/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBRegionTableViewCell.h"

@implementation VYBRegionTableViewCell
@synthesize nameLabel, vybeCountLabel, userCountLabel;

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setName:(NSString *)aName {
    self.nameLabel.text = aName;
}

- (void)setVybeCount:(NSNumber *)aNum {
    self.vybeCountLabel.text = [aNum stringValue];
}

- (void)setUserCount:(NSNumber *)aNum {
    self.userCountLabel.text = [aNum stringValue];
}

@end
