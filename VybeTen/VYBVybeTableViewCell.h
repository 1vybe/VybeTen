//
//  VYBVybeTableViewCell.h
//  VybeTen
//
//  Created by jinsuk on 8/22/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Zone;
@interface VYBVybeTableViewCell : PFTableViewCell

@property (nonatomic, weak) IBOutlet UILabel *timestampLabel;
@property (nonatomic, weak) IBOutlet UILabel *locationLabel;
@property (nonatomic, weak) IBOutlet PFImageView *thumbnailImageView;
@property (nonatomic, weak) IBOutlet UIView *separatorLineView;
@property (nonatomic, weak) IBOutlet UIImageView *greenLightSavedVybe;
- (void)setUnwatched:(BOOL)unwatched;
@end
