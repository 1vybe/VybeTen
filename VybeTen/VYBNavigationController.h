//
//  VYBNavigationController.h
//  VybeTen
//
//  Created by jinsuk on 6/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MBProgressHUD/MBProgressHUD.h>

@protocol VYBPageViewControllerProtocol <NSObject>

- (NSInteger)pageIndex;

@end

@interface VYBNavigationController : UINavigationController <VYBPageViewControllerProtocol, MBProgressHUDDelegate>

+ (VYBNavigationController *)navigationControllerForPageIndex:(NSInteger)pageIndex withRootViewController:(UIViewController *)rootViewController;
- (NSInteger)pageIndex;


@end
