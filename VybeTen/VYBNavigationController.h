//
//  VYBNavigationController.h
//  VybeTen
//
//  Created by jinsuk on 6/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VYBPageViewControllerProtocol <NSObject>

- (NSInteger)pageIndex;

@end

@interface VYBNavigationController : UINavigationController <VYBPageViewControllerProtocol>

+ (VYBNavigationController *)navigationControllerForPageIndex:(NSInteger)pageIndex withRootViewController:(UIViewController *)rootViewController;
- (NSInteger)pageIndex;

@end
