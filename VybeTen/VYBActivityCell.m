//
//  VYBActivityCell.m
//  VybeTen
//
//  Created by jinsuk on 6/29/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBActivityCell.h"
#import "VYBActivityViewController.h"
#import "VYBUtility.h"

@implementation VYBActivityCell
@synthesize delegate;
@synthesize activity;
@synthesize nameLabel;
@synthesize tribeButton;
@synthesize summaryTextView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.nameLabel = [[UILabel alloc] init];
        [self.contentView addSubview:self.nameLabel];

        self.tribeLabel = [[UILabel alloc] init];
        [self.contentView addSubview:self.tribeLabel];
        
        self.tribeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [tribeButton addTarget:self action:@selector(didTapTribeButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.tribeButton];
        
        self.summaryTextView = [[UITextView alloc] init];
        self.summaryTextView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.summaryTextView];
        
        self.dateLabel = [[UILabel alloc] init];
        [self.contentView addSubview:self.dateLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.nameLabel setFrame:CGRectMake(0, 0, 80, 30)];
    
    [self.summaryTextView setFrame:CGRectMake(80, 0, [UIScreen mainScreen].bounds.size.width - 200, 30)];
    
    [self.tribeLabel setFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width - 120, 0, 120, 30)];
    [self.tribeButton setFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width - 120, 0, 120, 30)];
    
    [self.dateLabel setFrame:CGRectMake(0, 30, 100, 20)];
}

- (void)setActivity:(PFObject *)obj {
    activity = obj;
    
    if ([[obj parseClassName] isEqualToString:kVYBVybeClassKey]) {
        PFObject *user = [obj objectForKey:kVYBVybeUserKey];
        if (user) {
            self.nameLabel.text = user[kVYBUserDisplayNameKey];
        } else {
            self.nameLabel.text = @"Someone";
        }
        
        NSString *summary = [VYBActivityViewController stringForActivity:obj];
        if (summary) {
            self.summaryTextView.text = summary;
        }
        
        PFObject *tribe = activity[kVYBVybeTribeKey];
        if (tribe) {
            self.tribeLabel.text = tribe[kVYBTribeNameKey];
        }
        
        self.dateLabel.text = [VYBUtility localizedDateStringFrom:activity.createdAt];
    }
    
    if ([[obj parseClassName] isEqualToString:kVYBTribeClassKey]) {
        PFObject *user = [obj objectForKey:kVYBTribeCreatorKey];
        if (user) {
            self.nameLabel.text = user[kVYBUserDisplayNameKey];
        } else {
            self.nameLabel.text = @"Someone";
        }
        
        NSString *summary = [VYBActivityViewController stringForActivity:obj];
        if (summary) {
            self.summaryTextView.text = summary;
        }
        
        self.tribeLabel.text = activity[kVYBTribeNameKey];
        
        self.dateLabel.text = [VYBUtility localizedDateStringFrom:activity.createdAt];
    }
   
}

- (void)setIsNew:(BOOL)isNew {
    if (isNew) {
        self.summaryTextView.backgroundColor = [UIColor grayColor];
    } else {
        self.summaryTextView.backgroundColor = [UIColor clearColor];
    }
}


- (void)didTapTribeButton:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cell:didTapTribeButton:)]) {
        [self.delegate cell:self didTapTribeButton:self.activity];
    }
}

+ (CGFloat)heightForCell {
    return 50.0f;
}


@end
