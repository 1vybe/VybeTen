//
//  VYBFollowingTableViewController.h
//  VybeTen
//
//  Created by jinsuk on 8/28/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VYBFollowingTableViewController : PFQueryTableViewController

- (void)watchNewVybesFromUser:(NSString *)aUserID;

@end
