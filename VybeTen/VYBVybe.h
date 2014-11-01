//
//  VYBVybe.h
//  VybeTen
//
//  Created by jinsuk on 10/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VYBVybe : NSObject
@property (nonatomic) CLLocation *locationCL;

- (VYBVybe *)initWithParseObject:(PFObject *)parseObj;
- (PFObject *)parseObject;
- (NSString *)videoFilePath;
- (NSString *)thumbnailFilePath;
- (NSString *)locationString;
- (NSString *)tagString;

- (void)setTag:(NSString *)tag;
- (void)setGeoTag:(CLLocation *)location;
- (void)setLocationString:(NSString *)locationString;
- (BOOL)hasLocationData;
@end
