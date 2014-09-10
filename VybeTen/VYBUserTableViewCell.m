//
//  VYBUserTableViewCell.m
//  VybeTen
//
//  Created by jinsuk on 8/21/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBUserTableViewCell.h"

@interface VYBUserTableViewCell ()
- (IBAction)watchNewButtonPressed:(id)sender;
@end
@implementation VYBUserTableViewCell

- (void)awakeFromNib
{
    // Initialization code
}

- (IBAction)watchNewButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(watchNewVybesFromUser:)]) {
        [self.delegate performSelector:@selector(watchNewVybesFromUser:) withObject:self.userObjID];
    }
}


- (void)setFreshVybeCount:(NSInteger)freshVybeCount {
    _freshVybeCount = freshVybeCount;

    self.watchNewButton.hidden = !_freshVybeCount;
    
    [self.watchNewButton setTitle:[NSString stringWithFormat:@"%ld", (long)_freshVybeCount] forState:UIControlStateNormal];
}

- (void)setVybeCount:(NSInteger)vybeCount {
    _vybeCount = vybeCount;
    
    if (_freshVybeCount > 1)
        [self.countLabel setText:[NSString stringWithFormat:@"%ld Vybes", (long)_vybeCount]];
    else
        [self.countLabel setText:[NSString stringWithFormat:@"%ld Vybe", (long)_vybeCount]];
}




@end
