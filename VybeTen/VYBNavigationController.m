//
//  VYBNavigationController.m
//  VybeTen
//
//  Created by jinsuk on 6/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBNavigationController.h"
#import "VYBHubViewController.h"

@interface VYBNavigationController ()

@end

@implementation VYBNavigationController {
    NSInteger _pageIndex;
}

+ (VYBNavigationController *)navigationControllerForPageIndex:(NSInteger)pageIndex withRootViewController:(UIViewController *)rootViewController {
    if (pageIndex >= 0 && pageIndex < 3) {
        return [[self alloc] initWithPageIndex:pageIndex withRootViewController:rootViewController];
    }
    return nil;
}

+ (VYBNavigationController *)navigationControllerForPageIndex:(NSInteger)pageIndex {
    if (pageIndex == VYBHubPageIndex) {
        return [[self alloc] initWithPageIndex:pageIndex withRootViewController:nil];
    }
    return nil;
}


- (id)initWithPageIndex:(NSInteger)pageIndex withRootViewController:(UIViewController *)rootViewController {
    if (!rootViewController) {
        switch (pageIndex) {
            case VYBHubPageIndex:
                self = [[UIStoryboard storyboardWithName:@"HubStoryboard" bundle:nil] instantiateInitialViewController];
                break;
            default:
                break;
        }
    } else {
        self = [self initWithRootViewController:rootViewController];
    }
    
    if (self) {
        _pageIndex = pageIndex;
    }
    return self;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    // To remove a navigation bar's back button text 
    self.navigationBar.topItem.title = @"";
    [super pushViewController:viewController animated:animated];
}

- (NSInteger)pageIndex {
    return _pageIndex;
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

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [self.topViewController preferredInterfaceOrientationForPresentation];
}


@end
