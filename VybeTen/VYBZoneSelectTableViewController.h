//
//  VYBZoneSelectTableViewController.h
//  VybeTen
//
//  Created by jinsuk on 11/3/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VYBZoneSelectTableViewController : UITableViewController
@property (nonatomic) NSArray *suggestions;
@property (nonatomic, weak) id delegate;
@end
