//
//  VYBVybeCell.h
//  VybeTen
//
//  Created by jinsuk on 6/2/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VYBVybeCellDelegate;

@interface VYBVybeCell : PFTableViewCell

@property (nonatomic, strong) id <VYBVybeCellDelegate> delegate;

@property (nonatomic, strong) PFObject *vybe;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) UIButton *nameButton;
@property (nonatomic, strong) UIButton *thumbnailImageButton;
@property (nonatomic, strong) PFImageView *thumbnailImageView;

- (void)setVybe:(PFObject *)vybe;
- (void)didTapVybeButtonAction:(id)sender;
- (void)didTapFollowButtonAction:(id)sender;

+ (CGFloat)heightForCell;

@end

@protocol VYBVybeCellDelegate <NSObject>
@optional
- (void)cell:(VYBVybeCell *)cellView didTapVybeButton:(PFObject *)aVybe;
- (void)cell:(VYBVybeCell *)cellView didTapFollowButton:(PFObject *)aVybe;

@end