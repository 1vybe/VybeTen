//
//  VYBVybeCell.m
//  VybeTen
//
//  Customize delete button. Basically the button is hidden until the top layer slides down.
//
//  Created by Kim Jin Su on 2014. 2. 26..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBVybeCell.h"

@implementation VYBVybeCell
@synthesize thumbnailView = _thumbnailView;
@synthesize labelTitle = _labelTitle;
@synthesize buttonDelete = _buttonDelete;
@synthesize topLayer = _topLayer;

// For vybes in MyTribes
- (void)customize {
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    // Rotate the thumbnail image counter-clockwise
    CGAffineTransform rotate = CGAffineTransformMakeRotation(-M_PI_2);
    self.thumbnailView.transform = rotate;
    [self.thumbnailView setContentMode:UIViewContentModeScaleAspectFit];
}

// For vybes in MyVybes
- (void)customizeOtherDirection {
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    // Rotate the thumbnail image clockwise
    CGAffineTransform rotate = CGAffineTransformMakeRotation(M_PI_2);
    self.thumbnailView.transform = rotate;
    [self.thumbnailView setContentMode:UIViewContentModeScaleAspectFit];
}

// For tribes in MyTribes
- (void)customizeWithTitle:(NSString *)title {
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    // Rotate the thumbnail image
    CGAffineTransform rotate = CGAffineTransformMakeRotation(-M_PI_2);
    UILabel *labelTitle = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.bounds.size.width/2 - 80, self.contentView.bounds.size.height/2 - 20, 160, 40)];
    [labelTitle setText:title];
    [labelTitle setTextColor:[UIColor whiteColor]];
    [labelTitle setTextAlignment:NSTextAlignmentCenter];
    [labelTitle setFont:[UIFont fontWithName:@"Montreal-Xlight" size:18]];
    [self.contentView addSubview:labelTitle];
    [labelTitle setTransform:rotate];
    self.labelTitle = labelTitle;
}

/**
 * In iOS7 it works because by using performSelector:withObject:afterDelay the selector is queued on the thread’s run loop and
 * not performed immediately, allowing the OS to add the Delete button view in the meantime.
 **/
- (void)willTransitionToState:(UITableViewCellStateMask)state {
    [super willTransitionToState:state];
    if ((state & UITableViewCellStateShowingDeleteConfirmationMask) == UITableViewCellStateShowingDeleteConfirmationMask ) {
        [self recurseAndReplaceSubviewIfDeleteConfirmationControl:self.subviews];
        [self performSelector:@selector(recurseAndReplaceSubviewIfDeleteConfirmationControl:) withObject:self.subviews afterDelay:0];
    }
}

- (void)recurseAndReplaceSubviewIfDeleteConfirmationControl:(NSArray *)subviews {
    NSLog(@"recursing");
    for (UIView *subview in subviews) {
        // For iOS 6 and earlier
        if ([NSStringFromClass([subview class]) isEqualToString:@"UITableViewCellDeleteConfirmationControl"]) {
            UIView *backgroundCoverDefaultControl = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
            [backgroundCoverDefaultControl setBackgroundColor:[UIColor clearColor]];
            UIImage *deleteImg = [UIImage imageNamed:@"button_cancel.png"];
            UIImageView *deleteButton = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, deleteImg.size.width, deleteImg.size.height)];
            [deleteButton setImage:deleteImg];
        }
        // The rest is to handle iOS 7
        if ([NSStringFromClass([subview class]) isEqualToString:@"UITableViewCellDeleteConfirmationButton"]) {
            NSLog(@"ConfirmationButton found");
            UIButton *deleteButton = (UIButton *)subview;
            [deleteButton setImage:[UIImage imageNamed:@"button_cancel.png"] forState:UIControlStateNormal];
            [deleteButton setBackgroundColor:[UIColor clearColor]];
            for (UIView *view in subview.subviews) {
                if ([view isKindOfClass:[UILabel class]]) {
                    [view removeFromSuperview];
                }
            }
        }
        if ([NSStringFromClass([subview class]) isEqualToString:@"UITableViewCellDeleteConfirmationView"]) {
            NSLog(@"ConfirmationView found");
            [subview setBackgroundColor:[UIColor clearColor]];
            for (UIView *innerSubview in subview.subviews) {
                if (![innerSubview isKindOfClass:[UIButton class]]) {
                    NSLog(@"DeleteConfirmationView: removing a button");
                    [innerSubview removeFromSuperview];
                }
            }
        }
        if ([subview.subviews count] > 0) {
            [self recurseAndReplaceSubviewIfDeleteConfirmationControl:subview.subviews];
        }
    }
    NSLog(@"recursing done");
}

- (void)prepareForReuse {
    [self.labelTitle removeFromSuperview];
    [super prepareForReuse];
}

/**
 * Helper functions
 **/

// Recursively travel down the view tree, increasing the
// indentation level for children
- (void) dumpView: (UIView *) aView atIndent: (int) indent into:(NSMutableString *) outstring
{
    // Add the indentation dashes
    for (int i = 0; i < indent; i++)
        [outstring appendString:@"--"];
    // Follow that with the class description
    [outstring appendFormat:@"[%2d] %@\n", indent, [[aView class] description]];
    
    // Recurse through each subview
    for (UIView *view in aView.subviews)
        [self dumpView:view atIndent:indent + 1 into:outstring];
}

// Start the tree recursion at level 0 with the root view
- (NSString *) displayViews: (UIView *) aView
{
    NSMutableString *outstring = [NSMutableString string];
    [self dumpView:aView atIndent:0 into:outstring];
    
    return outstring;
}

@end
