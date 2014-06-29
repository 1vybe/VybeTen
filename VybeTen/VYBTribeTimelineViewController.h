//
//  VYBTribeVybesViewController.h
//  VybeTen
//
//  Created by jinsuk on 3/20/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VYBVybeCell.h"

@class VYBTribe;

@interface VYBTribeTimelineViewController : PFQueryTableViewController <VYBVybeCellDelegate>

@property (nonatomic, strong) PFObject *tribe;
@property (nonatomic, strong) PFObject *lastWatchedVybe;

- (void)moveToLastWatchtedVybeCell;

@end
