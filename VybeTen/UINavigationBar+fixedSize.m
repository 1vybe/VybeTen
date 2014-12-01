//
//  UINavigationBar+fixedSize.m
//  VybeTen
//
//  Created by jinsuk on 9/25/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "UINavigationBar+fixedSize.h"
#import <objc/runtime.h>

#define FYIsIOSVersionGreaterThanOrEqualTo(v) \
([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@implementation UINavigationBar (fixedSize)

//- (CGSize)sizeThatFits_FixedHeightWhenStatusBarHidden:(CGSize)size {
//    if ([UIApplication sharedApplication].statusBarHidden && FYIsIOSVersionGreaterThanOrEqualTo(@"7.0")) {
//        CGSize newSize = CGSizeMake(self.frame.size.width, 64.0);
//        return newSize;
//    } else {
//        return [self sizeThatFits_FixedHeightWhenStatusBarHidden:size];
//    }
//}
//
//+ (void)load {
//    method_exchangeImplementations(class_getInstanceMethod(self, @selector(sizeThatFits:)), class_getInstanceMethod(self, @selector(sizeThatFits_FixedHeightWhenStatusBarHidden:)));
//}

@end
