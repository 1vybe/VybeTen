//
//  VYBCache.m
//  VybeTen
//
//  Created by jinsuk on 5/10/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Parse/Parse.h>
#import "VYBCache.h"
#import "VYBConstants.h"

@implementation VYBCache
@synthesize cache;

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

- (void)setAttributes:(NSDictionary *)attributes forUser:(PFUser *)user {
    NSString *key = [self keyForUser:user];
    [self.cache setObject:attributes forKey:key];
}

- (NSString *)keyForUser:(PFUser *)user {
    return [NSString stringWithFormat:@"user_%@", [user objectId]];
}

- (void)clear {
    
}

@end
