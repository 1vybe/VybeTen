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

+ (id)sharedCache;

- (void)clear;
- (void)addFreshVybe:(PFObject *)nVybe;
- (void)removeFreshVybe:(PFObject *)oVybe;
//- (void)addFreshVybe:(PFObject *)nVybe forLocation:(NSString *)location;
//- (void)addFreshVybe:(PFObject *)nVybe forUser:(PFObject *)aUser;
- (NSArray *)freshVybes;
- (NSDictionary *)freshVybesByLocation;
- (NSDictionary *)freshVybesByUser;
- (NSArray *)freshVybesForLocation:(NSString *)location;
- (NSArray *)freshVybesForUser:(PFObject *)aUser;
- (void)clearFreshVybes;

// TODO: These should not be cached but only the counter should be
- (void)addUser:(PFObject *)user forLocation:(NSString *)location;
- (void)addVybe:(PFObject *)vybe forLocation:(NSString *)location;
- (NSArray *)usersForLocation:(NSString *)location;
- (NSArray *)vybesForLocation:(NSString *)location;
- (NSDictionary *)usersByLocation;
- (NSDictionary *)vybesByLocation;
- (NSInteger)numberOfLocations;
- (void)clearUsersByLocation;
- (void)clearVybesByLocation;


- (void)setAttributesForVybe:(PFObject *)vybe likers:(NSArray *)likers commenters:(NSArray *)commenters likedByCurrentUser:(BOOL)likedByCurrentUser;
- (NSDictionary *)attributesForVybe:(PFObject *)vybe;
- (NSNumber *)likeCountForVybe:(PFObject *)vybe;
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
