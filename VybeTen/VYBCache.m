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

#import "Vybe-Swift.h"

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

- (void)setPointScore:(NSInteger)score forVybe:(PFObject *)vybe {
  NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForVybe:vybe]];
  [attributes setObject:[NSNumber numberWithInteger:score] forKey:kVYBVybeAttributesPointScoreKey];
  [self setAttributes:attributes forVybe:vybe];
}

- (NSInteger)pointScoreForVybe:(PFObject *)vybe {
  NSDictionary *attributes = [self attributesForVybe:vybe];
  if (attributes) {
    NSNumber *score = [attributes objectForKey:kVYBVybeAttributesPointScoreKey];
    if (score) {
      return [score integerValue];
    }
  }
  
  return 0;
}

- (void)incrementPointScoreForVybe:(PFObject *)vybe {
  NSInteger newScore = [self pointScoreForVybe:vybe] + 1;
  [self setPointScore:newScore forVybe:vybe];
}

- (void)decrementPointScoreForVybe:(PFObject *)vybe {
  NSInteger newScore = [self pointScoreForVybe:vybe] - 1;
  [self setPointScore:newScore forVybe:vybe];
}

- (void)setPointTypeFromCurrentUserForVybe:(PFObject *)vybe type:(NSString *)typeStr {
  NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForVybe:vybe]];
  [attributes setObject:typeStr forKey:kVYBVybeAttributesPointTypeByCurrentUserKey];
  [self setAttributes:attributes forVybe:vybe];
}

- (NSString *)pointTypeFromCurrentUserForVybe:(PFObject *)vybe {
  NSDictionary *attributes = [self attributesForVybe:vybe];
  if (attributes) {
    NSString *type = [attributes objectForKey:kVYBVybeAttributesPointTypeByCurrentUserKey];
    if (type) {
      return type;
    }
  }
  return kVYBVybeAttributesPointTypeNoneKey;
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



#pragma mark - ()

- (NSDictionary *)attributesForVybe:(PFObject *)vybe {
  NSString *key = [self keyForVybe:vybe];
  return [self.cache objectForKey:key];
}

- (void)setAttributes:(NSDictionary *)attributes forVybe:(PFObject *)vybe {
  NSString *key = [self keyForVybe:vybe];
  [self.cache setObject:attributes forKey:key];
}

- (NSDictionary *)attributesForUser:(PFUser *)user {
  NSDictionary *attributes = [self.cache objectForKey:[self keyForUser:user]];
  return attributes;
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
