//
//  VYBProfileViewController.h
//  VybeTen
//
//  Created by jinsuk on 8/22/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VYBActivityTableViewController : PFQueryTableViewController
@property (nonatomic, strong) PFObject *user;
- (IBAction)profileButtonPressed:(id)sender;
@end
