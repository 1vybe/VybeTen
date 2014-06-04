//
//  VYBFriendsCell.h
//  VybeTen
//
//  Created by jinsuk on 6/2/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VYBFriendsCellDelegate;

@interface VYBFriendsCell : PFTableViewCell {
    //id _delegate;
}

@property (nonatomic, strong) id <VYBFriendsCellDelegate> delegate;

@property (nonatomic, strong) PFUser *user;
@property (nonatomic, strong) UILabel *tribeLabel;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) UIButton *nameButton;
@property (nonatomic, strong) UIButton *avatarImageButton;
@property (nonatomic, strong) PFImageView *avatarImageView;

- (void)setUser:(PFUser *)user;
- (void)didTapUserButtonAction:(id)sender;
- (void)didTapFollowButtonAction:(id)sender;

+ (CGFloat)heightForCell;

@end

@protocol VYBFriendsCellDelegate <NSObject>
@optional
- (void)cell:(VYBFriendsCell *)cellView didTapUserButton:(PFUser *)aUser;
- (void)cell:(VYBFriendsCell *)cellView didTapFollowButton:(PFUser *)aUser;

@end