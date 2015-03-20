//
//  VYBNavigationController.h
//  VybeTen
//
//  Created by jinsuk on 6/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

@interface VYBNavigationController : UINavigationController

@property (nonatomic, assign) IBInspectable NSInteger pageIndex;

- (void)pushViewController:(UIViewController *)viewController
                  animated:(BOOL)animated
                completion:(void (^)(void))completion;

- (void)popViewControllerAnimated:(BOOL)animated
                completion:(void (^)(void))completion;
@end
