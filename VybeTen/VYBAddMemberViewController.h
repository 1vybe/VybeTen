//
//  VYBFriendsViewController.h
//  VybeTen
//
//  Created by jinsuk on 5/4/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VYBFriendCell.h"

@interface VYBAddMemberViewController : PFQueryTableViewController <VYBFriendCellDelegate>

@property (nonatomic) PFObject *tribe;

- (id)initWithTribe:(PFObject *)aTribe;

@end
