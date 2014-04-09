//
//  VYBTribe.m
//  VybeTen
//
//  Created by jinsuk on 4/9/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBTribe.h"

@implementation VYBTribe

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        [self setTribeName:[aDecoder decodeObjectForKey:@"tribeName"]];
        [self setVybes:[aDecoder decodeObjectForKey:@"vybes"]];
        [self setUsers:[aDecoder decodeObjectForKey:@"users"]];
        [self setSyncs:[aDecoder decodeObjectForKey:@"syncs"]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:tribeName forKey:@"tribeName"];
    [aCoder encodeObject:vybes forKey:@"vybes"];
    [aCoder encodeObject:users forKey:@"users"];
    [aCoder encodeObject:syncs forKey:@"syncs"];
}

- (void)setTribeName:(NSString *)name {
    tribeName = name;
}
- (void)setVybes:(NSMutableArray *)vys {
    vybes = vys;
}
- (void)setUsers:(NSMutableArray *)usrs {
    users = usrs;
}
- (void)setSyncs:(NSMutableArray *)s {
    syncs = s;
}

- (NSString *)tribeName {
    return tribeName;
}

- (NSMutableArray *)vybes {
    return vybes;
}

- (NSMutableArray *)users {
    return users;
}
- (NSMutableArray *)syncs {
    return syncs;
}

@end
