//
//  VYBVybeStore.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 24..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBVybeStore.h"
#import "VYBVybe.h"

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
        NSString *path = [self myVybesArchivePath];
        myVybes = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        
        if (!myVybes)
            myVybes = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (NSArray *)myVybes {
    return myVybes;
}

- (void)addVybe:(VYBVybe *)v {
    [myVybes addObject:v];
    NSLog(@"There are %d vybes", [myVybes count]);
}

- (void)removeVybe:(VYBVybe *)v {
    [myVybes removeObjectIdenticalTo:v];
}

- (NSString *)myVybesArchivePath {
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    
    return [documentDirectory stringByAppendingPathComponent:@"myVybes.archive"];
}

- (BOOL)saveChanges {
    NSString *path = [self myVybesArchivePath];
    
    return [NSKeyedArchiver archiveRootObject:myVybes toFile:path];
}


@end
