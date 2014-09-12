//
//  VYBVybeTableViewCell.h
//  VybeTen
//
//  Created by jinsuk on 8/22/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VYBActivityTableViewCell : UITableViewCell
@property (nonatomic, strong) IBOutlet UILabel *username;
@property (nonatomic, strong) IBOutlet UILabel *activity;
@property (nonatomic, strong) IBOutlet UIImageView *profilePic;
@property (nonatomic, strong) IBOutlet UIImageView *vybeThumbnail;
@end
