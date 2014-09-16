//
//  VYBProfileInfoView.h
//  VybeTen
//
//  Created by jinsuk on 8/22/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VYBProfileInfoView : UIView
@property (nonatomic, strong) id delegate;
@property (nonatomic, strong) IBOutlet UILabel *followersLabel;
@property (nonatomic, strong) IBOutlet UILabel *followingLabel;
@property (nonatomic, strong) IBOutlet UIImageView *profileImageView;
@end
