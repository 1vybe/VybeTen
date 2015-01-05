//
//  VYBMyVybeStore.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 24..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VYBVybe.h"
@class Zone;
@interface VYBMyVybeStore : NSObject
@property (nonatomic) Zone *currZone;
@property (nonatomic) NSInteger currentUploadStatus;

+ (VYBMyVybeStore *)sharedStore;
- (void)prepareNewVybe;
- (void)uploadCurrentVybe;

- (NSArray *)savedVybes;
- (void)deleteSavedVybe:(PFObject *)savedObj;


//- (void)addVybe:(VYBMyVybe *)aVybe;
- (void)startUploadingSavedVybes;
- (NSString *)myVybesArchivePath;
- (VYBVybe *)currVybe;

- (BOOL)saveChanges;

@end
