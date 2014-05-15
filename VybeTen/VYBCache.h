//
//  VYBCache.h
//  VybeTen
//
//  Created by jinsuk on 5/10/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VYBCache : NSObject

@property (nonatomic, strong) NSCache *cache;

+ (id)sharedCache;

- (void)clear;
- (void)setFacebookFriends:(NSArray *)friends;
- (NSArray *)facebookFriends;

@end
