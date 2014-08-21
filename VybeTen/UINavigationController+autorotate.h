//
//  UINavigationController+autorotate.h
//  VybeTen
//
//  Created by jinsuk on 8/21/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UINavigationController (autorotate)
- (BOOL)shouldAutorotate;
- (NSUInteger)supportedInterfaceOrientations;

@end
