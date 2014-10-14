//
//  VYBVybe.m
//  VybeTen
//
//  Created by jinsuk on 10/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBVybe.h"
@interface VYBVybe ()
@property (nonatomic) NSString *uniqueFileName;
@property (nonatomic) CLLocation *locationCL;
@property (nonatomic) NSMutableDictionary *parseObjectDictionary;
@end

@implementation VYBVybe
@synthesize uniqueFileName;
@synthesize parseObjectDictionary;
@synthesize locationCL;

- (VYBVybe *)initWithParseObject:(PFObject *)parseObj {
    self = [super init];
    if (self) {
        parseObjectDictionary = [NSMutableDictionary dictionaryWithDictionary:
                                  [parseObj dictionaryWithValuesForKeys:[parseObj allKeys]]];
        uniqueFileName = [self generateUniqueFileName];
    }
    return self;
}

- (NSString *)generateUniqueFileName {
    //Create unique filename
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *thePath = [[paths lastObject] stringByAppendingPathComponent:@"VybeToUpload"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:thePath])
        [[NSFileManager defaultManager] createDirectoryAtPath:thePath withIntermediateDirectories:YES attributes:nil error:nil];
    
    CFUUIDRef newUniqueId = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef newUniqueIdString = CFUUIDCreateString(kCFAllocatorDefault, newUniqueId);
    NSString *uniqueName = [NSString stringWithString:(__bridge NSString *)newUniqueIdString];
    CFRelease(newUniqueId);
    CFRelease(newUniqueIdString);
    
    return uniqueName;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    
    if (self) {
        [self setUniqueFileName:[aDecoder decodeObjectForKey:@"uniqueFileName"]];
        [self setLocationCL:[aDecoder decodeObjectForKey:@"location"]];
        [self setParseObjectDictionary:[NSMutableDictionary dictionaryWithDictionary:
                                        [aDecoder decodeObjectForKey:@"parseObjectDictionary"]]];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.uniqueFileName forKey:@"uniqueFileName"];
    [aCoder encodeObject:self.locationCL forKey:@"location"];
    [aCoder encodeObject:self.parseObjectDictionary forKey:@"parseObjectDictionary"];
}

- (PFObject *)parseObject {
    PFObject *parseObj = [PFObject objectWithClassName:kVYBVybeClassKey dictionary:self.parseObjectDictionary];
    
    [parseObj setObject:[PFUser currentUser] forKey:kVYBVybeUserKey];
    
    PFACL *vybeACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [vybeACL setPublicReadAccess:YES];
    parseObj.ACL = vybeACL;
    
    if (self.locationCL)
        [parseObj setObject:[PFGeoPoint geoPointWithLocation:self.locationCL] forKey:kVYBVybeGeotag];
    
    return parseObj;
}

- (NSString *)videoFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *thePath = [[paths lastObject] stringByAppendingPathComponent:@"VybeToUpload"];
    
    NSString *videoPath = [thePath stringByAppendingPathComponent:self.uniqueFileName];
    
    return [videoPath stringByAppendingPathExtension:@"mov"];
}

- (NSString *)thumbnailFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *thePath = [[paths lastObject] stringByAppendingPathComponent:@"VybeToUpload"];
    
    NSString *thumbnailPath = [thePath stringByAppendingPathComponent:self.uniqueFileName];
    
    return [thumbnailPath stringByAppendingPathExtension:@"jpeg"];
}

- (NSString *)locationString {
    return [self.parseObjectDictionary objectForKey:kVYBVybeLocationStringKey];
}

- (void)setGeoTag:(CLLocation *)location {
    self.locationCL = location;
}

- (void)setLocationString:(NSString *)locationString {
    [self.parseObjectDictionary setObject:locationString forKey:kVYBVybeLocationStringKey];
}

- (BOOL)hasLocationData {
    return [self locationString] && ([[self locationString] length] > 0);
}

@end
