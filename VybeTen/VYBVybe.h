//
//  VYBVybe.h
//  VybeTen
//
//  Created by jinsuk on 10/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VYBVybe : NSObject
- (VYBVybe *)initWithParseObject:(PFObject *)parseObj;
- (PFObject *)parseObject;
- (NSString *)videoFilePath;
- (NSString *)thumbnailFilePath;
- (NSString *)locationString;

- (void)setGeoTag:(CLLocation *)location;
- (void)setLocationString:(NSString *)locationString;
- (BOOL)hasLocationData;
@end
