//
//  VYBImageStore.m
//  VybeTen
//
//  Created by jinsuk on 2/24/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBImageStore.h"

@implementation VYBImageStore

+ (VYBImageStore *)sharedStore {
    static VYBImageStore *sharedStore = nil;
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
        dictionary = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)setImage:(UIImage *)img forKey:(NSString *)key {
    [dictionary setObject:img forKey:key];
}

- (UIImage *)imageWithKey:(NSString *)key {
    return [dictionary objectForKey:key];
}

- (void)deleteImageForKey:(NSString *)key {
    if (!key)
        return;
    [dictionary removeObjectForKey:key];
}
@end
