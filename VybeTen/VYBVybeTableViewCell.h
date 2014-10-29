//
//  VYBVybeTableViewCell.h
//  VybeTen
//
//  Created by jinsuk on 8/22/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VYBVybeTableViewCell : PFTableViewCell

@property (nonatomic, weak) IBOutlet UILabel *timestampLabel;
@property (nonatomic, weak) IBOutlet UILabel *locationLabel;
@property (nonatomic, weak) IBOutlet UILabel *nearbyCountLabel;
@property (nonatomic, weak) IBOutlet UILabel *viewCountLabel;
@property (nonatomic, weak) IBOutlet PFImageView *thumbnailImageView;

@end
