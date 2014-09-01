//
//  VYBHubControlView.m
//  VybeTen
//
//  Created by jinsuk on 8/28/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBHubControlView.h"

@interface VYBHubControlView ()
@property (nonatomic, weak) id delegate;
/*
@property (nonatomic, strong) IBOutlet UIButton *locationButton;
@property (nonatomic, strong) IBOutlet UIButton *followingButton;
- (IBAction)locationButtonPressed:(id)sender;
- (IBAction)followingButtonPressed:(id)sender;
 */
@end

@implementation VYBHubControlView

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:COLOR_CONTROL_BG];
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
- (CGSize)intrinsicContentSize {
    return self.frame.size;
}

@end
