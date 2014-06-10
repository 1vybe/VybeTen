//
//  VYBTribesCell.h
//  VybeTen
//
//  Created by jinsuk on 6/2/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VYBTribeCellDelegate;

@interface VYBTribeCell : PFTableViewCell

@property (nonatomic, strong) id <VYBTribeCellDelegate> delegate;

@property (nonatomic, strong) PFObject *tribe;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) UIButton *nameButton;
@property (nonatomic, strong) UIButton *thumbnailImageButton;
@property (nonatomic, strong) PFImageView *thumbnailImageView;

- (void)setTribe:(PFObject *)tribe;
- (void)didTapTribeButtonAction:(id)sender;
- (void)didTapFollowButtonAction:(id)sender;

+ (CGFloat)heightForCell;

@end

@protocol VYBTribeCellDelegate <NSObject>
@optional
- (void)cell:(VYBTribeCell *)cellView didTapTribeButton:(PFObject *)aTribe;
- (void)cell:(VYBTribeCell *)cellView didTapFollowButton:(PFObject *)aTribe;

@end