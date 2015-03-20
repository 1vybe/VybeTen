//
//  NSArray+PFObject.m
//  VybeTen
//
//  Created by jinsuk on 9/5/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "NSArray+PFObject.h"
#import <Parse/PFObject.h>

@implementation NSArray (PFObject)

- (BOOL)containsPFObject:(PFObject *)obj {
    for (PFObject *pObj in self) {
        if ( [pObj.objectId isEqualToString:obj.objectId] )
            return YES;
    }
    return NO;
}

@end
