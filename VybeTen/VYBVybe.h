//
//  VYBVybe.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 24..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

@interface VYBVybe : NSObject <NSCoding, CLLocationManagerDelegate> {
    NSString *deviceId;
    NSString *vybeKey;
    NSString *vybePath;
    NSString *videoPath;
    NSString *thumbnailPath;
    NSString *tribeName;
    NSDate *timeStamp;
    CLLocation *location;
    int upStatus; int downStatus;
}
- (id)initWithDeviceId:(NSString *)devId;
- (void)setDeviceId:(NSString *)devId;
- (void)setVybeKey:(NSString *)vyKey;
- (void)setTribeVybePathWith:(NSString *)name;
- (void)setUpStatus:(int)us;
- (void)setDownStatus:(int)ds;
- (void)setTimeStamp:(NSDate *)date;
- (void)setLocation:(CLLocation *)loc;
- (void)setTribeName:(NSString *)name;
- (NSString *)deviceId;
- (NSString *)vybeKey;
- (NSString *)videoPath;
- (NSString *)thumbnailPath;
- (NSString *)tribeVideoPath;
- (NSString *)tribeThumbnailPath;
- (NSString *)tribeName;
- (int)upStatus;
- (int)downStatus;
- (NSDate *)timeStamp;
- (CLLocation *)location;
- (NSString *)timeString;
- (NSString *)dateString;
- (NSString *)howOld;
- (BOOL)isFresherThan:(VYBVybe *)comp;
@end
