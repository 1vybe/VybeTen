//
//  VYBUser.h
//  VybeTen
//
//  Created by jinsuk on 7/28/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>
@class VYBZone;
@interface VYBUser : NSObject <NSCoding>

@property (nonatomic, strong) NSDate *lastWatchedVybeTimeStamp;
@property (nonatomic, strong) VYBZone *currZone;

@end
