//
//  VYBRegionHeaderButton.m
//  VybeTen
//
//  Created by jinsuk on 8/21/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBRegionHeaderButton.h"

@implementation VYBRegionHeaderButton {
    
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

+ (id)VYBRegionHeaderButton {
    VYBRegionHeaderButton *theView = [[[NSBundle mainBundle] loadNibNamed:@"VYBRegionHeaderButton" owner:nil options:nil] lastObject];
    if ( [theView isKindOfClass:[VYBRegionHeaderButton class]] ) {
        return theView;
    }
    
    return nil;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
}

- (IBAction)unwatchedVybeButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(watchNewVybesFrom:)]) {
        [self.delegate performSelector:@selector(watchNewVybesFrom:) withObject:nil];
    
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
