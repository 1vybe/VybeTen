//
//  NSMutableArray+PFObject.h
//  VybeTen
//
//  Created by jinsuk on 9/5/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//
@class PFObject;

@interface NSMutableArray (PFObject)
- (void)removePFObject:(PFObject *)pObj;
- (void)addPFObject:(PFObject *)pObj;

@end
