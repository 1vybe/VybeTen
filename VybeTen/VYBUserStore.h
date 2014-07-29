//
//  VYBUserStore.h
//  VybeTen
//
//  Created by jinsuk on 7/28/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VYBUserStore : NSObject
@property (nonatomic) NSInteger newPrivateVybeCount;
+ (VYBUserStore *)sharedStore;
- (NSDate *)lastWatchedVybeTimeStamp;
- (void)setLastWatchedVybeTimeStamp:(NSDate *)aDate;
- (BOOL)saveChanges;

@end
