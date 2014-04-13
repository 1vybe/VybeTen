//
//  VYBVybeStore.h
//  VybeTen
//
//  Created by jinsuk on 2/24/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VYBVybeStore : NSObject {
    NSMutableArray *tribes;
}

+ (VYBVybeStore *)sharedStore;
- (NSArray *)tribes;
- (NSString *)tribesArchivePath;
- (BOOL)saveChanges;

@end
