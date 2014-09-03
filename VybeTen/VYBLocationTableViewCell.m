//
//  VYBLocationTableViewCell.m
//  VybeTen
//
//  Created by jinsuk on 8/28/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBLocationTableViewCell.h"
#import "VYBCache.h"

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

- (void)setLocationKey:(NSString *)keyStr {
    //_locationString = locationString;
    
    NSArray *arr = [keyStr componentsSeparatedByString:@","];
    if (arr.count == 2) {
        cityNameLabel.text = arr[0];
        NSString *countryCode = arr[1];
        UIImage *flagImg = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", countryCode]];
        [flagImageView setImage:flagImg];
        
    }
}

- (void)setVybeCount:(NSInteger)vybeCount {
    _vybeCount = vybeCount;
    if ( _vybeCount > 1)
        vybeCountLabel.text = [NSString stringWithFormat:@"%d Vybes", _vybeCount];
    else
        vybeCountLabel.text = [NSString stringWithFormat:@"%d Vybe", _vybeCount];
}

- (void)setUserCount:(NSInteger)userCount {
    _userCount = userCount;
    
    followingCountLabel.text = [NSString stringWithFormat:@"%d Following", _userCount];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
