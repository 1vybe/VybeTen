//
//  VYBFriendCollectionCell.h
//  VybeTen
//
//  Created by jinsuk on 5/19/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PFImageView;
@protocol VYBFriendCollectionCellDelegate;

@interface VYBFriendCollectionCell : UICollectionViewCell {
    id _delegate;
}

@property (nonatomic,strong) id<VYBFriendCollectionCellDelegate> delegate;
@property (nonatomic, strong) PFUser *user;
@property (nonatomic, strong) UIButton *nameButton;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) UIButton *profilePictureButton;
@property (nonatomic, strong) PFImageView *profilePictureView;

- (void)setUser:(PFUser *)user;
- (void)didTapUserButton:(id)sender;
- (void)didTapFollowButton:(id)sender;

+ (CGFloat)heightForCell;

@end

@protocol VYBFriendCollectionCellDelegate <NSObject>
@optional

- (void)cell:(VYBFriendCollectionCell *)cellView didTapUserButton:(PFUser *)aUser;
- (void)cell:(VYBFriendCollectionCell *)cellView didTapFollowButton:(PFUser *)aUser;

@end

