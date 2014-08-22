//
//  VYBRegionHeaderButton.h
//  VybeTen
//
//  Created by jinsuk on 8/21/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VYBRegionHeaderButton : UIButton
@property (nonatomic, strong) IBOutlet UILabel *regionNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *regionUserCountLabel;
@property (nonatomic) NSInteger sectionNumber;

+ (id)VYBRegionHeaderButton;
@end
