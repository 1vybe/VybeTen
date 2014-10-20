//
//  VYBNavigationController.h
//  VybeTen
//
//  Created by jinsuk on 6/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MBProgressHUD/MBProgressHUD.h>

@interface VYBNavigationController : UINavigationController <MBProgressHUDDelegate>

@property (nonatomic, assign) IBInspectable NSInteger pageIndex;

+ (VYBNavigationController *)navigationControllerForPageIndex:(NSInteger)pageIndex withRootViewController:(UIViewController *)rootViewController;

@end
