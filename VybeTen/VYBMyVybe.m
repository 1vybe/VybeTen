//
//  VYBMyVybe.m
//  VybeTen
//
//  Created by jinsuk on 5/23/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBMyVybe.h"
#import "VYBUtility.h"

@implementation VYBMyVybe

@synthesize uniqueFileName, geoTag, locationName, timeStamp, tribeObjectID, videoFileObjectID, thumbnailFileObjectID;

- (id)init {
    self = [super init];
    
    if (self) {
        uniqueFileName = [self generateUniqueFileName];
    }
    
    return self;
}

- (NSString *)generateUniqueFileName {
    //Create unique filename
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *uniquePath = [[paths lastObject] stringByAppendingPathComponent:@"VybeToUpload"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:uniquePath])
        [[NSFileManager defaultManager] createDirectoryAtPath:uniquePath withIntermediateDirectories:YES attributes:nil error:nil];
    
    CFUUIDRef newUniqueId = CFUUIDCreate(kCFAllocatorDefault);
	CFStringRef newUniqueIdString = CFUUIDCreateString(kCFAllocatorDefault, newUniqueId);
	uniquePath = [uniquePath stringByAppendingPathComponent:(__bridge NSString *)newUniqueIdString];
	CFRelease(newUniqueId);
	CFRelease(newUniqueIdString);
    
    return uniquePath;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    
    if (self) {
        [self setUniqueFileName:[aDecoder decodeObjectForKey:@"uniqueFileName"]];
        [self setGeoTag:[aDecoder decodeObjectForKey:kVYBVybeGeotag]];
        [self setLocationName:[aDecoder decodeObjectForKey:kVYBVybeLocationName]];
        [self setTimeStamp:[aDecoder decodeObjectForKey:kVYBVybeTimestampKey]];
        [self setTribeObjectID:[aDecoder decodeObjectForKey:kVYBVybeTribeKey]];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:uniqueFileName forKey:@"uniqueFileName"];
    [aCoder encodeObject:geoTag forKey:kVYBVybeGeotag];
    [aCoder encodeObject:locationName forKey:kVYBVybeLocationName];
    [aCoder encodeObject:timeStamp forKey:kVYBVybeTimestampKey];
    [aCoder encodeObject:tribeObjectID forKey:kVYBVybeTribeKey];
}

- (void)setGeoTagFrom:(PFGeoPoint *)aGeoPoint {
    geoTag = [[CLLocation alloc] initWithLatitude:aGeoPoint.latitude longitude:aGeoPoint.longitude];

}

- (void)setTribeObjectID:(NSString *)tribeID {
    tribeObjectID = tribeID;
}


- (PFObject *)parseObjectVybe {
    PFObject *theVybe = [PFObject objectWithClassName:kVYBVybeClassKey];
    
    PFObject *theTribe = [PFObject objectWithoutDataWithClassName:kVYBTribeClassKey objectId:tribeObjectID];
    [theVybe setObject:theTribe forKey:kVYBVybeTribeKey];
    
    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:geoTag.coordinate.latitude longitude:geoTag.coordinate.longitude];
    [theVybe setObject:geoPoint forKey:kVYBVybeGeotag];
    
    if (locationName) {
        [theVybe setObject:locationName forKey:kVYBVybeLocationName];
    }
    
    [theVybe setObject:timeStamp forKey:kVYBVybeTimestampKey];
    [theVybe setObject:[PFUser currentUser] forKey:kVYBVybeUserKey];

    return theVybe;
}

- (NSString *)videoFilePath {
    return [uniqueFileName stringByAppendingPathExtension:@"mov"];
}

- (NSString *)thumbnailFilePath {
    return [uniqueFileName stringByAppendingPathExtension:@"jpeg"];
}




@end
