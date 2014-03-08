//
//  VYBMyTribeStore.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 8..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <AWSRuntime/AWSRuntime.h>
#import "VYBMyTribeStore.h"
#import "VYBConstants.h"

@implementation VYBMyTribeStore
@synthesize s3 = _s3;

+ (VYBMyTribeStore *)sharedStore {
    static VYBMyTribeStore *sharedStore = nil;
    if (!sharedStore)
        sharedStore = [[super allocWithZone:nil] init];
    
    return sharedStore;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [self sharedStore];
}

- (id)init {
    self = [super init];
  
    if (self) {
        //[self connectToTribe];
        if (!myTribeVybes)
            myTribeVybes = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (NSArray *)myTribeVybes {
    return myTribeVybes;
}

- (void)connectToTribe {
    @try {
        NSLog(@"connecting to Tribe");
        // Initializing S3 client
        self.s3 = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
        self.s3.endpoint = [AmazonEndpoints s3Endpoint:US_WEST_2];
        NSArray *objects = [self.s3 listObjectsInBucket:@"vybes"];
        NSLog(@"there are %d objects", [objects count]);
        // Download all the vybes for this tribe
        // TODO: Download only new vybes
        for (S3ObjectSummary *obj in objects) {
            S3GetObjectRequest *gor = [[S3GetObjectRequest alloc] initWithKey:[obj key] withBucket:@"vybes"];
            gor.delegate = self;
            NSLog(@"Downloading object[%@]", [obj key]);
            [self.s3 getObject:gor];
        }
        
        
    } @catch (AmazonServiceException *exception) {
        NSLog(@"[MyTribe]AWS Error: %@", exception);
    }
}

#pragma mark AmazonServiceRequestDelegate methods

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
    NSData *received = response.body;
    NSLog(@"File received: %@", response.responseHeader);
    
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"Error occured while receiving a file");
}

@end
