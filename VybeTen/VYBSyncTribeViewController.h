//
//  VYBSyncTribeTableViewController.h
//  VybeTen
//
//  Created by jinsuk on 4/13/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@class  VYBTribe;

@interface VYBSyncTribeViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, copy) void (^completionBlock)(VYBTribe *tribe);

- (void)setCompletionBlock:(void (^) (VYBTribe *tribe))block;

@end
