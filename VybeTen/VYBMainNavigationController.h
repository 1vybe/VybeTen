//
//  VYBMainNavigationController.h
//  VybeTen
//
//  Created by jinsuk on 3/28/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VYBAnimator.h"

@interface VYBMainNavigationController : UINavigationController <UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UINavigationController *navigationController;
@property (strong, nonatomic) VYBAnimator *animator;
@property (strong, nonatomic) UIPercentDrivenInteractiveTransition* interactionController;
@property (nonatomic, strong) UIToolbar *bottomBar;

@end
