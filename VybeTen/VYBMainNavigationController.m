//
//  VYBMainNavigationController.m
//  VybeTen
//
//  Created by jinsuk on 3/28/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBMainNavigationController.h"

@implementation VYBMainNavigationController
@synthesize bottomBar = _bottomBar;

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC {
    if (operation == UINavigationControllerOperationPop) {
        return self.animator;
    }
    return nil;
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController {
    return self.interactionController;
}



@end
