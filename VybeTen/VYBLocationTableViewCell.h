//
//  VYBLocationTableViewCell.h
//  VybeTen
//
//  Created by jinsuk on 8/28/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VYBLocationTableViewCell : UITableViewCell
@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) NSString *locationKey;
@property (nonatomic) NSInteger vybeCount;
@property (nonatomic) NSInteger userCount;
@property (nonatomic) NSInteger freshVybeCount;
@end
