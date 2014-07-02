//
//  VYBActivityCell.h
//  VybeTen
//
//  Created by jinsuk on 6/29/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Parse/Parse.h>

@protocol VYBActivityCellDelegate;

@interface VYBActivityCell : PFTableViewCell
@property (nonatomic, strong) id <VYBActivityCellDelegate> delegate;
@property (nonatomic, strong) PFObject *activity;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UITextView *summaryTextView;
@property (nonatomic, strong) UILabel *tribeLabel;
@property (nonatomic, strong) UIButton *tribeButton;
@property (nonatomic, strong) UILabel *dateLabel;

- (void)setActivity:(PFObject *)obj;
- (void)setIsNew:(BOOL)isNew;
- (void)didTapTribeButton:(id)sender;
+ (CGFloat)heightForCell;

@end

@protocol VYBActivityCellDelegate <NSObject>
@optional
- (void)cell:(VYBActivityCell *)cell didTapTribeButton:(PFObject *)aActivity;
@end
