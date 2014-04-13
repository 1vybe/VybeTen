//
//  VYBS3Connector.h
//  VybeTen
//
//  Created by jinsuk on 4/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSS3/AWSS3.h>

@interface VYBS3Connector : NSObject <AmazonServiceRequestDelegate> {
    AmazonS3Client *s3;
    NSMutableData *container;
}

- (id)initWithClient:(AmazonS3Client *)client completionBlock:(void (^)(NSError *err))block;

@property (nonatomic, copy) S3ListBucketsRequest *request;
@property (nonatomic, copy) void (^completionBlock) (NSError *err);

- (void)startTribeListRequest:(S3ListBucketsRequest *)req;
- (void)startTribeVybesRequest:(S3ListObjectsRequest *)req;

@end
