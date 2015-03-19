//
//  UIStoryboard+Vybe.m
//  VybeTen
//
//  Created by Jinsu Kim on 1/26/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

#import "UIStoryboard+Vybe.h"

@implementation UIStoryboard (Vybe)

+ (UIStoryboard *)homeStoryboard {
  return [UIStoryboard storyboardWithName:@"Home" bundle:[NSBundle mainBundle]];
}

+ (UIStoryboard *)captureStoryboard {
  return [UIStoryboard storyboardWithName:@"Capture" bundle:[NSBundle mainBundle]];
}

@end
