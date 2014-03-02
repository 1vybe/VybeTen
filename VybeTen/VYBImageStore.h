//
//  VYBImageStore.h
//  VybeTen
//
//  Created by jinsuk on 2/24/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VYBImageStore : NSObject {
    NSMutableDictionary *dictionary;
}

+ (VYBImageStore *)sharedStore;
- (void)setImage:(UIImage *)img forKey:(NSString *)key;
- (UIImage *)imageWithKey:(NSString *)key;

@end
