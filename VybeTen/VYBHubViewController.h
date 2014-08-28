//
//  VYBHubViewController.h
//  VybeTen
//
//  Created by jinsuk on 8/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Parse/Parse.h>
#import "VYBLocationTableViewController.h"
@interface VYBHubViewController : UIViewController <UISearchDisplayDelegate, UISearchBarDelegate>
@property (nonatomic, strong) IBOutlet UIView *controlView;
@property (nonatomic, strong) IBOutlet UIButton *locationButton;
@property (nonatomic, strong) IBOutlet UIButton *followingButton;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@end
