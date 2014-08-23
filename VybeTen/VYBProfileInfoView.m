//
//  VYBProfileInfoView.m
//  VybeTen
//
//  Created by jinsuk on 8/22/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBProfileInfoView.h"

@implementation VYBProfileInfoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (IBAction)watchAllButtonPressed:(id)sender {
    if (self.delegate) {
        if ( [self.delegate respondsToSelector:@selector(watchAllButtonPressed:)] ) {
            [self.delegate performSelector:@selector(watchAllButtonPressed:) withObject:nil];
        }
    }
}

@end
