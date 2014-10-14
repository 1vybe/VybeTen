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
@property (nonatomic, strong) IBOutlet UIButton *watchFreshButton;
@property (nonatomic, strong) IBOutlet UILabel *cityNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *followingCountLabel;
@property (nonatomic, strong) IBOutlet UILabel *vybeCountLabel;
@property (nonatomic, strong) IBOutlet UIImageView *flagImageView;

- (IBAction)watchFreshButtonPressed:(id)sender;

@end

@implementation VYBLocationTableViewCell
@synthesize cityNameLabel, followingCountLabel, watchFreshButton, vybeCountLabel, flagImageView;

- (void)awakeFromNib {
    // Initialization code
}

- (void)setLocationKey:(NSString *)keyStr {
    _locationKey = keyStr;
    
    if (_locationKey && [_locationKey length] > 0) {
        NSArray *arr = [keyStr componentsSeparatedByString:@","];
        if (arr.count == 2) {
#warning temporary fix
            if ([arr[0] isEqualToString:@"(null)"]) {
                cityNameLabel.text = @"Unknown";
                [flagImageView setImage:[UIImage imageNamed:@"unknown_country_flag.png"]];
            }
            else {
                cityNameLabel.text = arr[0];
                NSString *countryCode = arr[1];
                UIImage *flagImg = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", countryCode]];
                [flagImageView setImage:flagImg];
            }
        }
    }
}

- (void)setVybeCount:(NSInteger)vybeCount {
    _vybeCount = vybeCount;
    if ( _vybeCount > 1)
        vybeCountLabel.text = [NSString stringWithFormat:@"%ld Vybes", (long)_vybeCount];
    else
        vybeCountLabel.text = [NSString stringWithFormat:@"%ld Vybe", (long)_vybeCount];
}

- (void)setUserCount:(NSInteger)userCount {
    _userCount = userCount;

    followingCountLabel.text = [NSString stringWithFormat:@"%ld Following", (long)_userCount];
}

- (void)setFreshVybeCount:(NSInteger)freshVybeCount {
    _freshVybeCount = freshVybeCount;
    
    watchFreshButton.hidden = !_freshVybeCount;
    
    [watchFreshButton setTitle:[NSString stringWithFormat:@"%ld", (long)_freshVybeCount] forState:UIControlStateNormal];
}

- (IBAction)watchFreshButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(watchNewVybesFromLocation:)]) {
        [self.delegate performSelector:@selector(watchNewVybesFromLocation:) withObject:_locationKey];
    }
}

@end
