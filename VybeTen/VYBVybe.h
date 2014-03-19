//
//  VYBVybe.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 24..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VYBVybe : NSObject <NSCoding> {
    NSString *deviceId;
    NSString *vybeKey;
    NSString *vybePath;
    NSString *videoPath;
    NSString *thumbnailPath;
    NSDate *timeStamp;
    int upStatus; int downStatus;
}
- (id)initWithDeviceId:(NSString *)devId;
- (void)setDeviceId:(NSString *)devId;
- (void)setVybeKey:(NSString *)vyKey;
- (void)setTribeVybeKey:(NSString *)key;
- (void)setUpStatus:(int)us;
- (void)setDownStatus:(int)ds;
- (void)setTimeStamp:(NSDate *)date;
- (NSString *)deviceId;
- (NSString *)vybeKey;
- (NSString *)videoPath;
- (NSString *)thumbnailPath;
- (int)upStatus;
- (int)downStatus;
- (NSDate *)timeStamp;
- (NSString *)timeString;
- (NSString *)dateString;
- (BOOL)isFresherThan:(VYBVybe *)comp;
@end
