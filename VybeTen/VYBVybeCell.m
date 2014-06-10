//
//  VYBVybesCell.m
//  VybeTen
//
//  Created by jinsuk on 6/2/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBVybeCell.h"
#import "VYBUtility.h"

@implementation VYBVybeCell


@synthesize delegate;
@synthesize vybe;
@synthesize thumbnailImageButton;
@synthesize thumbnailImageView;
@synthesize nameButton;
//@synthesize followButton;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.thumbnailImageView = [[PFImageView alloc] initWithFrame:CGRectMake(10.0f, 14.0f, 40.0f, 40.0f)];
        [self.contentView addSubview:self.thumbnailImageView];
        
        self.thumbnailImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.thumbnailImageButton.backgroundColor = [UIColor clearColor];
        self.thumbnailImageButton.frame = CGRectMake( 10.0f, 14.0f, 40.0f, 40.0f);
        [self.thumbnailImageButton addTarget:self action:@selector(didTapVybeButtonAction:)
                            forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.thumbnailImageButton];
        
        self.nameButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.nameButton.backgroundColor = [UIColor clearColor];
        self.nameButton.titleLabel.font = [UIFont fontWithName:@"Montreal-Xlight" size:16.0f];
        self.nameButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.nameButton setTitleColor:[UIColor colorWithRed:87.0f/255.0f green:72.0f/255.0f blue:49.0f/255.0f alpha:1.0f]
                              forState:UIControlStateNormal];
        [self.nameButton setTitleColor:[UIColor colorWithRed:134.0f/255.0f green:100.0f/255.0f blue:65.0f/255.0f alpha:1.0f]
                              forState:UIControlStateHighlighted];
        [self.nameButton setTitleShadowColor:[UIColor whiteColor]
                                    forState:UIControlStateNormal];
        [self.nameButton setTitleShadowColor:[UIColor whiteColor]
                                    forState:UIControlStateSelected];
        [self.nameButton.titleLabel setShadowOffset:CGSizeMake( 0.0f, 1.0f)];
        [self.nameButton addTarget:self action:@selector(didTapVybeButtonAction:)
                  forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.nameButton];
        
        /*
        self.followButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.followButton.titleLabel.font = [UIFont boldSystemFontOfSize:15.0f];
        self.followButton.titleEdgeInsets = UIEdgeInsetsMake( 0.0f, 10.0f, 0.0f, 0.0f);
        [self.followButton setTitle:NSLocalizedString(@"Follow  ", @"Follow string, with spaces added for centering")
                           forState:UIControlStateNormal];
        [self.followButton setTitle:@"Following"
                           forState:UIControlStateSelected];
        [self.followButton setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:57.0f/255.0f blue:45.0f/255.0f alpha:1.0f]
                                forState:UIControlStateNormal];
        [self.followButton setTitleColor:[UIColor whiteColor]
                                forState:UIControlStateSelected];
        [self.followButton setTitleShadowColor:[UIColor colorWithRed:232.0f/255.0f green:203.0f/255.0f blue:168.0f/255.0f alpha:1.0f]
                                      forState:UIControlStateNormal];
        [self.followButton setTitleShadowColor:[UIColor blackColor]
                                      forState:UIControlStateSelected];
        self.followButton.titleLabel.shadowOffset = CGSizeMake( 0.0f, -1.0f);
        [self.followButton addTarget:self action:@selector(didTapFollowButtonAction:)
                    forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.followButton];
        */
        
        
    }
    return self;
}


#pragma mark - VYBVybesCell
- (void)setVybe:(PFObject *)aVybe {
    vybe = aVybe;
    
    // Configure the cell
    [thumbnailImageView setFile:[self.vybe objectForKey:kVYBVybeThumbnailKey]];
    [thumbnailImageView loadInBackground];
    
    // Set name
    NSString *nameString = [VYBUtility localizedDateStringFrom:[self.vybe objectForKey:kVYBVybeTimestampKey]];
    CGSize nameSize = [nameString boundingRectWithSize:CGSizeMake(144.0f, CGFLOAT_MAX)
                                               options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin
                                            attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:16.0f]}
                                               context:nil].size;
    [nameButton setTitle:nameString forState:UIControlStateNormal];
    [nameButton setTitle:nameString forState:UIControlStateHighlighted];
    
    [nameButton setFrame:CGRectMake( 60.0f, 17.0f, nameSize.width, nameSize.height)];
    
    // Set follow button
    //[followButton setFrame:CGRectMake( 208.0f, 20.0f, 103.0f, 32.0f)];
}


#pragma mark - ()

+ (CGFloat)heightForCell {
    return 67.0f;
}


/* Inform delegate that a user image or name was tapped */
- (void)didTapVybeButtonAction:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cell:didTapVybeButton:)]) {
        [self.delegate cell:self didTapVybeButton:self.vybe];
    }
}

/* Inform delegate that the follow button was tapped */
- (void)didTapFollowButtonAction:(id)sender {
    /*
     if (self.delegate && [self.delegate respondsToSelector:@selector(cell:didTapFollowButton:)]) {
     [self.delegate cell:self didTapFollowButton:self.user];
     }
     */
}


@end
