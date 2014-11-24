//
//  NSMutableArray+VYBVybe.h
//  VybeTen
//
//  Created by Jinsu Kim on 11/24/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>
@class VYBVybe;
@interface NSMutableArray (VYBVybe)
- (void)addVybeObject:(VYBVybe *)aVybe;
- (void)removeVybeObject:(VYBVybe *)aVybe;
@end
