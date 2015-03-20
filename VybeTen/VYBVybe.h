//
//  VYBVybe.h
//  VybeTen
//
//  Created by jinsuk on 10/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>
@class PFObject;
@class CLLocation;
@interface VYBVybe : NSObject
@property (nonatomic) NSString *uniqueFileName;
@property (nonatomic) CLLocation *locationCL;
//@property (nonatomic) VYBZone *vybeZone;

- (VYBVybe *)initWithParseObject:(PFObject *)parseObj;
- (VYBVybe *)initWithVybeObject:(VYBVybe *)aVybe;
- (PFObject *)parseObject;
- (NSString *)videoFilePath;
- (NSString *)thumbnailFilePath;

- (void)setTribe:(PFObject *)tribe;

//- (NSString *)locationString;
//- (NSString *)tagString;
//- (NSString *)zoneID;
//- (NSString *)zoneName;
//- (void)setVybeZone:(Zone *)zone;
//- (void)setTag:(NSString *)tag;
//- (void)setLocationString:(NSString *)locationString;
//- (BOOL)hasLocationData;


@end
