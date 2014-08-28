//
//  VYBLocationTableViewCell.m
//  VybeTen
//
//  Created by jinsuk on 8/28/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBLocationTableViewCell.h"

@interface VYBLocationTableViewCell ()
@property (nonatomic, weak) id delegate;

@property (nonatomic, strong) IBOutlet UILabel *cityNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *followingCountLabel;
@property (nonatomic, strong) IBOutlet UIButton *unwatchedVybeButton;
@property (nonatomic, strong) IBOutlet UILabel *vybeCountLabel;
@property (nonatomic, strong) IBOutlet UIImageView *flagImageView;
@end

@implementation VYBLocationTableViewCell
@synthesize cityNameLabel, followingCountLabel, unwatchedVybeButton, vybeCountLabel, flagImageView;

- (void)awakeFromNib {
    // Initialization code
}

- (void)setLocationString:(NSString *)locationString {
    //_locationString = locationString;
    
    NSArray *arr = [locationString componentsSeparatedByString:@","];
    if (arr.count == 3) {
        cityNameLabel.text = arr[1];
        NSString *countryCode = arr[2];
        UIImage *flagImg = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", countryCode]];
        [flagImageView setImage:flagImg];
    }
}

- (void)setVybeCount:(NSInteger)vybeCount {
    //_vybeCount = vybeCount;
    vybeCountLabel.text = [NSString stringWithFormat:@"%d Vybes", vybeCount];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
