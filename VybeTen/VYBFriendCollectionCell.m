//
//  VYBFriendCollectionCell.m
//  VybeTen
//
//  Created by jinsuk on 5/19/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBFriendCollectionCell.h"

@implementation VYBFriendCollectionCell
@synthesize delegate, user, profilePictureButton, profilePictureView, nameButton, followButton;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.5]];
        
        profilePictureView = [[PFImageView alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
        [profilePictureView setImage:[UIImage imageNamed:@"user_avatar.png"]];
        [self.contentView addSubview:profilePictureView];
        
        profilePictureButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
        [profilePictureButton setBackgroundColor:[UIColor clearColor]];
        //[profilePictureButton addTarget:self action:@selector(didTapUserButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:profilePictureButton];
        
        self.nameButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.nameButton.backgroundColor = [UIColor clearColor];
        self.nameButton.titleLabel.font = [UIFont fontWithName:@"Montreal-Xlight" size:18.0f];
        self.nameButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self.nameButton setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.3]
                              forState:UIControlStateNormal];
        [self.nameButton setTitleColor:[UIColor whiteColor]
                              forState:UIControlStateHighlighted];
        //[self.nameButton addTarget:self action:@selector(didTapUserButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.nameButton];

    
        self.followButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.followButton.titleLabel.font = [UIFont fontWithName:@"Montreal-Xlight" size:18.0f];
        [self.followButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [self.followButton setTitle:@"Follow"
                           forState:UIControlStateNormal];
        [self.followButton setTitle:@"Following"
                           forState:UIControlStateSelected];
        [self.followButton setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5]
                                forState:UIControlStateNormal];
        [self.followButton setTitleColor:[UIColor whiteColor]
                                forState:UIControlStateSelected];
        [self.followButton addTarget:self action:@selector(didTapFollowButton:)
                    forControlEvents:UIControlEventTouchUpInside];
        //[self.contentView addSubview:self.followButton];
    }
    
    return self;
}

- (void)setUser:(PFUser *)aUser {
    user = aUser;
    PFFile *profileFile = user[kVYBUserProfilePicSmallKey];
    if (profileFile) {
        [profilePictureView setFile:profileFile];
        [profilePictureView loadInBackground];
    }
    
    NSString *nameString = user[kVYBUserDisplayNameKey];
    CGSize nameSize = [nameString boundingRectWithSize:CGSizeMake(130.0f, CGFLOAT_MAX)
                                               options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin
                                            attributes:@{NSFontAttributeName:[UIFont fontWithName:@"Montreal-Xlight" size:18.0f]}
                                               context:nil].size;
    NSLog(@"nameLabel: %@", NSStringFromCGSize(nameSize));
    [self.nameButton setTitle:user[kVYBUserDisplayNameKey] forState:UIControlStateNormal];
    [self.nameButton setTitle:user[kVYBUserDisplayNameKey] forState:UIControlStateHighlighted];
    [nameButton setFrame:CGRectMake( 80.0f, 10.0f, nameSize.width, nameSize.height)];

    //[followButton setFrame:CGRectMake( 80.0f, 30, 103.0f, 40.0f)];
}

+ (CGFloat)heightForCell {
    return 80.0f;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if (selected) {
        [self.contentView setBackgroundColor:[UIColor orangeColor]];
    } else {
        [self.contentView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.5]];
    }
}

- (void)didTapUserButton:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didTapUserButton:)]) {
        [self.delegate performSelector:@selector(didTapUserButton:) withObject:self.user];
    }
}

- (void)didTapFollowButton:(id)sender {
    
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
