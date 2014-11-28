//
//  VYBAppDelegate.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 19..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "VybeTen-Swift.h"
#import "VYBNavigationController.h"
#import "VYBPageViewController.h"

@class VYBPlayerViewController;
@interface VYBAppDelegate : UIResponder <UIApplicationDelegate, UIPageViewControllerDataSource, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong) NSArray *viewControllers;
@property (nonatomic) VYBPlayerViewController *playerVC;

@property (nonatomic, readonly) int networkStatus;

- (BOOL)isParseReachable;
- (void)moveToPage:(NSInteger)pageIdx;

- (void)presentFirstPage;
- (void)proceedToMainInterface;
- (void)logOut;
@end
