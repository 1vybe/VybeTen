//
//  VYBMyTribeStore.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 8..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBMyTribeStore.h"

@implementation VYBMyTribeStore

+ (VYBMyTribeStore *)sharedStore {
    static VYBMyTribeStore *sharedStore = nil;
    if (!sharedStore)
        sharedStore = [[super allocWithZone:nil] init];
    
    return sharedStore;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [self sharedStore];
}

- (id)init {
    self = [super init];
  
    if (self) {
        myTribeVybes = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (NSArray *)myTribeVybes {
    return myTribeVybes;
}



@end
