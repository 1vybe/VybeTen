//
//  VYBWatchAllButton.m
//  VybeTen
//
//  Created by jinsuk on 8/30/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBWatchAllButton.h"
@interface VYBWatchAllButton ()
@property (nonatomic, weak) IBOutlet UIButton *watchButton;
@property (nonatomic, weak) IBOutlet UIButton *counterButton;
@end
@implementation VYBWatchAllButton


- (id)awakeAfterUsingCoder:(NSCoder *)aDecoder {
    if (![self.subviews count]) {
        VYBWatchAllButton *theOne = (VYBWatchAllButton *)[[[NSBundle mainBundle] loadNibNamed:@"VYBWatchAllButton" owner:nil options:nil] firstObject];
        
        theOne.frame = self.frame;
        theOne.autoresizingMask = self.autoresizingMask;
        theOne.translatesAutoresizingMaskIntoConstraints = self.translatesAutoresizingMaskIntoConstraints;
        
        for (NSLayoutConstraint *constraint in self.constraints) {
            id firstItem = constraint.firstItem;
            if (firstItem == self)
                firstItem = theOne;
            
            id secondItem = constraint.secondItem;
            if (secondItem == self)
                secondItem = theOne;
            
            [theOne addConstraint:[NSLayoutConstraint constraintWithItem:firstItem attribute:constraint.firstAttribute
                                                               relatedBy:constraint.relation
                                                                  toItem:secondItem attribute:constraint.secondAttribute multiplier:constraint.multiplier constant:constraint.constant]];
        }
        
        return theOne;
    }
    return self;
}

- (void)shrink {
    self.watchButton.hidden = YES;
}

- (void)expand {
    self.watchButton.hidden = NO;
}

- (void)setCounterText:(NSString *)aText {
    [self.counterButton setTitle:aText forState:UIControlStateNormal];
}



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
