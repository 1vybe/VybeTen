//
//  VYBUserStore.m
//  VybeTen
//
//  Created by jinsuk on 7/28/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBUserStore.h"
#import "VYBUser.h"

@implementation VYBUserStore {
    VYBUser *user;
}

+ (VYBUserStore *)sharedStore {
    static VYBUserStore *sharedStore = nil;
    if (!sharedStore) {
        sharedStore = [[super allocWithZone:nil] init];
    }
    return sharedStore;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [self sharedStore];
}

- (id)init {
    self = [super init];
    if (self) {
        self.newPrivateVybeCount = 0;
        
        NSString *path = [self userInfoArchivePath];
        user = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        if (!user) {
            user = [[VYBUser alloc] init];
        }
    }
    return self;
}

- (NSString *)userInfoArchivePath {
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    
    return [documentDirectory stringByAppendingPathComponent:@"userInfo.archive"];
}

- (BOOL)saveChanges {
    NSString *path = [self userInfoArchivePath];
    return [NSKeyedArchiver archiveRootObject:user toFile:path];
}


- (NSDate *)lastWatchedVybeTimeStamp {
    return [user lastWatchedVybeTimeStamp];
}

- (void)setLastWatchedVybeTimeStamp:(NSDate *)aDate {
    [user setLastWatchedVybeTimeStamp:aDate];
}

@end
