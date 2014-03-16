//
//  VYBVybe.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 24..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VYBVybe : NSObject <NSCoding> {
    NSString *vybeKey;
    NSString *vybePath;
    NSString *videoPath;
    NSString *thumbnailPath;
    NSDate *timeStamp;
    int upStatus; int downStatus;
}
- (void)setVybeKey:(NSString *)vyKey;
- (void)setVybePath:(NSString *)vyPath;
- (void)setVideoPath:(NSString *)vidPath;
- (void)setThumbnailPath:(NSString *)thumbPath;
- (void)setUpStatus:(int)us;
- (void)setDownStatus:(int)ds;
- (void)setTimeStamp:(NSDate *)date;
- (NSString *)vybeKey;
- (NSString *)videoPath;
- (NSString *)thumbnailPath;
- (int)upStatus;
- (int)downStatus;
- (NSDate *)timeStamp;
- (NSString *)timeString;
- (NSString *)dateString;

@end
