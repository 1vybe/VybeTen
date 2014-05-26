//
//  VYBFriendsViewController.h
//  VybeTen
//
//  Created by jinsuk on 5/4/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VYBAddMemberViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, readonly) NSArray *objects;
@property (nonatomic) PFObject *currTribe;

@end
