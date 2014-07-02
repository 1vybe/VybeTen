//
//  VYBActivityViewController.h
//  VybeTen
//
//  Created by jinsuk on 5/30/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VYBActivityCell.h"

@interface VYBActivityViewController : PFQueryTableViewController <VYBActivityCellDelegate>

+ (NSString *)stringForActivity:(PFObject *)aActivity;

@end
