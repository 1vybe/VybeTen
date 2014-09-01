//
//  VYBWatchAllButton.m
//  VybeTen
//
//  Created by jinsuk on 8/30/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBWatchAllButton.h"
@implementation VYBWatchAllButton

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        VYBWatchAllButton *watchXib = [[[NSBundle mainBundle] loadNibNamed:@"VYBWatchAllButton" owner:self options:nil] objectAtIndex:0];
        [self addSubview:watchXib];
    }
    
    return self;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
