//
//  VYBOldZoneFinder.h
//  VybeTen
//
//  Created by jinsuk on 10/30/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VYBOldZoneFinder : NSObject
- (void)findZoneNearLocationInBackgroundWithLatitude:(double)latitude longitude:(double)longitude completionHandler:(void (^)(NSArray *results, NSError *error))completionBlock;

@end
