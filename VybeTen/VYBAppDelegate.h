//
//  VYBAppDelegate.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 19..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "VYBMainPageViewController.h"

@class VYBWelcomeViewController;

@interface VYBAppDelegate : UIResponder <UIApplicationDelegate, PFLogInViewControllerDelegate, UIPageViewControllerDataSource>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) UINavigationController *navController;
@property (nonatomic, strong) UIPageViewController *pageController;
@property (nonatomic, strong) VYBWelcomeViewController *welcomeViewController;

/* TODO */
@property (nonatomic, readonly) int networkStatus;
- (BOOL)isParseReachable;

- (void)facebookRequestDidLoad:(id)result;
- (void)facebookRequestDidFailWithError:(NSError *)error;

- (void)presentLoginViewController;
- (void)presentLoginViewControllerAnimated:(BOOL)animated;
- (void)fetchCurrentUserData;
- (void)logOut;

@end
