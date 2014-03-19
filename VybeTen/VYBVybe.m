//
//  VYBVybe.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 24..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBVybe.h"
#import "VYBConstants.h"


@implementation VYBVybe

- (id)initWithDeviceId:(NSString *)devId {
    self = [super init];
    if (self) {
        [self setUpStatus:UPFRESH];
        NSDate *now = [NSDate date];
        [self setDeviceId:devId];
        [self setTimeStamp:now];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        [self setDeviceId:[aDecoder decodeObjectForKey:@"deviceId"]];
        [self setVybeKey:[aDecoder decodeObjectForKey:@"vybeKey"]];
        [self setVideoPath:[aDecoder decodeObjectForKey:@"videoPath"]];
        [self setThumbnailPath:[aDecoder decodeObjectForKey:@"thumbnailPath"]];
        [self setTimeStamp:[aDecoder decodeObjectForKey:@"timeStamp"]];
        [self setUpStatus:[aDecoder decodeIntForKey:@"upStatus"]];
        if (upStatus == UPLOADING)
            upStatus = UPFRESH;
        [self setDownStatus:[aDecoder decodeIntForKey:@"downStatus"]];
        if (downStatus == DOWNLOADING)
            downStatus = DOWNFRESH;
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:deviceId forKey:@"deviceId"];
    [aCoder encodeObject:vybeKey forKey:@"vybeKey"];
    [aCoder encodeObject:videoPath forKey:@"videoPath"];
    [aCoder encodeObject:thumbnailPath forKey:@"thumbnailPath"];
    [aCoder encodeObject:timeStamp forKey:@"timeStamp"];
    [aCoder encodeInt:upStatus forKey:@"upStatus"];
    [aCoder encodeInt:downStatus forKey:@"downStatus"];
}

- (void)setDeviceId:(NSString *)devId {
    deviceId = devId;
}

- (void)setVybeKey:(NSString *)vyKey {
    vybeKey = vyKey;
    [self setVybePath];
    if (!timeStamp) {
        //NSLog(@"timeStamp will be created for the first time for thie vybe");
        NSDate *date = [self encodeKeyString:vyKey];
        [self setTimeStamp:date];
    }

}

- (void)setTribeVybeKey:(NSString *)vyKey {
    vybeKey = vyKey;
    [self setTribeVybePath];
    if (!timeStamp) {
        //NSLog(@"timeStamp will be created for the first time for thie vybe");
        NSDate *date = [self encodeKeyString:vyKey];
        [self setTimeStamp:date];
    }
}

/* Returns a date object from the key string */
- (NSDate *)encodeKeyString:(NSString *)str {
    //NSLog(@"encoding string: %@", str);
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss:SSS"];
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [formatter setTimeZone:gmt];
    NSCharacterSet *delimiters = [NSCharacterSet characterSetWithCharactersInString:@"[]"];
    // Extracts and saves deviceId information
    [self setDeviceId:[[str componentsSeparatedByCharactersInSet:delimiters] objectAtIndex:1]];
    // Extracts and saves date information
    NSString *dateString = [[str componentsSeparatedByCharactersInSet:delimiters] objectAtIndex:2];
    NSDate *date = [formatter dateFromString:dateString];
    //NSLog(@"after encoding: %@", date);
    return date;
}

- (void)setVybePath {
    // Path to save in the application's document directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *vidPath = [documentsDirectory stringByAppendingPathComponent:vybeKey];
    vidPath = [vidPath stringByAppendingString:@".mov"];
    [self setVideoPath:vidPath];
    [self setThumbnailPath:[vidPath stringByReplacingOccurrencesOfString:@".mov" withString:@".jpeg"]];
}

- (void)setTribeVybePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *vidPath = [documentsDirectory stringByAppendingPathComponent:@"Tribe"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:vidPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:vidPath withIntermediateDirectories:YES attributes:nil error:nil];
    vidPath = [vidPath stringByAppendingPathComponent:vybeKey];
    vidPath = [vidPath stringByAppendingString:@".mov"];
    [self setVideoPath:vidPath];
    [self setThumbnailPath:[vidPath stringByReplacingOccurrencesOfString:@".mov" withString:@".jpeg"]];
}


- (void)setVideoPath:(NSString *)vidPath {
    videoPath = vidPath;
}

- (void)setThumbnailPath:(NSString *)path {
    thumbnailPath = path;
}

- (void)setTimeStamp:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss:SSS"];
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [formatter setTimeZone:gmt];
    NSString *dateString = [formatter stringFromDate:date];
    //NSLog(@"TIME NOW IS %@", date);
    NSString *keyString = [NSString stringWithFormat:@"[%@]%@", deviceId, dateString];
    //NSLog(@"KEY STRING IS %@", keyString);
    if (![self vybeKey])
        [self setVybeKey:keyString];
    timeStamp = date;
}

- (void)setUpStatus:(int)us {
    upStatus = us;
}

- (void)setDownStatus:(int)ds {
    downStatus = ds;
}

- (NSString *)vybeKey {
    return vybeKey;
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
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [dateFormatter setTimeZone:gmt];

    return [dateFormatter stringFromDate:timeStamp];
}

- (NSString *)timeString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:usLocale];
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [dateFormatter setTimeZone:gmt];
    
    return [dateFormatter stringFromDate:timeStamp];
}

- (NSDate *)timeStamp {
    return timeStamp;
}

- (NSString *)deviceId {
    return deviceId;
}

- (int)upStatus {
    return upStatus;
}

- (int)downStatus {
    return downStatus;
}

- (BOOL)isFresherThan:(VYBVybe *)comp {
    NSLog(@"%@ VS %@", [self timeStamp], [comp timeStamp]);
    if ([[self timeStamp] compare:[comp timeStamp]] == NSOrderedDescending) {
        NSLog(@"date1 is later than date2");
        return YES;
    } else {
        NSLog(@"date1 is older than date2");
        return NO;
    }
}

- (NSString *)howOld {
    NSDate *now = [NSDate date];
    NSTimeInterval timeDiff = [now timeIntervalSinceDate:[self timeStamp]];
    int timeD = (int)timeDiff;
    NSString *timePassedBy;
    if (timeD >= 3600 * 24)
        timePassedBy = [NSString stringWithFormat:@"%d %@ ago ", timeD/24, (timeD/24 == 1) ? @"day" : @"days"];
    else if (timeD >= 3600)
        timePassedBy = [NSString stringWithFormat:@"%dh %dm ago ", timeD/3600, (timeD%3600)/60];
    else if (timeD >= 60)
        timePassedBy = [NSString stringWithFormat:@"%dm %ds ago ", timeD/60, timeD%60];
    else
        timePassedBy = [NSString stringWithFormat:@"%ds ago ", timeD];
    
    return timePassedBy;
}


@end
