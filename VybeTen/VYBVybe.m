//
//  VYBVybe.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 24..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBVybe.h"


@implementation VYBVybe

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        [self setVideoPath:[aDecoder decodeObjectForKey:@"videoPath"]];
        [self setThumbnailPath:[aDecoder decodeObjectForKey:@"thumbnailPath"]];
        [self setTimeStamp:[aDecoder decodeObjectForKey:@"timeStamp"]];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:videoPath forKey:@"videoPath"];
    [aCoder encodeObject:thumbnailPath forKey:@"thumbnailPath"];
    [aCoder encodeObject:timeStamp forKey:@"timeStamp"];
}

- (void)setVybePath:(NSString *)vyPath {
    vybePath = vyPath;
    [self setVideoPath:[NSString stringWithFormat:@"%@.mov", vyPath]];
    [self setThumbnailPath:[NSString stringWithFormat:@"%@.jpeg", vyPath]];
}

- (void)setVideoPath:(NSString *)vidPath {
    videoPath = vidPath;
}

- (void)setThumbnailPath:(NSString *)thumbPath {
    thumbnailPath = thumbPath;
}

- (void)setTimeStamp:(NSDate *)date {
    timeStamp = date;
}

- (NSString *)getVideoPath {
    return videoPath;
}

- (NSString *)getThumbnailPath {
    return thumbnailPath;
}

- (NSString *)getDateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:usLocale];

    return [dateFormatter stringFromDate:timeStamp];
}

- (NSString *)getTimeString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:usLocale];
    
    return [dateFormatter stringFromDate:timeStamp];
}

- (NSDate *)getTimeStamp {
    return timeStamp;
}

- (NSData *)getVideo {
    return [[NSData alloc] initWithContentsOfFile:videoPath];
}


@end
