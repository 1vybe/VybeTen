//
//  VYBVybe.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 24..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VYBVybe : NSObject <NSCoding> {
    NSString *videoPath;
    UIImage *thumbnailImg;
    NSDate *timeStamp;
}

- (void)setVideoPath:(NSString *)vidPath;
- (void)setThumbnailImg:(UIImage *)thumbpath;
- (void)setTimeStamp:(NSDate *)date;
- (UIImage *)getThumbnail;
- (NSData *)getVideo;


@end
