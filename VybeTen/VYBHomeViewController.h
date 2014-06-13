//
//  VYBHomeViewController.h
//  VybeTen
//
//  Created by jinsuk on 6/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VYBNavigationController.h"

@interface VYBHomeViewController : UIViewController <VYBPageViewControllerProtocol, PFLogInViewControllerDelegate>

+ (VYBHomeViewController *)homeViewControllerForPageIndex:(NSInteger)pageIndex;
- (NSInteger)pageIndex;

- (void)facebookRequestDidLoad:(id)result;
- (void)facebookRequestDidFailWithError:(NSError *)error;

- (void)presentLoginViewController;
- (void)refreshUserData;
- (void)logOut;

@end
