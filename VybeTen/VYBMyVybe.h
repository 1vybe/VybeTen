//
//  VYBMyVybe.h
//  VybeTen
//
//  Created by jinsuk on 5/23/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Parse/Parse.h>

@interface VYBMyVybe : NSObject <NSCoding> {
    
}
@property (nonatomic, strong) NSString *uniqueFileName;
@property (nonatomic, strong) CLLocation *geoTag;
@property (nonatomic, strong) NSString *locationString; // 'neighborhood,city,countrycode' (country code is 3166-1 alpha-2)
@property (nonatomic, strong) NSDate *timeStamp;
@property (nonatomic) BOOL isPublic;
//@property (nonatomic, strong) NSString *tribeObjectID;
@property (nonatomic, strong) NSString *videoFileObjectID;
@property (nonatomic, strong) NSString *thumbnailFileObjectID;

//- (id)initWithParseObjectVybe:(PFObject *)aVybe;
- (PFObject *)parseObjectVybe;
- (NSString *)videoFilePath;
- (NSString *)thumbnailFilePath;
- (PFGeoPoint *)location;
- (void)setGeoTagFrom:(PFGeoPoint *)aGeoPoint;

@end
