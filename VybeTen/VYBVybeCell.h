//
//  VYBVybeCell.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 26..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VYBVybeCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UIImageView *thumbnailImageView;
@property (nonatomic, weak) UILabel *labelTitle;
- (void)customize;
- (void)customizeOtherDirection;
- (void)customizeWithTitle:(NSString *)title;
@end
