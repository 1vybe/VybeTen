//
//  VYBHubControlView.m
//  VybeTen
//
//  Created by jinsuk on 8/28/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBHubControlView.h"

@interface VYBHubControlView ()

@property (nonatomic, strong) IBOutlet UIButton *locationButton;
@property (nonatomic, strong) IBOutlet UIButton *followingButton;
- (IBAction)locationButtonPressed:(id)sender;
- (IBAction)followingButtonPressed:(id)sender;

@end

@implementation VYBHubControlView
@synthesize locationButton, followingButton;

- (id)awakeAfterUsingCoder:(NSCoder *)aDecoder {
    if (![self.subviews count]) {
        VYBHubControlView *theOne = [[[NSBundle mainBundle] loadNibNamed:@"VYBHubControlView" owner:nil options:nil] firstObject];
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
            
            // By default location tab is selected at the beginning
            theOne.locationButton.selected = YES;
        }
        
        return theOne;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGFloat lineWidth = 1.0f;
    CGContextSetLineWidth(ctx, lineWidth);
    
    // Move the path down by half of the line width so it doesn't straddle pixels.
    CGContextMoveToPoint(ctx, 0, self.bounds.size.height - lineWidth*0.5);
    CGContextAddLineToPoint(ctx, self.bounds.size.width, self.bounds.size.height - lineWidth*0.5);
    
    CGContextSetStrokeColorWithColor(ctx, COLOR_CONTROL_LINE.CGColor);
    CGContextStrokePath(ctx);
}

- (IBAction)locationButtonPressed:(id)sender {
    if (!locationButton.selected) {
        [locationButton setSelected:YES];
        [followingButton setSelected:NO];
        if (self.delegate && [self.delegate respondsToSelector:@selector(locationButtonPressed:)]) {
            [self.delegate performSelector:@selector(locationButtonPressed:) withObject:sender];
        }
    }
}

- (IBAction)followingButtonPressed:(id)sender {
    if (!followingButton.selected) {
        [followingButton setSelected:YES];
        [locationButton setSelected:NO];
        if (self.delegate && [self.delegate respondsToSelector:@selector(followingButtonPressed:)]) {
            [self.delegate performSelector:@selector(followingButtonPressed:) withObject:sender];
        }
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
/*
- (IBAction)locationButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(locationButtonPressed:)]) {
        [self.delegate performSelector:@selector(locationButtonPressed:) withObject:sender];
    }
}

- (IBAction)followingButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(followingButtonPressed:)]) {
        [self.delegate performSelector:@selector(followingButtonPressed:) withObject:sender];
    }
}
*/


@end
