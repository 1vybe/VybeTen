//
//  VYBTribesViewController.h
//  VybeTen
//
//  Created by jinsuk on 4/14/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VYBPageViewControllerProtocol;
@interface VYBTribesViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, VYBPageViewControllerProtocol>

+ (id)tribesViewControllerForPageIndex:(NSInteger)pageIndex;
- (NSInteger)pageIndex;

@end
