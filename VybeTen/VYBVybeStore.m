//
//  VYBVybeStore.m
//  VybeTen
//
//  Created by jinsuk on 2/24/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBVybeStore.h"

@implementation VYBVybeStore

+ (VYBVybeStore *)sharedStore {
    static VYBVybeStore *sharedStore = nil;
    if (!sharedStore)
        sharedStore = [[super allocWithZone:nil] init];
    
    return sharedStore;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [self sharedStore];
}

- (id)init {
    self = [super init];
    
    if (self) {
        NSString *path = [self tribesArchivePath];
        tribes = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        if (!tribes)
            tribes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSArray *)tribes {
    return tribes;
}

- (NSString *)tribesArchivePath {
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDir = [documentDirectories objectAtIndex:0];
    
    return [documentDir stringByAppendingPathComponent:@"tribes.archive"];
}
- (BOOL)saveChanges {
    NSString *path = [self tribesArchivePath];
    return [NSKeyedArchiver archiveRootObject:tribes toFile:path];
}

@end
