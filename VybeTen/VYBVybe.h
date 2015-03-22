//
//  VYBVybe.h
//  VybeTen
//
//  Created by jinsuk on 10/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

@class PFObject;
@class CLLocation;

@interface VYBVybe : NSObject
@property (nonatomic) NSString *uniqueFileName;
@property (nonatomic) CLLocation *locationCL;

- (VYBVybe *)initWithParseObject:(PFObject *)parseObj;
- (VYBVybe *)initWithVybeObject:(VYBVybe *)aVybe;
- (PFObject *)parseObject;
- (NSString *)videoFilePath;
- (NSString *)thumbnailFilePath;

@end
