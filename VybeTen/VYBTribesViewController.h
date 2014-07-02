//
//  VYBTribesViewController.h
//  VybeTen
//
//  Created by jinsuk on 4/14/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VYBTribeCell.h"
#import "VYBCreateTribeViewController.h"

@interface VYBTribesViewController : PFQueryTableViewController <VYBTribeCellDelegate, VYBCreateTribeViewControllerDelegate>


@end
