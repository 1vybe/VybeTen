//
//  VYBS3Connector.m
//  VybeTen
//
//  Created by jinsuk on 4/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBS3Connector.h"
#import "VYBMyTribeStore.h"
#import "VYBConstants.h"

static NSMutableArray *sharedConnectionList = nil;

@implementation VYBS3Connector

@synthesize request = _request;
@synthesize completionBlock = _completionBlock;

- (id)initWithClient:(AmazonS3Client *)client completionBlock:(void (^)(NSError *err))block {
    self = [super init];
    if (self) {
        s3 = client;
        self.completionBlock = block;
    }
    return self;
}

- (void)startTribeListRequest:(S3ListBucketsRequest *)req {
    [req setDelegate:self];
    [req setRequestTag:@"TribeList"];
    [s3 listBuckets:req];
    
    if (!sharedConnectionList)
        sharedConnectionList = [[NSMutableArray alloc] init];
    
    [sharedConnectionList addObject:self];
}

- (void)startTribeVybesRequest:(S3ListObjectsRequest *)req {
    [req setDelegate:self];
    [req setRequestTag:@"TribeVybes"];
    [s3 listObjects:req];

    if (!sharedConnectionList)
        sharedConnectionList = [[NSMutableArray alloc] init];
    
    [sharedConnectionList addObject:self];
}

- (void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response {
    // There was an error from the service
    if (response.exception) {
        NSError *err = [[NSError alloc] init];
        [self completionBlock](err);
        [sharedConnectionList removeObject:self];
    }
    
    if ( [request.requestTag isEqualToString:@"TribeList"] ) {
        S3ListBucketsResponse *buckets = (S3ListBucketsResponse *)response;
        S3ListBucketsResult *result = buckets.listBucketsResult;
        
        NSLog(@"There are %d tribes in the server", [result.buckets count]);
        
        NSMutableArray *newTribes = [[NSMutableArray alloc] init];
        for (S3Bucket *bucket in result.buckets) {
            if ([bucket.name isEqualToString:@"vybes"] || [bucket.name isEqualToString:@"NUNS-ISLAND"] || [bucket.name isEqualToString:@"CERCLE"] || [bucket.name isEqualToString:@"mtl_D3"] ) {
            }
         else {
             // If there already exists a tribe, copy its vybes into new
             if ( [[VYBMyTribeStore sharedStore] hasTribe:bucket.name] ) {
                 VYBTribe *tribe =[[VYBMyTribeStore sharedStore] tribe:bucket.name];
                 [newTribes addObject:tribe];
             } else {
                 VYBTribe *newT = [[VYBTribe alloc] init];
                 [newT setTribeName:bucket.name];
                 [newTribes addObject:newT];
             }
         }
        }
        
        [[VYBMyTribeStore sharedStore] setMyTribes:newTribes];
    }
    
    else if ( [request.requestTag isEqualToString:@"TribeVybes"] ) {
        S3ListObjectsResponse *listResponse = (S3ListObjectsResponse *)response;
        S3ListObjectsResult *result = listResponse.listObjectsResult;
        NSString *buckName = result.bucketName;
        NSLog(@"Server has %d videos for %@ Tribe", [result.objectSummaries count], buckName);
        //TODO: this if statement should check the total number of NEW vybes ONLY
        if ([result.objectSummaries count] == 0)
            return;
        else {
            //NSLog(@"adding begins");
            VYBTribe *tr = [[VYBMyTribeStore sharedStore] tribe:buckName];
            for (S3ObjectSummary *obj in result.objectSummaries) {
                // will be added ONLY if new
                VYBVybe *newV = [[VYBVybe alloc] init];
                [newV setVybeKey:[obj key]];
                [newV setTribeName:buckName];
                [newV setTribeVybePathWith:buckName];
                //[newV setDeviceId:[self extractDeviceIdFrom:[obj key]]];
                [newV setDownStatus:DOWNFRESH];
                // Tribe will add this vybe ONLY IF NEW
                [tr addVybe:newV];
            }
            //NSLog(@"adding done");
            [[VYBMyTribeStore sharedStore] downloadTribeVybesFor:tr];
        }
    }

    
    [self completionBlock](nil);
    [sharedConnectionList removeObject:self];
}

- (void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error {
    [self completionBlock](error);
    [sharedConnectionList removeObject:self];
    
}

- (void)request:(AmazonServiceRequest *)request didReceiveData:(NSData *)data {
    
}

@end
