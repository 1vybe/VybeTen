//
//  VYBUser.m
//  VybeTen
//
//  Created by jinsuk on 4/9/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBUser.h"

@implementation VYBUser

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        deviceId = [aDecoder decodeObjectForKey:@"deviceId"];
        username = [aDecoder decodeObjectForKey:@"username"];
        vybes = [aDecoder decodeObjectForKey:@"vybes"];
        tribes = [aDecoder decodeObjectForKey:@"tribes"];
        friends = [aDecoder decodeObjectForKey:@"friends"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:deviceId forKey:@"deviceId"];
    [aCoder encodeObject:username forKey:@"username"];
    [aCoder encodeObject:vybes forKey:@"vybes"];
    [aCoder encodeObject:tribes forKey:@"tribes"];
    [aCoder encodeObject:friends forKey:@"friends"];
}

- (void)setDeviceId:(NSString *)devId {
    deviceId = devId;
}

- (void)setUsername:(NSString *)name {
    username = name;
}

- (void)setVybes:(NSMutableArray *)vs {
    vybes = vs;
}

- (void)setTribes:(NSMutableArray *)ts {
    tribes = ts;
}

- (void)setFriends:(NSMutableArray *)fs {
    friends = fs;
}

- (NSString *)deviceId {
    return deviceId;
}

- (NSString *)username {
    return username;
}

- (NSMutableArray *)vybes {
    return vybes;
}

- (NSMutableArray *)tribes {
    return tribes;
}

- (NSMutableArray *)friends {
    return friends;
}

@end
