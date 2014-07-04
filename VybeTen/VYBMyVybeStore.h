//
//  VYBMyVybeStore.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 24..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VYBMyVybe.h"

@interface VYBMyVybeStore : NSObject {
    NSArray *myVybes;
    NSMutableArray *uploadQueue;
}

+ (VYBMyVybeStore *)sharedStore;
- (void)addVybe:(VYBMyVybe *)aVybe;
- (void)uploadVybe:(VYBMyVybe *)aVybe;
- (void)uploadDelayedVybes;
- (NSString *)myVybesArchivePath;


- (BOOL)saveChanges;

@end
