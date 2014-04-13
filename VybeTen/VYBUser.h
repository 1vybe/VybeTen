//
//  VYBUser.h
//  VybeTen
//
//  Created by jinsuk on 4/9/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VYBUser : NSObject <NSCoding> {
    NSString *deviceId;
    NSString *username;
    NSMutableArray *vybes;
    NSMutableArray *tribes;
    NSMutableArray *friends;
}

- (void)setDeviceId:(NSString *)devId;
- (void)setUsername:(NSString *)name;
- (void)setVybes:(NSMutableArray *)vs;
- (void)setTribes:(NSMutableArray *)ts;
- (void)setFriends:(NSMutableArray *)fs;
- (NSString *)deviceId;
- (NSString *)username;
- (NSMutableArray *)vybes;
- (NSMutableArray *)tribes;
- (NSMutableArray *)friends;

@end
