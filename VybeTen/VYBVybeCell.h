//
//  VYBVybeCell.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 26..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VYBVybeCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UIImageView *thumbnailView;
@property (nonatomic, weak) UILabel *labelTitle;
@property (nonatomic, strong) UIButton *buttonDelete;
@property (nonatomic, strong) UIView *topLayer;
@property (nonatomic, assign) CGFloat firstX;
@property (nonatomic, assign) CGFloat firstY;

- (void)customize;
- (void)customizeWithTitle:(NSString *)title;
@end
