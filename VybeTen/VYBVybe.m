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
        [self setUploaded:[aDecoder decodeBoolForKey:@"uploaded"]];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:videoPath forKey:@"videoPath"];
    [aCoder encodeObject:thumbnailPath forKey:@"thumbnailPath"];
    [aCoder encodeObject:timeStamp forKey:@"timeStamp"];
    [aCoder encodeBool:uploaded forKey:@"uploaded"];
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

- (void)setUploaded:(BOOL)up {
    uploaded = up;
}

- (NSString *)videoPath {
    return videoPath;
}

- (NSString *)thumbnailPath {
    return thumbnailPath;
}

- (NSString *)dateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:usLocale];

    return [dateFormatter stringFromDate:timeStamp];
}

- (NSString *)timeString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:usLocale];
    
    return [dateFormatter stringFromDate:timeStamp];
}

- (NSDate *)timeStamp {
    return timeStamp;
}

- (BOOL)isUploaded {
    return uploaded;
}

- (NSData *)getVideo {
    return [[NSData alloc] initWithContentsOfFile:videoPath];
}


@end
