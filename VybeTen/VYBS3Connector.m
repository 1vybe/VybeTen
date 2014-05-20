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

- (void)startDownloading:(S3GetObjectRequest *)req forVybe:(VYBVybe *)v {
    self.request = req;
    [req setDelegate:self];
    [req setRequestTag:[v vybeKey]];
    [v setDownStatus:DOWNLOADING];
    [s3 getObject:req];
}

- (void)startFeaturedRequest:(S3ListObjectsRequest *)req {
    [req setDelegate:self];
    [req setRequestTag:@"FeaturedVybes"];
    [s3 listObjects:req];
    
    if (!sharedConnectionList)
        sharedConnectionList = [[NSMutableArray alloc] init];
    
    [sharedConnectionList addObject:self];
}

- (void)startTrendingRequest:(S3ListObjectsRequest *)req {
    [req setDelegate:self];
    [req setRequestTag:@"TrendingVybes"];
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
        
        NSLog(@"There are %lu tribes in the server", (unsigned long)[result.buckets count]);
        
        NSMutableArray *newTribes = [[NSMutableArray alloc] init];
        for (S3Bucket *bucket in result.buckets) {
            if ([bucket.name isEqualToString:@"vybes"] || [bucket.name isEqualToString:@"NUNS-ISLAND"] || [bucket.name isEqualToString:@"CERCLE"]
                || [bucket.name isEqualToString:@"mtl_D3"] || [bucket.name isEqualToString:@"mtl_vybes"] || [bucket.name isEqualToString:@"mtl_D3"]
                || [bucket.name isEqualToString:@"vybe-featured"] || [bucket.name isEqualToString:@"vybe-trending"] || [bucket.name isEqualToString:@"amino"]) {
            }
         else {
             // If there already exists a tribe, copy its vybes into new
             if ( [[VYBMyTribeStore sharedStore] hasTribe:bucket.name] ) {
                 VYBTribe *tribe =[[VYBMyTribeStore sharedStore] tribe:bucket.name];
                 [newTribes addObject:tribe];
             } else {
                 VYBTribe *newT = [[VYBTribe alloc] initWithTribeName:bucket.name];
                 [newTribes addObject:newT];
             }
         }
        }
        [[VYBMyTribeStore sharedStore] setMyTribes:newTribes];
        [self completionBlock](nil);
        [sharedConnectionList removeObject:self];
    }
    /* TODO: Should only download new vybes and apply updates/deletes */
    else if ( [request.requestTag isEqualToString:@"TribeVybes"] ) {
        S3ListObjectsResponse *listResponse = (S3ListObjectsResponse *)response;
        S3ListObjectsResult *result = listResponse.listObjectsResult;
        NSString *buckName = result.bucketName;
        NSMutableArray *newVybes = [[NSMutableArray alloc] init];
        NSLog(@"Server has %lu videos for %@ Tribe", (unsigned long)[result.objectSummaries count], buckName);
        VYBTribe *tr = [[VYBMyTribeStore sharedStore] tribe:buckName];
        // Reset vybes of a tribe everytime this method is called
        [tr setVybes:newVybes];
        //TODO: this if statement should check the total number of NEW vybes ONLY
        if ([result.objectSummaries count] > 0) {
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
        }
        [self completionBlock](nil);
        [sharedConnectionList removeObject:self];
    }
    
    else if ( [request.requestTag isEqualToString:@"FeaturedVybes"] ) {
        S3ListObjectsResponse *listResponse = (S3ListObjectsResponse *)response;
        S3ListObjectsResult *result = listResponse.listObjectsResult;
        NSString *buckName = result.bucketName;
        NSLog(@"Server has %lu videos for %@ Tribe", (unsigned long)[result.objectSummaries count], buckName);
        //TODO: this if statement should check the total number of NEW vybes ONLY
        if ([result.objectSummaries count] == 0)
            return;
        else {
            //NSLog(@"adding begins");
            for (S3ObjectSummary *obj in result.objectSummaries) {
                NSCharacterSet *delimiters = [NSCharacterSet characterSetWithCharactersInString:@"/"];
                NSArray *strings = [[obj key] componentsSeparatedByCharactersInSet:delimiters];
                NSString *featureName = [strings objectAtIndex:0];
                /*
                if (![[[VYBMyTribeStore sharedStore] featuredTribes] objectForKey:featureName]) {
                    VYBTribe *trb = [[VYBTribe alloc] initWithTribeName:featureName];
                    [[[VYBMyTribeStore sharedStore] featuredTribes] setObject:trb forKey:featureName];
                }
                VYBTribe *tribe = [[[VYBMyTribeStore sharedStore] featuredTribes] objectForKey:featureName];
                */
                // will be added ONLY if new
                VYBVybe *newV = [[VYBVybe alloc] init];
                [newV setVybeKey:[strings objectAtIndex:1]];
                [newV setTribeName:featureName];
                [newV setTribeVybePathWith:featureName];
                //[newV setDeviceId:[self extractDeviceIdFrom:[obj key]]];
                [newV setDownStatus:DOWNFRESH];
                // Tribe will add this vybe ONLY IF NEW
                //[tribe addVybe:newV];
                
                //NSLog("@After insertion in FEATURE: %d",[[(VYBTribe *)[[[VYBMyTribeStore sharedStore] featuredTribes] objectForKey:featureName] vybes] count]);
            }
        }
    }
    
    else {
        S3GetObjectRequest *getReq = (S3GetObjectRequest *)request;
        NSLog(@"[%@]ASYNC DOWN SUCCESS", [getReq bucket]);
        VYBTribe *tribe = [[VYBMyTribeStore sharedStore] tribe:[getReq bucket]];
        VYBVybe *v = [tribe vybeWithKey:request.requestTag];
        NSString *videoPath = [v tribeVideoPath];
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:videoPath];
        NSData *videoReceived = [[NSData alloc] initWithData:response.body];
        [videoReceived writeToURL:outputURL atomically:YES];
        
        //[tribe changeDownStatusFor:request.requestTag withStatus:DOWNLOADED];
        [v setDownStatus:DOWNLOADED];
        [[VYBMyTribeStore sharedStore] saveThumbnailImageForVybe:v];
        [self completionBlock](nil);
        [[VYBMyTribeStore sharedStore] downloadNextVybeOf:v];
        
        videoReceived = nil;
    }
}

- (void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error {
    if ([request.requestTag isEqualToString:@"TribeList"]) {
        
    } else if ([request.requestTag isEqualToString:@"TribeVybes"]) {
        
    } else if ([request.requestTag isEqualToString:@"FeaturedVybes"]) {
        
    } else {
        NSLog(@"Error occured while receiving a file");
        S3GetObjectRequest *getReq = (S3GetObjectRequest *)request;
        VYBTribe *tribe = [[VYBMyTribeStore sharedStore] tribe:[getReq bucket]];
        [tribe changeDownStatusFor:request.requestTag withStatus:DOWNFRESH];

    }
    [self completionBlock](error);
    [sharedConnectionList removeObject:self];
    
}

- (void)stopDownloading {
    [[self.request urlConnection] cancel];
}

@end
