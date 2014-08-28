//
//  VYBRegionHeaderButton.h
//  VybeTen
//
//  Created by jinsuk on 8/21/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VYBRegionHeaderButton : UIButton
@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) IBOutlet UILabel *cityNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *followingCountLabel;
@property (nonatomic, strong) IBOutlet UIButton *unwatchedVybeButton;
@property (nonatomic, strong) IBOutlet UILabel *vybeCountLabel;
@property (nonatomic, strong) IBOutlet UIImageView *flagImageView;

@property (nonatomic) NSInteger sectionNumber;

+ (id)VYBRegionHeaderButton;
//- (IBAction)unwatchedVybeButtonPressed:(id)sender;
@end
