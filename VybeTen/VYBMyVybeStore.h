//
//  VYBMyVybeStore.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 24..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VYBVybe.h"

@interface VYBMyVybeStore : NSObject {
    NSMutableArray *myVybes;
}

+ (VYBMyVybeStore *)sharedStore;
- (NSArray *)myVybes;
- (void)listVybes;
- (void)addVybe:(VYBVybe *)v;
- (void)removeVybe:(VYBVybe *)v;
- (NSString *)myVybesArchivePath;
- (BOOL)saveChanges;

@end
