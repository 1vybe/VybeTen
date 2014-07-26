
//
//  VYBNavigationController.m
//  VybeTen
//
//  Created by jinsuk on 6/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBNavigationController.h"

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

- (id)initWithPageIndex:(NSInteger)pageIndex withRootViewController:(UIViewController *)rootViewController {
    self = [self initWithRootViewController:rootViewController];
    if (self) {
        _pageIndex = pageIndex;
    }
    return self;
}

- (NSInteger)pageIndex {
    return _pageIndex;
}

- (void)showToastWithImage:(UIImage *)aIamge title:(NSString *)title {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:aIamge];
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:hud];
    hud.mode = MBProgressHUDModeCustomView;
    hud.customView = imageView;
    hud.delegate = self;
    hud.labelText = @"Posted";
    [hud show:YES];
    [hud hide:YES afterDelay:0.5];
}

- (BOOL)shouldAutorotate {
    return [self.topViewController shouldAutorotate];
}

- (NSUInteger)supportedInterfaceOrientations {
    return [self.topViewController supportedInterfaceOrientations];
}

@end
