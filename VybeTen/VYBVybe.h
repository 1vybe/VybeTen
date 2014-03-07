//
//  VYBVybe.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 24..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VYBVybe : NSObject <NSCoding> {
    NSString *vybePath;
    NSString *videoPath;
    NSString *thumbnailPath;
    NSDate *timeStamp;
}
- (void)setVybePath:(NSString *)vybePath;
- (void)setVideoPath:(NSString *)vidPath;
- (void)setThumbnailPath:(NSString *)thumbPath;
- (void)setTimeStamp:(NSDate *)date;
- (NSString *)getVideoPath;
- (NSString *)getThumbnailPath;
- (NSString *)getTimeString;
- (NSString *)getDateString;
- (NSDate *)getTimeStamp;
- (NSData *)getVideo;



@end
