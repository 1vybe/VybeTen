//
//  VYBCache.h
//  VybeTen
//
//  To Cache List
//  ---------
//  - When the user creates a new tribe
//  - When the user posts a vybe to that tribe
//  -
//  Created by jinsuk on 5/10/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VYBCache : NSObject
@property (nonatomic, strong) NSDate *lastRefresh;

+ (id)sharedCache;

- (void)clear;
- (void)addFreshVybe:(PFObject *)nVybe;
- (void)removeFreshVybe:(PFObject *)oVybe;
- (NSArray *)freshVybes;

- (void)setActivityCount:(int)count;
- (NSInteger)activityCount;

- (void)setAttributesForVybe:(PFObject *)vybe likers:(NSArray *)likers commenters:(NSArray *)commenters likedByCurrentUser:(BOOL)likedByCurrentUser;
- (void)setAttributesForVybe:(PFObject *)vybe flaggedByCurrentUser:(BOOL)flaggedByCurrentUser;
- (void)setBlockedUsers:(NSArray *)usersBlockedByMe forUser:(PFUser *)user;
- (void)addBlockedUser:(PFUser *)blockedUser forUser:(PFUser *)user;
- (void)removeBlockedUser:(PFUser *)blockedUser forUser:(PFUser *)user;
- (void)setNearbyCount:(NSNumber *)count forVybe:(PFObject *)vybe;
- (NSDictionary *)attributesForVybe:(PFObject *)vybe;
- (NSNumber *)likeCountForVybe:(PFObject *)vybe;
- (NSArray *)likersForVybe:(PFObject *)vybe;
- (BOOL)vybeLikedByMe:(PFObject *)vybe;
- (BOOL)vybeFlaggedByMe:(PFObject *)vybe;
- (NSArray *)usersBlockedByMe;
- (NSNumber *)nearbyCountForVybe:(PFObject *)vybe;
- (NSDictionary *)attributesForUser:(PFUser *)user;
- (NSArray *)usersFollowedByMe;
- (NSNumber *)vybeCountForUser:(PFUser *)user;
- (NSNumber *)tribeCountForUser:(PFUser *)user;
- (PFObject *)syncTribeForUser:(PFUser *)user;
- (BOOL)followStatusForUser:(PFUser *)user;
- (void)setSyncTribe:(PFObject *)tribe user:(PFUser *)user;
- (void)setVybeCount:(NSNumber *)count user:(PFUser *)user;
- (void)setTribeCount:(NSNumber *)count user:(PFUser *)user;
- (void)setFollowStatus:(BOOL)following user:(PFUser *)user;

- (void)setFacebookFriends:(NSArray *)friends;
- (NSArray *)facebookFriends;


@end
