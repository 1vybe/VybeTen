//
//  VYBSyncTribeTableViewController.h
//  VybeTen
//
//  Created by jinsuk on 4/13/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VYBCreateTribeViewController.h"

@interface VYBSyncTribeViewController : PFQueryTableViewController <VYBCreateTribeViewControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@end
