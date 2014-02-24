//
//  VYBVybeStore.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 24..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VYBVybe;

@interface VYBVybeStore : NSObject {
    NSMutableArray *myVybes;
}

+ (VYBVybeStore *)sharedStore;
- (NSArray *)myVybes;
- (void)addVybe:(VYBVybe *)v;
- (void)removeVybe:(VYBVybe *)v;
- (NSString *)myVybesArchivePath;
- (BOOL)saveChanges;

@end
