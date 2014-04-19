//
//  VYBS3Uploader.m
//  VybeTen
//
//  Created by jinsuk on 4/16/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBS3Uploader.h"

@implementation VYBS3Uploader

@synthesize completionBlock = _completionBlock;

- (id)initWithClient:(AmazonS3Client *)client completionBlock:(void (^)(NSError *))block {
    self = [super init];
    if (self) {
        s3 = client;
        self.completionBlock = block;
    }
    return self;
}

- (void)startTribeListRequest:(S3PutObjectRequest *)req {
    [req setDelegate:self];
}

@end
