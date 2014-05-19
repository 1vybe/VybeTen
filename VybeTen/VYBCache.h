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

- (NSDictionary *)attributesForUser:(PFUser *)user;
- (NSNumber *)vybeCountForUser:(PFUser *)user;
- (NSNumber *)tribeCountForUser:(PFUser *)user;
- (BOOL)followStatusForUser:(PFUser *)user;
- (void)setVybeCount:(NSNumber *)count user:(PFUser *)user;
- (void)setTribeCount:(NSNumber *)count user:(PFUser *)user;
- (void)setFollowStatus:(BOOL)following user:(PFUser *)user;

- (void)setFacebookFriends:(NSArray *)friends;
- (NSArray *)facebookFriends;

@end
