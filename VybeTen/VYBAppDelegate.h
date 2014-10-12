//
//  VYBAppDelegate.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 19..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "VYBNavigationController.h"
#import "VYBPageViewController.h"
#import "VYBLogInViewController.h"

@interface VYBAppDelegate : UIResponder <UIApplicationDelegate, UIPageViewControllerDataSource, VYBLogInViewControllerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong) VYBPageViewController *pageController;
@property (nonatomic, strong) VYBNavigationController *navController;
@property (nonatomic, strong) NSArray *viewControllers;
@property (nonatomic) VYBPlayerViewController *playerVC;

@property (nonatomic, readonly) int networkStatus;

- (BOOL)isParseReachable;
- (void)moveToPage:(NSInteger)pageIdx;

- (void)presentLoginViewController;
- (void)presentLoginViewControllerAnimated:(BOOL)animated;
- (void)presentPageViewController;

- (void)logOut;
@end
