//
//  VYBNavigationController.m
//  VybeTen
//
//  Created by jinsuk on 6/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBNavigationController.h"
#import <MBProgressHUD/MBProgressHUD.h>

@implementation VYBNavigationController

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
  // To remove a navigation bar's back button text
  //self.navigationBar.topItem.title = @"";
  [super pushViewController:viewController animated:animated];
}

- (void)pushViewController:(UIViewController *)viewController
                  animated:(BOOL)animated
                completion:(void (^)(void))completion {
  [CATransaction begin];
  [CATransaction setCompletionBlock:completion];
  [self pushViewController:viewController animated:animated];
  [CATransaction commit];
}

- (void)popViewControllerAnimated:(BOOL)animated
                completion:(void (^)(void))completion {
  [CATransaction begin];
  [CATransaction setCompletionBlock:completion];
  [self popViewControllerAnimated:animated];
  [CATransaction commit];
}

- (BOOL)prefersStatusBarHidden {
  return [self.topViewController prefersStatusBarHidden];
}

- (BOOL)shouldAutorotate {
  return [self.topViewController shouldAutorotate];
}

- (NSUInteger)supportedInterfaceOrientations {
  return [self.topViewController supportedInterfaceOrientations];
}

@end
