//
//  VYBTribe.m
//  VybeTen
//
//  Vybes are stored in Tribe with the most recent vybe at index 0.
//
//  Created by jinsuk on 4/9/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBTribe.h"
#import "VYBConstants.h"

@implementation VYBTribe

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        [self setTribeName:[aDecoder decodeObjectForKey:@"tribeName"]];
        [self setOpen:[aDecoder decodeBoolForKey:@"open"]];
        [self setVybes:[aDecoder decodeObjectForKey:@"vybes"]];
        if (!vybes)
            vybes = [[NSMutableArray alloc] init];
        [self setUsers:[aDecoder decodeObjectForKey:@"users"]];
        if (!users)
            users = [[NSMutableArray alloc] init];
        [self setSyncs:[aDecoder decodeObjectForKey:@"syncs"]];
        if (!syncs)
            syncs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:tribeName forKey:@"tribeName"];
    [aCoder encodeBool:open forKey:@"open"];
    [aCoder encodeObject:vybes forKey:@"vybes"];
    [aCoder encodeObject:users forKey:@"users"];
    [aCoder encodeObject:syncs forKey:@"syncs"];
}


- (void)addVybe:(VYBVybe *)v {
    if ( [self hasVybe:v] )
        return;
    NSInteger i = 0;
    for (; i < [vybes count]; i++) {
        if ( [v isFresherThan:[vybes objectAtIndex:i]] ) {
            break;
        }
    }
    NSLog(@"Adding");
    [vybes insertObject:v atIndex:i];
    NSLog(@"[%d]", [vybes count]);
}

- (BOOL)hasVybe:(VYBVybe *)newV {
    for (VYBVybe *v in vybes) {
        if ( [[v vybeKey] isEqualToString:[newV vybeKey]] )
            return YES;
    }
    return NO;
}

- (VYBVybe *)vybeWithKey:(NSString *)vyKey {
    for (VYBVybe *v in vybes) {
        if ( [[v vybeKey] isEqualToString:vyKey] )
            return v;
    }
    return nil;
}

- (BOOL)hasDownloadingVybe {
    for (VYBVybe *v in vybes) {
        if ([v downStatus] == DOWNLOADING)
            return YES;
    }
    return NO;
}

- (VYBVybe *)oldestVybeToBeDownloaded {
    for (VYBVybe *v in [vybes reverseObjectEnumerator]) {
        if ([v downStatus] == DOWNFRESH)
            return v;
    }
    return nil;
}

- (VYBVybe *)newestVybeTobeDownloaded {
    for (VYBVybe *v in vybes) {
        if ([v downStatus] == DOWNFRESH)
            return v;
    }
    return nil;
}

- (NSArray *)downloadedVybes {
    NSMutableArray *downloaded = [[NSMutableArray alloc] init];
    for (VYBVybe *v in vybes) {
        if ([v downStatus] == DOWNLOADED)
            [downloaded addObject:v];
    }
    return downloaded;
}

- (void)changeDownStatusFor:(NSString *)vyKey withStatus:(BOOL)down {
    for (VYBVybe *v in vybes) {
        if ( [[v vybeKey] isEqualToString:vyKey] ) {
            [v setDownStatus:down];
            return;
        }
    }
}



/**
 * Getters and Setters
 **/

- (void)setTribeName:(NSString *)name {
    tribeName = name;
}

- (void)setOpen:(BOOL)op {
    open = op;
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

- (BOOL)isOpen {
    return open;
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
