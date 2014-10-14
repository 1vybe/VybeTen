//
//  VYBMyVybeStore.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 24..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VYBVybe.h"

@interface VYBMyVybeStore : NSObject

+ (VYBMyVybeStore *)sharedStore;
- (void)prepareNewVybe;
- (void)uploadCurrentVybe;

//- (void)addVybe:(VYBMyVybe *)aVybe;
- (void)startUploadingOldVybes;
- (NSString *)myVybesArchivePath;
- (VYBVybe *)currVybe;

- (BOOL)saveChanges;

@end
