//
//  VYBTribe.h
//  VybeTen
//
//  Created by jinsuk on 4/9/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VYBTribe : NSObject <NSCoding> {
    NSString *tribeName;
    NSMutableArray *vybes;
    NSMutableArray *users;
    NSMutableArray *syncs;
}

- (void)setTribeName:(NSString *)name;
- (void)setVybes:(NSMutableArray *)vys;
- (void)setUsers:(NSMutableArray *)usrs;
- (void)setSyncs:(NSMutableArray *)s;
- (NSString *)tribeName;
- (NSMutableArray *)vybes;
- (NSMutableArray *)users;
- (NSMutableArray *)syncs;

@end
