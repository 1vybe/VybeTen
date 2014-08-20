//
//  VYBRegionTableViewCell.h
//  VybeTen
//
//  Created by jinsuk on 8/19/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VYBRegionTableViewCell : UITableViewCell
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UILabel *vybeCountLabel;
@property (nonatomic, strong) IBOutlet UILabel *userCountLabel;
- (void)setName:(NSString *)aName;
- (void)setVybeCount:(NSNumber *)aNum;
- (void)setUserCount:(NSNumber *)aNum;
@end
