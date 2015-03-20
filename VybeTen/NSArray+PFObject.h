//
//  NSArray+PFObject.h
//  VybeTen
//
//  Created by jinsuk on 9/5/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

@class PFObject;

@interface NSArray (PFObject)
- (BOOL)containsPFObject:(PFObject *)obj;
@end
