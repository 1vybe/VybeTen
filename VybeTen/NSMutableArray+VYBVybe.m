//
//  NSMutableArray+VYBVybe.m
//  VybeTen
//
//  Created by Jinsu Kim on 11/24/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "NSMutableArray+VYBVybe.h"
#import "VYBVybe.h"

@implementation NSMutableArray (VYBVybe)
- (void)addVybeObject:(VYBVybe *)aVybe {
  for (VYBVybe *obj in self) {
    if (obj.uniqueFileName == aVybe.uniqueFileName) {
      NSLog(@"Cannot add the same vybe");
      return;
    }
  }
  [self addObject:aVybe];
}
- (void)removeVybeObject:(VYBVybe *)aVybe {
  for (VYBVybe *obj in self) {
    if (obj.uniqueFileName == aVybe.uniqueFileName) {
      [self removeObject:obj];
      return;
    }
  }
}
@end
