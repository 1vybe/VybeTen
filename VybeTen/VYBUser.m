//
//  VYBUser.m
//  VybeTen
//
//  Created by jinsuk on 7/28/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBUser.h"

@implementation VYBUser

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        [self setLastWatchedVybeTimeStamp:[aDecoder decodeObjectForKey:@"lastWatchedVybeTimeStamp"]];
    }
    return self;
}

- (id)init {
    self = [super init];
    
    if (self) {
        [self setLastWatchedVybeTimeStamp:[NSDate date]];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:[self lastWatchedVybeTimeStamp] forKey:@"lastWatchedVybeTimeStamp"];
}

@end
