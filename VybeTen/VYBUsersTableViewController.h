//
//  VYBUsersTableViewController.h
//  VybeTen
//
//  Created by jinsuk on 8/28/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VYBUsersTableViewController : UITableViewController
@property (nonatomic, weak) id delegate;
@property (nonatomic) NSString *locationKey;
@property (nonatomic) NSArray *freshVybes;

- (void)watchNewVybesFromUser:(NSString *)aUserID;

@end
