//
//  VYBCache.m
//  VybeTen
//
//  Created by jinsuk on 5/10/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBCache.h"
#import "NSArray+PFObject.h"
#import "NSMutableArray+PFObject.h"

@interface VYBCache()
@property (nonatomic, strong) NSCache *cache;
- (void)setAttributes:(NSDictionary *)attributes forVybe:(PFObject *)vybe;
@end

@implementation VYBCache
@synthesize cache;

#pragma mark - Initialization

+ (id)sharedCache {
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (id)init {
    self = [super init];
    if (self) {
        self.cache = [[NSCache alloc] init];
    }
    return self;
}

#pragma mark - VYBCache

- (void)clear {
    [self.cache removeAllObjects];
}

- (void)addFreshVybe:(PFObject *)nVybe {
    NSString *locString = nVybe[kVYBVybeLocationStringKey];
    NSArray *token = [locString componentsSeparatedByString:@","];
    if (token.count != 3)
        return;
    
    NSArray *watchedVybes = [self.cache objectForKey:@"watchedVybes"];
    if ( [watchedVybes containsPFObject:nVybe] )
        return;
    
    NSArray *freshVybes = [self.cache objectForKey:@"freshVybes"];
    if ( [freshVybes containsPFObject:nVybe] )
        return;
    
    NSArray *newArr;
    if (freshVybes) {
        newArr = [freshVybes arrayByAddingObject:nVybe];
    } else {
        newArr = [NSArray arrayWithObject:nVybe];
    }
    [self.cache setObject:newArr forKey:@"freshVybes"];
}

- (void)removeFreshVybe:(PFObject *)oVybe {
    NSString *removeFromFeed = @"remove_from_feed";
    [PFCloud callFunctionInBackground:removeFromFeed withParameters:@{@"vybeID": oVybe.objectId}
                                block:^(id object, NSError *error) {
                                    if (!error) {
                                        
                                    }
                                }];
    
    [self addWatchedVybe:oVybe];
    
    NSArray *oldFreshVybes = [self.cache objectForKey:@"freshVybes"];
    if (oldFreshVybes) {
        NSMutableArray *newFreshVybes = [NSMutableArray arrayWithArray:oldFreshVybes];
        [newFreshVybes removePFObject:oVybe];
        [self.cache setObject:newFreshVybes forKey:@"freshVybes"];
    }
}

- (void)addWatchedVybe:(PFObject *)oVybe {
    NSArray *watchedVybes = [self.cache objectForKey:@"watchedVybes"];
    NSArray *newArr;
    if (watchedVybes && ![watchedVybes containsPFObject:oVybe]) {
        newArr = [watchedVybes arrayByAddingObject:oVybe];
    } else {
        newArr = [NSArray arrayWithObject:oVybe];
    }
    [self.cache setObject:newArr forKey:@"watchedVybes"];
}

- (NSArray *)freshVybes {
    return [self.cache objectForKey:@"freshVybes"];
}

- (NSArray *)watchedVybes {
    return [self.cache objectForKey:@"watchedVybes"];
}

- (void)setActivityCount:(int)count {
    [self.cache setObject:[NSNumber numberWithInt:count] forKey:@"activityCount"];
}

- (NSInteger)activityCount {
    NSNumber *cnt = [self.cache objectForKey:@"activityCount"];
    if (cnt)
        return [cnt integerValue];
    else
        return 0;
}

- (void)setAttributesForVybe:(PFObject *)vybe likers:(NSArray *)likers commenters:(NSArray *)commenters likedByCurrentUser:(BOOL)likedByCurrentUser {
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithBool:likedByCurrentUser],kVYBVybeAttributesIsLikedByCurrentUserKey,
                                @([likers count]),kVYBVybeAttributesLikeCountKey,
                                likers,kVYBVybeAttributesLikersKey,
                                @([commenters count]),kVYBVybeAttributesCommentCountKey,
                                commenters,kVYBVybeAttributesCommentersKey,
                                nil];
    [self setAttributes:attributes forVybe:vybe];
}

- (void)setAttributesForVybe:(PFObject *)vybe flaggedByCurrentUser:(BOOL)flaggedByCurrentUser {
  NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithBool:flaggedByCurrentUser],kVYBVybeAttributesIsFlaggedByCurrentUserKey, nil];
  [self setAttributes:attributes forVybe:vybe];
}

- (void)setBlockedUsers:(NSArray *)usersBlockedByMe forUser:(PFUser *)user {
  NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForUser:user]];
  [attributes setObject:usersBlockedByMe forKey:kVYBUserAttributesBlockedUsersKey];
  [self setAttributes:attributes forUser:user];
}

- (void)addBlockedUser:(PFUser *)blockedUser forUser:(PFUser *)user {
  NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForUser:user]];
  NSArray *blackList = [NSArray arrayWithArray:[attributes objectForKey:kVYBUserAttributesBlockedUsersKey]];
  if (blackList) {
    blackList = [blackList arrayByAddingObject:blockedUser];
  }
  else {
    blackList = @[blockedUser];
  }
  [attributes setObject:blackList forKey:kVYBUserAttributesBlockedUsersKey];
  [self setAttributes:attributes forUser:user];
}

- (void)removeBlockedUser:(PFUser *)blockedUser forUser:(PFUser *)user {
  NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForUser:user]];
  NSMutableArray *blackList = [NSMutableArray arrayWithArray:[attributes objectForKey:kVYBUserAttributesBlockedUsersKey]];
  if (blackList) {
    [blackList removePFObject:blockedUser];
    [attributes setObject:blackList forKey:kVYBUserAttributesBlockedUsersKey];
    [self setAttributes:attributes forUser:user];

  }
}

- (void)setNearbyCount:(NSNumber *)count forVybe:(PFObject *)vybe {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForVybe:vybe]];
    [attributes setObject:count forKey:kVYBVybeAttributesNearbyCountKey];
    [self setAttributes:attributes forVybe:vybe];
}

- (NSNumber *)nearbyCountForVybe:(PFObject *)vybe {
    NSDictionary *attributes = [self attributesForVybe:vybe];
    NSNumber *count = [attributes objectForKey:kVYBVybeAttributesNearbyCountKey];
    return count;
}

- (NSDictionary *)attributesForVybe:(PFObject *)vybe {
    NSString *key = [self keyForVybe:vybe];
    return [self.cache objectForKey:key];
}

- (NSNumber *)likeCountForVybe:(PFObject *)vybe {
    NSDictionary *attributes = [self attributesForVybe:vybe];
    if (attributes) {
        return [attributes objectForKey:kVYBVybeAttributesLikeCountKey];
    }
    
    return [NSNumber numberWithInt:0];
}

- (BOOL)vybeLikedByMe:(PFObject *)vybe {
    NSDictionary *attributes = [self attributesForVybe:vybe];
    if (attributes) {
        NSNumber *boolNum = [attributes objectForKey:kVYBVybeAttributesIsLikedByCurrentUserKey];
        return [boolNum intValue] > 0;
    }
    
    return NO;
}

- (BOOL)vybeFlaggedByMe:(PFObject *)vybe {
  NSDictionary *attributes = [self attributesForVybe:vybe];
  if (attributes) {
    NSNumber *boolNum = [attributes objectForKey:kVYBVybeAttributesIsFlaggedByCurrentUserKey];
    return [boolNum intValue] > 0;
  }
  
  return NO;
}

- (NSArray *)usersBlockedByMe {
  NSDictionary *attributes = [self attributesForUser:[PFUser currentUser]];
  NSArray *blockedUsers = [attributes objectForKey:kVYBUserAttributesBlockedUsersKey];
  return blockedUsers;
}

- (NSArray *)likersForVybe:(PFObject *)vybe {
    NSDictionary *attributes = [self attributesForVybe:vybe];
    if (attributes) {
        return [attributes objectForKey:kVYBVybeAttributesLikersKey];
    }
    
    return nil;
}

- (NSDictionary *)attributesForUser:(PFUser *)user {
    NSDictionary *attributes = [self.cache objectForKey:[self keyForUser:user]];
    return attributes;
}

- (NSNumber *)vybeCountForUser:(PFUser *)user {
    NSDictionary *attributes = [self attributesForUser:user];
    if (attributes) {
        NSNumber *cnt = [attributes objectForKey:kVYBUserAttributesVybeCountKey];
        if (cnt) {
            return cnt;
        }
    }
    return [NSNumber numberWithInt:0];
}

- (NSNumber *)tribeCountForUser:(PFUser *)user {
    NSDictionary *attributes = [self attributesForUser:user];
    if (attributes) {
        NSNumber *cnt = [attributes objectForKey:kVYBUserAttributesTribeCountKey];
        if (cnt) {
            return cnt;
        }
    }
    return [NSNumber numberWithInt:0];
}

- (BOOL)followStatusForUser:(PFUser *)user {
    NSDictionary *attributes = [self attributesForUser:user];
    if (attributes) {
        NSNumber *followed = [attributes objectForKey:kVYBUserAttributesIsFollowedByCurrentUserKey];
        if (followed) {
            return [followed boolValue];
        }
    }
    return NO;
}

- (NSArray *)usersFollowedByMe {
    return nil;
}

- (PFObject *)syncTribeForUser:(PFUser *)user {
    NSDictionary *attributes = [self attributesForUser:user];
    if (attributes) {
        PFObject *tribe = [attributes objectForKey:kVYBUserAttributesSyncTribeKey];
        if (tribe) {
            return tribe;
        }
    }
    return nil;
}

- (void)setVybeCount:(NSNumber *)count user:(PFUser *)user {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForUser:user]];
    [attributes setObject:count forKey:kVYBUserAttributesVybeCountKey];
    [self setAttributes:attributes forUser:user];
}

- (void)setTribeCount:(NSNumber *)count user:(PFUser *)user {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForUser:user]];
    [attributes setObject:count forKey:kVYBUserAttributesTribeCountKey];
    [self setAttributes:attributes forUser:user];
}

- (void)setFollowStatus:(BOOL)following user:(PFUser *)user {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForUser:user]];
    [attributes setObject:[NSNumber numberWithBool:following] forKey:kVYBUserAttributesIsFollowedByCurrentUserKey];
    [self setAttributes:attributes forUser:user];
}

- (void)setSyncTribe:(PFObject *)tribe user:(PFUser *)user {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForUser:user]];
    [attributes setObject:tribe forKey:kVYBUserAttributesSyncTribeKey];
    [self setAttributes:attributes forUser:user];
}

- (void)setFacebookFriends:(NSArray *)friends {
    NSString *key = kVYBUserDefaultsCacheFacebookFriendsKey;
    [self.cache setObject:friends forKey:key];
    [[NSUserDefaults standardUserDefaults] setObject:friends forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *)facebookFriends {
    NSString *key = kVYBUserDefaultsCacheFacebookFriendsKey;
    if ([self.cache objectForKey:key]) {
        return [self.cache objectForKey:key];
    }
    
    NSArray *friends = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    
    if (friends) {
        [self.cache setObject:friends forKey:key];
    }
    
    return friends;
}

#pragma mark - ()

- (void)setAttributes:(NSDictionary *)attributes forVybe:(PFObject *)vybe {
    NSString *key = [self keyForVybe:vybe];
    [self.cache setObject:attributes forKey:key];
}

- (void)setAttributes:(NSDictionary *)attributes forUser:(PFUser *)user {
    NSString *key = [self keyForUser:user];
    [self.cache setObject:attributes forKey:key];
}

- (NSString *)keyForVybe:(PFObject *)vybe {
    return [NSString stringWithFormat:@"vybe_%@", [vybe objectId]];
}

- (NSString *)keyForUser:(PFUser *)user {
    return [NSString stringWithFormat:@"user_%@", [user objectId]];
}

@end
