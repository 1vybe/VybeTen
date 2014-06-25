//
//  VYBFriendsCell.m
//  VybeTen
//
//  Created by jinsuk on 6/2/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBFriendCell.h"


@implementation VYBFriendCell


@synthesize delegate;
@synthesize user;
@synthesize avatarImageButton;
@synthesize avatarImageView;
@synthesize nameButton;
@synthesize tribeLabel;
@synthesize followButton;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        //self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.avatarImageView = [[PFImageView alloc] initWithFrame:CGRectMake(10.0f, 14.0f, 40.0f, 40.0f)];
        [self.contentView addSubview:self.avatarImageView];
        
        self.avatarImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.avatarImageButton.backgroundColor = [UIColor clearColor];
        self.avatarImageButton.frame = CGRectMake( 10.0f, 14.0f, 40.0f, 40.0f);
        [self.avatarImageButton addTarget:self action:@selector(didTapUserButtonAction:)
                         forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.avatarImageButton];

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
        [self.nameButton addTarget:self action:@selector(didTapUserButtonAction:)
                  forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.nameButton];
        
        self.tribeLabel = [[UILabel alloc] init];
        self.tribeLabel.font = [UIFont systemFontOfSize:11.0f];
        self.tribeLabel.textColor = [UIColor grayColor];
        self.tribeLabel.backgroundColor = [UIColor clearColor];
        self.tribeLabel.shadowColor = [UIColor colorWithWhite:1.0f alpha:0.7f];
        self.tribeLabel.shadowOffset = CGSizeMake( 0.0f, 1.0f);
        [self.contentView addSubview:self.tribeLabel];
        
        self.followButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [followButton setFrame:CGRectMake( 208.0f, 20.0f, 50.0f, 50.0f)];
        [self.followButton setImage:[UIImage imageNamed:@"button_follow.png"] forState:UIControlStateNormal];
        [self.followButton setImage:[UIImage imageNamed:@"button_following.png"] forState:UIControlStateSelected];
        [self.followButton addTarget:self action:@selector(didTapFollowButtonAction:)
                    forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.followButton];
    }
    return self;
}


#pragma mark - VYBFriendsCell
- (void)setUser:(PFUser *)aUser {
    user = aUser;
    
    // Configure the cell
    [avatarImageView setFile:[self.user objectForKey:kVYBUserProfilePicSmallKey]];
    [avatarImageView loadInBackground];
    
    // Set name
    NSString *nameString = [self.user objectForKey:kVYBUserDisplayNameKey];
    CGSize nameSize = [nameString boundingRectWithSize:CGSizeMake(144.0f, CGFLOAT_MAX)
                                               options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin
                                            attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:16.0f]}
                                               context:nil].size;
    [nameButton setTitle:[self.user objectForKey:kVYBUserDisplayNameKey] forState:UIControlStateNormal];
    [nameButton setTitle:[self.user objectForKey:kVYBUserDisplayNameKey] forState:UIControlStateHighlighted];
    
    [nameButton setFrame:CGRectMake( 60.0f, 17.0f, nameSize.width, nameSize.height)];
    
    // Set photo number label
    CGSize tribeLabelSize = [@"tribes" boundingRectWithSize:CGSizeMake(144.0f, CGFLOAT_MAX)
                                                    options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin
                                                 attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:11.0f]}
                                                    context:nil].size;
    [tribeLabel setFrame:CGRectMake( 60.0f, 17.0f + nameSize.height, 140.0f, tribeLabelSize.height)];
}


#pragma mark - ()

+ (CGFloat)heightForCell {
    return 67.0f;
}


/* Inform delegate that a user image or name was tapped */
- (void)didTapUserButtonAction:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cell:didTapUserButton:)]) {
        [self.delegate cell:self didTapUserButton:self.user];
    }
}

/* Inform delegate that the follow button was tapped */
- (void)didTapFollowButtonAction:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cell:didTapFollowButton:)]) {
        [self.delegate cell:self didTapFollowButton:self.user];
    }
}


@end
