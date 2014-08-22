//
//  UINavigationController+Autorotate.m
//  VybeTen
//
//  Created by jinsuk on 8/21/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "UINavigationController+Autorotate.h"

@implementation UINavigationController (Autorotate)

- (BOOL)shouldAutorotate {
    return [self.topViewController shouldAutorotate];
}

- (NSUInteger)supportedInterfaceOrientations {
    return [self.topViewController supportedInterfaceOrientations];
}


@end
