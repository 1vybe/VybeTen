//
//  VYBNavigationController.m
//  VybeTen
//
//  Created by jinsuk on 6/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBNavigationController.h"

@implementation VYBNavigationController

+ (VYBNavigationController *)navigationControllerForPageIndex:(NSInteger)pageIndex withRootViewController:(UIViewController *)rootViewController {
  if (pageIndex >= 0 && pageIndex < 3) {
    return [[self alloc] initWithPageIndex:pageIndex withRootViewController:rootViewController];
  }
  return nil;
}

- (id)initWithPageIndex:(NSInteger)pageIndex withRootViewController:(UIViewController *)rootViewController {
  self = [super initWithRootViewController:rootViewController];
  if (self) {
    _pageIndex = pageIndex;
  }
  
  return self;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
  // To remove a navigation bar's back button text
  //self.navigationBar.topItem.title = @"";
  [super pushViewController:viewController animated:animated];
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
