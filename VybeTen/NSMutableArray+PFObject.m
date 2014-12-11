//
//  NSMutableArray+PFObject.m
//  VybeTen
//
//  Created by jinsuk on 9/5/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "NSMutableArray+PFObject.h"

@implementation NSMutableArray (PFObject)

- (void)removePFObject:(PFObject *)pObj {
    for (PFObject *obj in self) {
        if ( [obj.objectId isEqualToString:pObj.objectId] ) {
            [self removeObject:obj];
            return;
        }
    }
}

- (void)addPFObject:(PFObject *)aVybe {
  for (PFObject *obj in self) {
    if ([obj.objectId isEqualToString:aVybe.objectId]) {
      return;
    }
  }
  [self addObject:aVybe];
}

@end
