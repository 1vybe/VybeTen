//
//  VYBUserTableViewCell.h
//  VybeTen
//
//  Created by jinsuk on 8/21/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VYBUserTableViewCell : PFTableViewCell
@property (nonatomic, strong) IBOutlet UIImageView *profileImageView;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UIButton *watchNewButton;
@property (nonatomic, strong) IBOutlet UILabel *countLabel;
@property (nonatomic, weak) id delegate;
@property (nonatomic) NSString *userObjID;
@property (nonatomic) NSInteger freshVybeCount;

@end
