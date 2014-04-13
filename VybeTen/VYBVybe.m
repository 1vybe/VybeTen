//
//  VYBVybe.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 24..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBVybe.h"
#import "VYBConstants.h"
#import "VYBMyTribeStore.h"

@implementation VYBVybe {
    NSDateFormatter *dFormatter;
    CLLocationManager *locationManager;
}

- (id)init {
    self = [super init];
    if (self) {
        dFormatter = [[NSDateFormatter alloc] init];
        dFormatter = [[VYBMyTribeStore sharedStore] presetDateFormatter];
    }
    return self;
}

/*** This method should be called ONLY when capturing a new vybe. ***/
- (id)initWithDeviceId:(NSString *)devId {
    self = [self init];
    if (self) {
        [self setUpStatus:UPFRESH];
        // Save current location
        locationManager = [[CLLocationManager alloc] init];
        [locationManager setDelegate:self];
        [locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
        [locationManager startUpdatingLocation];
        
        // Save current time
        NSDate *now = [NSDate date];
        [self setDeviceId:devId];
        [self setTimeStamp:now];
        NSString *dateString = [dFormatter stringFromDate:now];
        NSString *keyString = [NSString stringWithFormat:@"[%@]%@", deviceId, dateString];
        [self setVybeKey:keyString];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        [self setDeviceId:[aDecoder decodeObjectForKey:@"deviceId"]];
        [self setVybeKey:[aDecoder decodeObjectForKey:@"vybeKey"]];
        [self setTribeName:[aDecoder decodeObjectForKey:@"tribeName"]];
        [self setVideoPath:[aDecoder decodeObjectForKey:@"videoPath"]];
        [self setThumbnailPath:[aDecoder decodeObjectForKey:@"thumbnailPath"]];
        [self setTimeStamp:[aDecoder decodeObjectForKey:@"timeStamp"]];
        [self setLocation:[aDecoder decodeObjectForKey:@"location"]];
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
    [aCoder encodeObject:tribeName forKey:@"tribeName"];
    [aCoder encodeObject:videoPath forKey:@"videoPath"];
    [aCoder encodeObject:thumbnailPath forKey:@"thumbnailPath"];
    [aCoder encodeObject:timeStamp forKey:@"timeStamp"];
    [aCoder encodeObject:location forKey:@"location"];
    if (upStatus == UPLOADING)
        upStatus = UPFRESH;
    [aCoder encodeInt:upStatus forKey:@"upStatus"];
    if (downStatus == DOWNLOADING)
        downStatus = DOWNFRESH;
    [aCoder encodeInt:downStatus forKey:@"downStatus"];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [self setLocation:[locations lastObject]];
    [locationManager stopUpdatingLocation];
    locationManager = nil;
    NSLog(@"Vybe taken at %@",location);
}

- (void)setDeviceId:(NSString *)devId {
    deviceId = devId;
}

- (void)setVybeKey:(NSString *)vyKey {
    vybeKey = vyKey;
    [self setVybePath];
    if (!timeStamp) {
        //NSLog(@"timeStamp will be created for the first time for thie vybe");
        NSDate *date = [self decodeKeyString:vyKey];
        [self setTimeStamp:date];
    }

}

- (void)setTribeName:(NSString *)name {
    tribeName = name;
}

/* Returns a date object from the key string */
- (NSDate *)decodeKeyString:(NSString *)str {
    //NSLog(@"encoding string: %@", str);
    NSCharacterSet *delimiters = [NSCharacterSet characterSetWithCharactersInString:@"[]"];
    NSArray *strings = [str componentsSeparatedByCharactersInSet:delimiters];
    // Extracts and saves deviceId information
    [self setDeviceId:[strings objectAtIndex:1]];
    // Extracts and saves date information
    NSString *dateString = [strings objectAtIndex:2];
    NSDate *date = [dFormatter dateFromString:dateString];
    //NSLog(@"after encoding: %@", date);
    return date;
}

- (void)setVybePath {
    /*
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    */
    /**
     * Instead you should always make a dynamic reference by only saving the filepath after you've gotten the documents
     * directory filepath prefix.
     **/
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *vidPath = [documentsDirectory stringByAppendingPathComponent:vybeKey];
    vidPath = [vidPath stringByAppendingString:@".mov"];
    [self setVideoPath:vidPath];
    [self setThumbnailPath:[vidPath stringByReplacingOccurrencesOfString:@".mov" withString:@".jpeg"]];
}

- (void)setTribeVybePathWith:(NSString *)name {
    /*
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
     */
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *vidPath = [documentsDirectory stringByAppendingPathComponent:@"Tribe"];
    vidPath = [vidPath stringByAppendingPathComponent:name];
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
    timeStamp = date;
}

- (void)setLocation:(CLLocation *)loc {
    location = loc;
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

- (NSString *)tribeName {
    return tribeName;
}

- (NSString *)videoPath {
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *vidPath = [documentsDirectory stringByAppendingPathComponent:vybeKey];
    vidPath = [vidPath stringByAppendingString:@".mov"];
    [self setVideoPath:vidPath];
    return vidPath;
}

- (NSString *)tribeVideoPath {
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *vidPath = [documentsDirectory stringByAppendingPathComponent:@"Tribe"];
    vidPath = [vidPath stringByAppendingPathComponent:tribeName];
    vidPath = [vidPath stringByAppendingPathComponent:vybeKey];
    vidPath = [vidPath stringByAppendingString:@".mov"];
    //[self setVideoPath:vidPath];
    return vidPath;
}

- (NSString *)thumbnailPath {
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *thumbPath = [documentsDirectory stringByAppendingPathComponent:vybeKey];
    thumbPath = [thumbPath stringByAppendingString:@".jpeg"];
    //[self setThumbnailPath:thumbPath];
    return thumbPath;
}

- (NSString *)tribeThumbnailPath {
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *thumbPath = [documentsDirectory stringByAppendingPathComponent:@"Tribe"];
    thumbPath = [thumbPath stringByAppendingPathComponent:tribeName];
    thumbPath = [thumbPath stringByAppendingPathComponent:vybeKey];
    thumbPath = [thumbPath stringByAppendingString:@".jpeg"];
    //[self setThumbnailPath:thumbPath];
    return thumbPath;
}

- (NSString *)dateString {
    NSDateFormatter *dateForm = [[NSDateFormatter alloc] init];
    [dateForm setDateStyle:NSDateFormatterMediumStyle];
    [dateForm setTimeStyle:NSDateFormatterNoStyle];
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateForm setLocale:usLocale];
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [dateForm setTimeZone:gmt];

    return [dateForm stringFromDate:timeStamp];
}

- (NSString *)timeString {
    NSDateFormatter *dateForm = [[NSDateFormatter alloc] init];
    [dateForm setTimeStyle:NSDateFormatterShortStyle];
    [dateForm setDateStyle:NSDateFormatterNoStyle];
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateForm setLocale:usLocale];
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [dateForm setTimeZone:gmt];
    
    return [dateForm stringFromDate:timeStamp];
}

- (NSDate *)timeStamp {
    return timeStamp;
}

- (CLLocation *)location {
    return location;
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
    //NSLog(@"%@ VS %@", [self timeStamp], [comp timeStamp]);
    if ([[self timeStamp] compare:[comp timeStamp]] == NSOrderedDescending) {
        //NSLog(@"date1 is later than date2");
        return YES;
    } else {
        //NSLog(@"date1 is older than date2");
        return NO;
    }
}

- (NSString *)howOld {
    NSDate *now = [NSDate date];
    NSTimeInterval timeDiff = [now timeIntervalSinceDate:[self timeStamp]];
    int timeD = (int)timeDiff;
    NSString *timePassedBy;
    if (timeD >= 3600 * 24 * 365)
        timePassedBy = [NSString stringWithFormat:@"%d %@ ago ", timeD/(3600*24*365), (timeD/(3600*24*365) == 1) ? @"year" : @"years"];
    if (timeD >= 3600 * 24 * 30)
        timePassedBy = [NSString stringWithFormat:@"%d %@ ago ", timeD/(3600*24*30), (timeD/(3600*24*30) == 1) ? @"month" : @"months"];
    else if (timeD >= 3600 * 24 * 7)
        timePassedBy = [NSString stringWithFormat:@"%d %@ ago ", timeD/(3600*24*7), (timeD/(3600*24*7) == 1) ? @"week" : @"weeks"];
    else if (timeD >= 3600 * 24)
        timePassedBy = [NSString stringWithFormat:@"%d %@ ago ", timeD/(3600*24), (timeD/(3600*24) == 1) ? @"day" : @"days"];
    else if (timeD >= 3600)
        timePassedBy = [NSString stringWithFormat:@"%dh %dm ago ", timeD/3600, (timeD%3600)/60];
    else if (timeD >= 60)
        timePassedBy = [NSString stringWithFormat:@"%dm %ds ago ", timeD/60, timeD%60];
    else
        timePassedBy = [NSString stringWithFormat:@"%ds ago ", timeD];
    
    return timePassedBy;
}




@end
