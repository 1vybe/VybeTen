//
//  VYBMyTribeStore.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 8..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <AWSRuntime/AWSRuntime.h>
#import <AdSupport/ASIdentifierManager.h>
#import <AVFoundation/AVFoundation.h>
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
    NSLog(@"tribe store init");
    self = [super init];
  
    if (self) {
        adId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
        @try {
            // Initializing S3 client
            self.s3 = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
            self.s3.endpoint = [AmazonEndpoints s3Endpoint:US_EAST_1];
        } @catch (AmazonServiceException *exception) {
            NSLog(@"[MyTribe]S3 init failed: %@", exception);
        }
        // Load saved videos from Tribe's Documents directory

        NSString *path = [self myTribesArchivePath];
        myTribesVybes = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        if (!myTribesVybes)
            myTribesVybes = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSDictionary *)myTribesVybes {
    return myTribesVybes;
}


- (void)refreshTribes {
    NSLog(@"Refreshing tribe lists");
    @try {
        S3ListBucketsRequest *bucketReq = [[S3ListBucketsRequest alloc] init];
        bucketReq.requestTag=@"ListBuckets";
        bucketReq.delegate = self;
        [self.s3 listBuckets:bucketReq];
    } @catch (AmazonServiceException *exception) {
        NSLog(@"[MyTribe]AWS error: %@", exception);
    }
}

- (void)syncWithCloudForTribe:(NSString *)name {
    NSLog(@"Already existing %u vybes in %@ Tribe", [[myTribesVybes objectForKey:name] count], name);

    //[self listVybes];
    @try {
        NSLog(@"Synching with %@ Tribe", name);
        S3ListObjectsRequest *lor = [[S3ListObjectsRequest alloc] initWithName:name];
        lor.delegate = self;
        lor.requestTag = @"ListVybesToDownload";
        [self.s3 listObjects:lor];
      } @catch (AmazonServiceException *exception) {
        NSLog(@"[MyTribe]AWS Error: %@", exception);
    } @catch (NSException *exception) {
        NSLog(@"[MyTribe]Exception: %@", exception);

    } @catch (NSError *err) {
        NSLog(@"[MyTribe]Error: %@", err);
    }
}




- (void)addNewVybeWithKey:(NSString *)key forTribe:(NSString *)name{
    
    if ( [self vybeWithKey:key forTribe:name] )
        return;
    NSInteger i = 0;
    //NSLog(@"basket size: %d", [[myTribesVybes objectForKey:name] count]);
    for (; i < [[myTribesVybes objectForKey:name] count]; i++) {
        VYBVybe *tempV = [[VYBVybe alloc] init];
        [tempV setTribe:name withKey:key];
        if (![tempV isFresherThan:[[myTribesVybes objectForKey:name] objectAtIndex:i]]) {
            //NSLog(@"OLDER");
            break;
        }
    }
    
    //NSLog(@"adding a new tribe vybe at %d", i);

    VYBVybe *newVybe = [[VYBVybe alloc] init];
    [newVybe setTribe:name withKey:key];
    [newVybe setDownStatus:DOWNFRESH];
    [[myTribesVybes objectForKey:name] insertObject:newVybe atIndex:i];
    [self saveChanges];
}

/**
 * Helper Functions
 **/

- (void)listVybes {
    for (VYBVybe *v in myTribesVybes) {
        NSLog(@"tribe vybe[%d]:%@", [v downStatus], [v vybeKey]);
    }
}

#pragma mark AmazonServiceRequestDelegate methods

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
    
    if ( [request.requestTag isEqualToString:@"ListBuckets"] ) {
        S3ListBucketsResponse *buckets = (S3ListBucketsResponse *)response;
        S3ListBucketsResult *result = buckets.listBucketsResult;
        NSLog(@"There are %d Tribes", [result.buckets count]);
        for (S3Bucket *bucket in result.buckets) {
            if (![myTribesVybes objectForKey:bucket.name] && ![bucket.name isEqualToString:@"vybes"]) {
                NSLog(@"Creating %@ Tribe for the first time", bucket.name);
                [myTribesVybes setObject:[[NSMutableArray alloc] init] forKey:bucket.name];
            }
        }
    }

    else if ( [request.requestTag isEqualToString:@"ListVybesToDownload"] ) {
        S3ListObjectsResponse *listResponse = (S3ListObjectsResponse *)response;
        S3ListObjectsResult *result = listResponse.listObjectsResult;
        NSLog(@"There are %d in the server", [result.objectSummaries count]);
        if ([result.objectSummaries count] == 0)
            return;
                else {
            for (S3ObjectSummary *obj in result.objectSummaries) {
                S3GetObjectRequest *gor = [[S3GetObjectRequest alloc] initWithKey:[obj key] withBucket:result.bucketName];
                gor.delegate = self;
                gor.requestTag = [obj key];
                // add only if it's new
                [self addNewVybeWithKey:[obj key] forTribe:result.bucketName];
                if ([self downStatusForVybeWithKey:[obj key] forTribe:result.bucketName] == DOWNFRESH ) {
                    NSLog(@"new downloading");
                    [self.s3 getObject:gor];
                }
            }

        }
    }
    else {
        S3GetObjectRequest *getReq = (S3GetObjectRequest *)request;
        NSLog(@"down success for %@ Tribe", [getReq bucket]);
        VYBVybe *v = [self vybeWithKey:request.requestTag forTribe:[getReq bucket]];
        NSString *videoPath = [v videoPath];
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:videoPath];
        NSData *received = [[NSData alloc] initWithData:response.body];
        [received writeToURL:outputURL atomically:YES];
        
        [self saveThumbnailImageForVybe:v];

        [self changeDownStatusFor:request.requestTag forTribe:[getReq bucket] withStatus:DOWNLOADED];
    }
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"Error occured while receiving a file");
    S3GetObjectRequest *getReq = (S3GetObjectRequest *)request;
    [self changeDownStatusFor:request.requestTag forTribe:[getReq bucket] withStatus:DOWNFRESH];
}

- (void)saveThumbnailImageForVybe:(VYBVybe *)v {
    NSURL *url = [[NSURL alloc] initFileURLWithPath:[v videoPath]];
    // Generating and saving a thumbnail for the captured vybe
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *generate = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    // To transform the snapshot to be in the orientation the video was taken with
    [generate setAppliesPreferredTrackTransform:YES];
    NSError *err = NULL;
    CMTime time = CMTimeMake(1, 60);
    CGImageRef imgRef = [generate copyCGImageAtTime:time actualTime:NULL error:&err];
    UIImage *thumb = [[UIImage alloc] initWithCGImage:imgRef];
    NSData *thumbData = UIImageJPEGRepresentation(thumb, 1);
    NSURL *thumbURL = [[NSURL alloc] initFileURLWithPath:[v thumbnailPath]];
    [thumbData writeToURL:thumbURL atomically:YES];
}

- (NSString *)videoPathAtIndex:(NSInteger)index forTribe:(NSString *)name{
    return [[[myTribesVybes objectForKey:name] objectAtIndex:index] videoPath];
}

- (NSString *)thumbPathAtIndex:(NSInteger)index forTribe:(NSString *)name{
    return [[[myTribesVybes objectForKey:name] objectAtIndex:index] thumbnailPath];
}

- (NSString *)myTribesArchivePath {
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    
    return [documentDirectory stringByAppendingPathComponent:@"myTribes.archive"];
}

- (BOOL)saveChanges {
    NSString *path = [self myTribesArchivePath];
    return [NSKeyedArchiver archiveRootObject:myTribesVybes toFile:path];
}

- (VYBVybe *)vybeWithKey:(NSString *)key forTribe:(NSString *)name{
    for (VYBVybe *v in [myTribesVybes objectForKey:name])
        if ( [[v vybeKey] isEqualToString:key] )
            return v;
    
    return nil;
}

- (void)changeDownStatusFor:(NSString *)key forTribe:(NSString *)name withStatus:(int)status{
    for (VYBVybe *v in [myTribesVybes objectForKey:name]) {
        if ( [[v vybeKey] isEqualToString:key] ) {
            [v setDownStatus:status];
        }
    }
}

- (int)downStatusForVybeWithKey:(NSString *)key forTribe:(NSString *)name{
    for (VYBVybe *v in [myTribesVybes objectForKey:name]) {
        if ( [[v vybeKey] isEqualToString:key] ) {
            return [v downStatus];
        }
    }
    
    return -1;
}


@end
