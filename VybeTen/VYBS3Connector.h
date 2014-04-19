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
}

- (id)initWithClient:(AmazonS3Client *)client completionBlock:(void (^)(NSError *err))block;

@property (nonatomic) S3ListBucketsRequest *request;
@property (nonatomic, copy) void (^completionBlock) (NSError *err);

- (void)startTribeListRequest:(S3ListBucketsRequest *)req;
- (void)startTribeVybesRequest:(S3ListObjectsRequest *)req;
- (void)startFeaturedRequest:(S3ListObjectsRequest *)req;
- (void)startTrendingRequest:(S3ListObjectsRequest *)req;

@end
