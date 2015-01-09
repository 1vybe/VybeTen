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

- (void)refreshBumpsForMeInBackground:(void (^)(BOOL success))completionBlock {
  PFQuery *bumpQuery = [PFQuery queryWithClassName:kVYBActivityClassKey];
//  [bumpQuery setCachePolicy:kPFCachePolicyNetworkElseCache];
  [bumpQuery orderByDescending:@"createdAt"];
  [bumpQuery includeKey:kVYBActivityVybeKey];
  [bumpQuery includeKey:kVYBActivityFromUserKey];
  [bumpQuery whereKey:kVYBActivityTypeKey equalTo:kVYBActivityTypeLike];
  [bumpQuery whereKey:kVYBActivityToUserKey equalTo:[PFUser currentUser]];
  // Only activities within the last 7 days
  NSDate *aWeekAgo = [NSDate dateWithTimeIntervalSinceNow:-1 * 60 * 60 * 24 * 3];
  [bumpQuery whereKey:@"createdAt" greaterThanOrEqualTo:aWeekAgo];
  
  [bumpQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    if (!error) {
      [self clearBumpsForMe];
      
      for (PFObject *activity in objects) {
        // Updating attributes for vybe
        [self addBump:activity[kVYBActivityVybeKey] fromUser:activity[kVYBActivityFromUserKey]];
        // Also we want to update attributes for current user
        [self addBumpForCurrentUser:activity];
      }
      if (completionBlock) {
        completionBlock(YES);
      }
    } else {
      if (completionBlock) {
        completionBlock(NO);
      }
    }
  }];
}

- (void)refreshMyBumpsInBackground:(void (^)(BOOL success))completionBlock {
  // Update my bumps
  PFQuery *bumpQuery = [PFQuery queryWithClassName:kVYBActivityClassKey];
//  [bumpQuery setCachePolicy:kPFCachePolicyNetworkElseCache];
  [bumpQuery orderByDescending:@"createdAt"];
  [bumpQuery includeKey:kVYBActivityVybeKey];
  [bumpQuery includeKey:kVYBActivityToUserKey];
  [bumpQuery whereKey:kVYBActivityTypeKey equalTo:kVYBActivityTypeLike];
  [bumpQuery whereKey:kVYBActivityFromUserKey equalTo:[PFUser currentUser]];
  // Only activities within the last 7 days
  NSDate *aWeekAgo = [NSDate dateWithTimeIntervalSinceNow:-1 * 60 * 60 * 24 * 3];
  [bumpQuery whereKey:@"createdAt" greaterThanOrEqualTo:aWeekAgo];
  
  [bumpQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    if (!error) {
      // NOTE: - Clearing and re-downloading here is very inefficient but needed for now to filter out activities on a deleted vybe.
      [self clearMyBumpActivities];
      
      for (PFObject *activity in objects) {
        [[VYBCache sharedCache] setAttributesForVybe:activity[kVYBActivityVybeKey] likers:@[[PFUser currentUser]] commenters:nil likedByCurrentUser:YES];
        
        [self addMyBump:activity];
      }
      if (completionBlock) {
        completionBlock(YES);
      }
    } else {
      completionBlock(NO);
    }
  }];
}

- (void)clearMyBumpActivities {
  NSMutableDictionary *myAttributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForUser:[PFUser currentUser]]];
  NSArray *empty = [[NSArray alloc] init];
  [myAttributes setObject:empty forKey:kVYBUserAttributesMyBumpsKey];
  
  [self setAttributes:myAttributes forUser:[PFUser currentUser]];
}

- (void)clearBumpsForMe {
  NSMutableDictionary *myAttributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForUser:[PFUser currentUser]]];
  NSArray *empty = [[NSArray alloc] init];
  [myAttributes setObject:empty forKey:kVYBUserAttributesBumpsForMeKey];
  
  [self setAttributes:myAttributes forUser:[PFUser currentUser]];
}

- (void)addMyBump:(PFObject *)activity {
  NSMutableDictionary *myAttributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForUser:[PFUser currentUser]]];
  NSArray *myBumps = [myAttributes objectForKey:kVYBUserAttributesMyBumpsKey];
  if (myBumps) {
    if (![myBumps containsPFObject:activity]) {
      myBumps = [myBumps arrayByAddingObject:activity];
    }
  } else {
    myBumps = [NSArray arrayWithObject:activity];
  }
  [myAttributes setObject:myBumps forKey:kVYBUserAttributesMyBumpsKey];
  
  [self setAttributes:myAttributes forUser:[PFUser currentUser]];
}

- (void)addBumpForCurrentUser:(PFObject *)activity {
  NSMutableDictionary *myAttributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForUser:[PFUser currentUser]]];
  NSArray *bumpsForMe = [myAttributes objectForKey:kVYBUserAttributesBumpsForMeKey];
  if (bumpsForMe) {
    if (![bumpsForMe containsPFObject:activity]) {
      bumpsForMe = [bumpsForMe arrayByAddingObject:activity];
    }
  } else {
    bumpsForMe = [NSArray arrayWithObject:activity];
  }
  [myAttributes setObject:bumpsForMe forKey:kVYBUserAttributesBumpsForMeKey];
  
  [self setAttributes:myAttributes forUser:[PFUser currentUser]];
}

- (void)addBump:(PFObject *)vybe fromUser:(PFUser *)fromUser {
  NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForVybe:vybe]];
  
  NSArray *bumpers = [attributes objectForKey:kVYBVybeAttributesLikersKey];
  if (bumpers) {
    if (![bumpers containsPFObject:fromUser]) {
      bumpers = [bumpers arrayByAddingObject:fromUser];
    }
  }
  else {
    bumpers = [NSArray arrayWithObject:fromUser];
  }
  
  [attributes setObject:bumpers forKey:kVYBVybeAttributesLikersKey];
  [attributes setObject:@(bumpers.count) forKey:kVYBVybeAttributesLikeCountKey];
  
  if ([fromUser.objectId isEqualToString:[PFUser currentUser].objectId] ) {
    [attributes setObject:[NSNumber numberWithBool:YES] forKey:kVYBVybeAttributesIsLikedByCurrentUserKey];
  }
  
  [self setAttributes:attributes forVybe:vybe];
}

- (NSArray *)bumpActivitiesForUser:(PFUser *)user {
  NSDictionary *attributes = [self attributesForUser:user];
  NSArray *bumpActivities = [attributes objectForKey:kVYBUserAttributesBumpsForMeKey];
  
  return bumpActivities;
}

- (NSArray *)myBumpActivities {
  NSDictionary *attributes = [self attributesForUser:[PFUser currentUser]];
  NSArray *myActivities = [attributes objectForKey:kVYBUserAttributesMyBumpsKey];
  
  return myActivities;
}


- (NSInteger)newBumpActivityCountForCurrentUser {
  NSInteger count = 0;
  
  NSDate *lastRefresh = [[NSUserDefaults standardUserDefaults] objectForKey:kVYBUserDefaultsActivityLastRefreshKey];
  
  NSArray *activities = [self bumpActivitiesForUser:[PFUser currentUser]];
  for (PFObject *activity in activities) {
    PFUser *fromUser = activity[kVYBActivityFromUserKey];
    if ( ! [fromUser.objectId isEqualToString:[PFUser currentUser].objectId] ) {
      if (lastRefresh && [lastRefresh timeIntervalSinceDate:activity.createdAt] > 0) {
        // Nothing
      } else {
        count++;
      }
    }
  }
  
  return count;
}

//- (NSInteger)bumpCountForUser:(PFUser *)user {
//  NSArray *bumpActivities = [self bumpActivitiesForUser:user];
//  if (bumpActivities) {
//    return bumpActivities.count;
//  } else {
//    return 0;
//  }
//}

- (NSNumber *)likeCountForVybe:(PFObject *)vybe {
  NSDictionary *attributes = [self attributesForVybe:vybe];
  if (attributes) {
    return [attributes objectForKey:kVYBVybeAttributesLikeCountKey];
  }
  
  return [NSNumber numberWithInt:0];
}

- (NSArray *)vybesLikedByMe {
  NSDictionary *myAttributes = [self attributesForUser:[PFUser currentUser]];
  NSArray *myActivities = [myAttributes objectForKey:kVYBUserAttributesMyBumpsKey];
  
  return myActivities;
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

- (void)setVybeCount:(NSNumber *)count user:(PFUser *)user {
  NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForUser:user]];
  [attributes setObject:count forKey:kVYBUserAttributesVybeCountKey];
  [self setAttributes:attributes forUser:user];
}

- (void)setFollowStatus:(BOOL)following user:(PFUser *)user {
  NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForUser:user]];
  [attributes setObject:[NSNumber numberWithBool:following] forKey:kVYBUserAttributesIsFollowedByCurrentUserKey];
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
