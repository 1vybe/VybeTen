//
//  UINavigationController+Fade.h
//  VybeTen
//
//  Created by jinsuk on 4/10/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UINavigationController (Fade)

- (void)pushFadeViewController:(UIViewController *)viewController;
- (void)fadePopViewController;

@end
