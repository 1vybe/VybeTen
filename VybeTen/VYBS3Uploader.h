//
//  VYBS3Uploader.h
//  VybeTen
//
//  Created by jinsuk on 4/16/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSS3/AWSS3.h>

@interface VYBS3Uploader : NSObject <AmazonServiceRequestDelegate> {
    AmazonS3Client *s3;
}

- (id)initWithClient:(AmazonS3Client *)client completionBlock:(void (^)(NSError *err))block;

@property (nonatomic) S3PutObjectRequest *request;
@property (nonatomic, copy) void (^completionBlock) (NSError *err);

- (void)startTribeListRequest:(S3PutObjectRequest *)req;

@end
