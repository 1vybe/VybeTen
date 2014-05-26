//
//  VYBMyVybeStore.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 24..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSS3/AWSS3.h>
#import "VYBMyVybe.h"

@interface VYBMyVybeStore : NSObject {
    NSArray *myVybes;
}

+ (VYBMyVybeStore *)sharedStore;
- (void)addVybe:(VYBMyVybe *)aVybe;
//- (PFObject *)vybeForKey:(NSString *)aKey;
//- (NSString *)videoPathWithKey:(NSString *)aKey;
//- (NSString *)thumbnailPathWithKey:(NSString *)aKey;
- (void)uploadVybe:(VYBMyVybe *)aVybe;
- (BOOL)removeVybeForKey:(NSString *)aKey;
- (NSString *)myVybesArchivePath;


- (void)delayedUploadsBegin;
- (BOOL)saveChanges;

@end
