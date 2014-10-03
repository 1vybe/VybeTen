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
    
    //NOTE: we discard the first location field (neighborhood)
    NSString *keyString = [NSString stringWithFormat:@"%@,%@", token[1], token[2]];
    [self addFreshVybe:nVybe forLocation:keyString];
    [self addFreshVybe:nVybe forUser:nVybe[kVYBVybeUserKey]];
    
    if ([nVybe[kVYBVybeTimestampKey] timeIntervalSinceDate:[[VYBCache sharedCache] lastRefresh]] > 0) {
        [self addVybe:nVybe forLocation:keyString];
        [self addVybe:nVybe forUser:nVybe[kVYBVybeUserKey]];
    }
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
    
    NSDictionary *oldFreshByLocation = [self.cache objectForKey:@"freshByLocation"];
    if (oldFreshByLocation) {
        NSString *locString = oVybe[kVYBVybeLocationStringKey];
        NSArray *token = [locString componentsSeparatedByString:@","];
        NSString *keyString = [NSString stringWithFormat:@"%@,%@", token[1], token[2]];
        NSArray *oldArr = [oldFreshByLocation objectForKey:keyString];
        if (oldArr) {
            NSMutableArray *newArr = [NSMutableArray arrayWithArray:oldArr];
            [newArr removePFObject:oVybe];
            NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:oldFreshByLocation];
            [newDict setObject:newArr forKey:keyString];
            [self.cache setObject:newDict forKey:@"freshByLocation"];
        }
    }
    
    NSDictionary *oldFreshByUser = [self.cache objectForKey:@"freshByUser"];
    if (oldFreshByUser) {
        PFObject *user = oVybe[kVYBVybeUserKey];
        NSArray *oldArr = [oldFreshByUser objectForKey:user.objectId];
        if (oldArr) {
            NSMutableArray *newArr = [NSMutableArray arrayWithArray:oldArr];
            [newArr removePFObject:oVybe];
            NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:oldFreshByUser];
            [newDict setObject:newArr forKey:user.objectId];
            [self.cache setObject:newDict forKey:@"freshByUser"];
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:VYBCacheFreshVybeCountChangedNotification object:nil];
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

- (void)addFreshVybe:(PFObject *)nVybe forLocation:(NSString *)location {
    NSDictionary *freshByLocation = [self.cache objectForKey:@"freshByLocation"];
    NSMutableDictionary *newDict;
    
    if (!freshByLocation) {
        newDict = [NSMutableDictionary dictionary];
        NSArray *newVybe = [NSArray arrayWithObject:nVybe];
        [newDict setObject:newVybe forKey:location];
    } else {
        newDict = [NSMutableDictionary dictionaryWithDictionary:freshByLocation];
        if (![freshByLocation objectForKey:location]) {
            NSArray *newVybe = [NSArray arrayWithObject:nVybe];
            [newDict setObject:newVybe forKey:location];
        } else {
            NSArray *currItems = [freshByLocation objectForKey:location];
            [newDict setObject:[currItems arrayByAddingObject:nVybe] forKey:location];
        }
        
    }
    [self.cache setObject:newDict forKey:@"freshByLocation"];
}



- (void)addFreshVybe:(PFObject *)nVybe forUser:(PFObject *)aUser {
    NSDictionary *freshByUser = [self.cache objectForKey:@"freshByUser"];
    NSMutableDictionary *newDict;
    
    if (!freshByUser) {
        newDict = [NSMutableDictionary dictionary];
        NSArray *newVybe = [NSArray arrayWithObject:nVybe];
        [newDict setObject:newVybe forKey:aUser.objectId];
    } else {
        newDict = [NSMutableDictionary dictionaryWithDictionary:freshByUser];
        if (![freshByUser objectForKey:aUser.objectId]) {
            NSArray *newVybe = [NSArray arrayWithObject:nVybe];
            [newDict setObject:newVybe forKey:aUser.objectId];
        } else {
            NSArray *currItems = [freshByUser objectForKey:aUser.objectId];
            [newDict setObject:[currItems arrayByAddingObject:nVybe] forKey:aUser.objectId];
        }
        
    }
    [self.cache setObject:newDict forKey:@"freshByUser"];
}

- (NSArray *)freshVybes {
    return [self.cache objectForKey:@"freshVybes"];
}

- (NSArray *)watchedVybes {
    return [self.cache objectForKey:@"watchedVybes"];
}

- (NSDictionary *)freshVybesByLocation {
    return [self.cache objectForKey:@"freshByLocation"];
}

- (NSDictionary *)freshVybesByUser{
    return [self.cache objectForKey:@"freshByUser"];
}

- (NSArray *)freshVybesForLocation:(NSString *)location {
    NSDictionary *dictionary = [self.cache objectForKey:@"freshByLocation"];
    NSArray *vybes = [dictionary objectForKey:location];
    
    return vybes;
}

- (NSArray *)freshVybesForUser:(PFObject *)aUser {
    NSDictionary *dictionary = [self.cache objectForKey:@"freshByUser"];
    NSArray *vybes = [dictionary objectForKey:aUser.objectId];
    
    return vybes;
}

/*
- (void)clearFreshVybes {
    NSDictionary *emptyDict = [[NSDictionary alloc] init];
    [self.cache setObject:emptyDict forKey:@"freshByLocation"];
    [self.cache setObject:emptyDict forKey:@"freshByUser"];
    
    NSArray *emptyArr = [[NSArray alloc] init];
    [self.cache setObject:emptyArr forKey:@"freshVybes"];
}
*/
- (void)addUser:(PFObject *)user forLocation:(NSString *)location {
    NSDictionary *usersByLocation = [self.cache objectForKey:@"usersByLocation"];
    NSMutableDictionary *newDict;
    
    if (!usersByLocation) {
        newDict = [NSMutableDictionary dictionary];
        NSArray *newUser = [NSArray arrayWithObject:user];
        [newDict setObject:newUser forKey:location];
    } else {
        newDict = [NSMutableDictionary dictionaryWithDictionary:usersByLocation];
        if (![usersByLocation objectForKey:location]) {
            NSArray *newUser = [NSArray arrayWithObject:user];
            [newDict setObject:newUser forKey:location];
        } else {
            NSArray *currUsers = [usersByLocation objectForKey:location];
            [newDict setObject:[currUsers arrayByAddingObject:user] forKey:location];
        }
        
    }
    [self.cache setObject:newDict forKey:@"usersByLocation"];
}

- (void)addVybe:(PFObject *)vybe forLocation:(NSString *)location {
    NSDictionary *vybesByLocation = [self.cache objectForKey:@"vybesByLocation"];
    NSMutableDictionary *newDict;
    
    if (!vybesByLocation) {
        newDict = [NSMutableDictionary dictionary];
        NSArray *newVybe = [NSArray arrayWithObject:vybe];
        [newDict setObject:newVybe forKey:location];
    } else {
        newDict = [NSMutableDictionary dictionaryWithDictionary:vybesByLocation];
        if (![vybesByLocation objectForKey:location]) {
            NSArray *newVybe = [NSArray arrayWithObject:vybe];
            [newDict setObject:newVybe forKey:location];
        } else {
            NSArray *newVybes = [vybesByLocation objectForKey:location];
            [newDict setObject:[newVybes arrayByAddingObject:vybe] forKey:location];
        }
        
    }
    [self.cache setObject:newDict forKey:@"vybesByLocation"];
}

- (void)addVybe:(PFObject *)vybe forUser:(PFObject *)aUser {
    NSDictionary *vybesByUser = [self.cache objectForKey:@"vybesByUser"];
    NSMutableDictionary *newDict;
    
    if (!vybesByUser) {
        newDict = [NSMutableDictionary dictionary];
        NSArray *newVybe = [NSArray arrayWithObject:vybe];
        [newDict setObject:newVybe forKey:aUser.objectId];
    } else {
        newDict = [NSMutableDictionary dictionaryWithDictionary:vybesByUser];
        if (![vybesByUser objectForKey:aUser.objectId]) {
            NSArray *newVybe = [NSArray arrayWithObject:vybe];
            [newDict setObject:newVybe forKey:aUser.objectId];
        } else {
            NSArray *newVybes = [vybesByUser objectForKey:aUser.objectId];
            [newDict setObject:[newVybes arrayByAddingObject:vybe] forKey:aUser.objectId];
        }
        
    }
    [self.cache setObject:newDict forKey:@"vybesByUser"];
}


- (NSArray *)usersForLocation:(NSString *)location {
    NSDictionary *usersByLocation = [self.cache objectForKey:@"usersByLocation"];
    NSArray *users = [usersByLocation objectForKey:location];
    
    return users;
}

- (NSArray *)vybesForLocation:(NSString *)location {
    NSDictionary *vybesByLocation = [self.cache objectForKey:@"vybesByLocation"];
    NSArray *vybes = [vybesByLocation objectForKey:location];
    
    return vybes;
}

- (NSArray *)vybesForUser:(PFObject *)aUser {
    NSDictionary *vybesByUser = [self.cache objectForKey:@"vybesByUser"];
    NSArray *vybes = [vybesByUser objectForKey:aUser.objectId];
    
    return vybes;
}

- (NSDictionary *)usersByLocation {
    return [self.cache objectForKey:@"usersByLocation"];
}

- (NSDictionary *)vybesByLocation {
    return [self.cache objectForKey:@"vybesByLocation"];
}

- (NSDictionary *)vybesByUser {
    return [self.cache objectForKey:@"vybesByUser"];
}

- (NSArray *)activeUsers {
    NSArray *active = [[NSArray alloc] init];
    for (NSArray *arr in [[self usersByLocation] allValues]) {
        if (arr && [arr count] > 0) {
            active = [active arrayByAddingObjectsFromArray:arr];
        }
    }
    return active;
}
/*
- (void)clearUsersByLocation {
    NSDictionary *emptyDict = [[NSDictionary alloc] init];
    [self.cache setObject:emptyDict forKey:@"usersByLocation"];
}

- (void)clearVybesByLocation {
    NSDictionary *emptyDict = [[NSDictionary alloc] init];
    [self.cache setObject:emptyDict forKey:@"vybesByLocation"];
}

- (void)clearVybesByUser {
    NSDictionary *emptyDict = [[NSDictionary alloc] init];
    [self.cache setObject:emptyDict forKey:@"vybesByUser"];
}
*/
- (NSInteger)numberOfLocations {
    NSDictionary *vybesByLocation = [self.cache objectForKey:@"vybesByLocation"];
    NSDictionary *usersByLocation = [self.cache objectForKey:@"usersByLocation"];
    
    if (vybesByLocation.allKeys.count != usersByLocation.allKeys.count) {
        NSLog(@"SOMETHING IS WRONG");
    }
    
    return usersByLocation.allKeys.count;
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
