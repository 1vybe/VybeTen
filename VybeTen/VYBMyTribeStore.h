//
//  VYBMyTribeStore.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 8..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VYBMyTribeStore : NSObject {
    NSMutableArray *myTribeVybes;
}
+ (VYBMyTribeStore *)sharedStore;
- (NSArray *)myTribeVybes;
@end
