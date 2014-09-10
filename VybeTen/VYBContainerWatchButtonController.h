//
//  VYBContainerWatchButtonController.h
//  VybeTen
//
//  Created by jinsuk on 9/9/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VYBUsersTableViewController.h"

@interface VYBContainerWatchButtonController : UIViewController
@property (nonatomic) NSString *locationKey;
@property (nonatomic) PFObject *userKey;
@property (nonatomic, weak) VYBUsersTableViewController *embeddedController;

- (void)freshVybeCountChanged;

@end
