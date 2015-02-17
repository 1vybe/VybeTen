//
//  VYBVybe.m
//  VybeTen
//
//  Created by jinsuk on 10/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBVybe.h"
#import "Vybe-Swift.h"

@interface VYBVybe ()
@property (nonatomic) NSMutableDictionary *parseObjectDictionary;
@end

@implementation VYBVybe
@synthesize uniqueFileName;
@synthesize parseObjectDictionary;
@synthesize locationCL;

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

- (VYBVybe *)initWithParseObject:(PFObject *)parseObj {
  self = [super init];
  if (self) {
    parseObjectDictionary = [NSMutableDictionary dictionaryWithDictionary:
                             [parseObj dictionaryWithValuesForKeys:[parseObj allKeys]]];
    uniqueFileName = [self generateUniqueFileName];
  }
  return self;
}

- (VYBVybe *)initWithVybeObject:(VYBVybe *)aVybe {
  // raw parse object doese not include PFObjects such as user, geoPoint, and ACL because they are not NSCoding.
  self = [self initWithParseObject:[aVybe rawParseObject]];
  if (self) {
    uniqueFileName = aVybe.uniqueFileName;
    locationCL = aVybe.locationCL;
  }
  return self;
}

- (PFObject *)parseObject {
  PFObject *parseObj = [PFObject objectWithClassName:kVYBVybeClassKey dictionary:self.parseObjectDictionary];
  
  [parseObj setObject:[PFUser currentUser] forKey:kVYBVybeUserKey];
  
  PFACL *vybeACL = [PFACL ACLWithUser:[PFUser currentUser]];
  [vybeACL setPublicReadAccess:YES];
  parseObj.ACL = vybeACL;
  
  if (self.locationCL)
    [parseObj setObject:[PFGeoPoint geoPointWithLocation:self.locationCL] forKey:kVYBVybeGeotagKey];
  
  return parseObj;
}

- (PFObject *)rawParseObject {
  PFObject *parseObj = [PFObject objectWithClassName:kVYBVybeClassKey dictionary:self.parseObjectDictionary];
  
  return parseObj;
}

- (NSString *)videoFilePath {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *thePath = [[paths lastObject] stringByAppendingPathComponent:@"VybeToUpload"];
  
  NSString *videoPath = [thePath stringByAppendingPathComponent:self.uniqueFileName];
  
  return [videoPath stringByAppendingPathExtension:@"mp4"];
}

- (NSString *)thumbnailFilePath {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *thePath = [[paths lastObject] stringByAppendingPathComponent:@"VybeToUpload"];
  
  NSString *thumbnailPath = [thePath stringByAppendingPathComponent:self.uniqueFileName];
  
  return [thumbnailPath stringByAppendingPathExtension:@"jpeg"];
}

- (void)setTribe:(PFObject *)tribe {
  [parseObjectDictionary setObject:tribe forKey:kVYBVybeTribeKey];
}

@end
