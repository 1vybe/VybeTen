//
//  VYBVybe.h
//  VybeTen
//
//  Created by jinsuk on 10/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VYBZone;
@interface VYBVybe : NSObject
@property (nonatomic) CLLocation *locationCL;
@property (nonatomic) VYBZone *vybeZone;

- (VYBVybe *)initWithParseObject:(PFObject *)parseObj;
- (PFObject *)parseObject;
- (NSString *)videoFilePath;
- (NSString *)thumbnailFilePath;
- (NSString *)locationString;
- (NSString *)tagString;

- (void)setTag:(NSString *)tag;
- (void)setLocationString:(NSString *)locationString;
- (BOOL)hasLocationData;
@end
