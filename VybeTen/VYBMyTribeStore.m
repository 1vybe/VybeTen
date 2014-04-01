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

@implementation VYBMyTribeStore {
    NSDateFormatter *dFormatter;
    NSTimeZone *gmt;

}
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
    //NSLog(@"tribe store init");
    self = [super init];
  
    if (self) {
        adId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
        /* Caching NSDateFormatter object for performance issue. Allocating and initializing this object is very costly */
        dFormatter = [[NSDateFormatter alloc] init];
        gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        [dFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss:SSS"];
        [dFormatter setTimeZone:gmt];

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


- (BOOL)addNewTribe:(NSString *)tribeName {
    @try {
        S3CreateBucketRequest *request = [[S3CreateBucketRequest alloc] initWithName:tribeName];
        [self.s3 createBucket:request];
        NSLog(@"A new tribe added");
        [myTribesVybes setObject:[[NSMutableArray alloc] init] forKey:tribeName];
    } @catch (AmazonServiceException *exception){
        NSLog(@"[MyTribe addNewTribe] Amazon Service Error: %@", exception);
        return NO;
    } @catch (AmazonClientException *exception) {
        NSLog(@"[MyTribe addNewTribe] Amazon Client Error: %@", exception);
        return NO;
    }
    return YES;
}

- (BOOL)refreshTribes {
    NSLog(@"Refreshing tribe lists");
    @try {
        S3ListBucketsRequest *bucketReq = [[S3ListBucketsRequest alloc] init];
        S3ListBucketsResponse *buckets = [self.s3 listBuckets:bucketReq];
        S3ListBucketsResult *result = buckets.listBucketsResult;
        NSLog(@"There are %d tribes in the server", [result.buckets count]);
        NSMutableDictionary *newDictionary = [[NSMutableDictionary alloc] init];
        for (S3Bucket *bucket in result.buckets) {
            /* Here we are manually exlcuding some buckets on testing purpose */
            if ([bucket.name isEqualToString:@"vybes"] || [bucket.name isEqualToString:@"NUNS-ISLAND"] || [bucket.name isEqualToString:@"CERCLE"] || [bucket.name isEqualToString:@"RUSSIAN"]) {
            }
            else {
                // If there already exists a tribe, copy its vybes into new
                if ( [myTribesVybes objectForKey:bucket.name] ) {
                    [newDictionary setObject:[myTribesVybes objectForKey:bucket.name] forKey:bucket.name];
                } else {
                    [newDictionary setObject:[[NSMutableArray alloc] init] forKey:bucket.name];
                }
            }
        }
        myTribesVybes = nil;
        myTribesVybes = newDictionary;
    } @catch (AmazonServiceException *exception) {
        NSLog(@"[MyTribe]AWS error: %@", exception);
        return NO;
    }
    return YES;
}

- (BOOL)syncWithCloudForTribe:(NSString *)name {
    NSLog(@"Already existing %u vybes in %@ Tribe", [[myTribesVybes objectForKey:name] count], name);
    @try {
        NSLog(@"Synching with %@ Tribe", name);
        // Tribe name is bucket name is S3
        S3ListObjectsRequest *lor = [[S3ListObjectsRequest alloc] initWithName:name];
        S3ListObjectsResponse *listResponse = [self.s3 listObjects:lor];;
        S3ListObjectsResult *result = listResponse.listObjectsResult;
        NSString *buckName = result.bucketName;
        NSLog(@"Server has %d videos for %@ Tribe", [result.objectSummaries count], name);
        if ([result.objectSummaries count] == 0)
            return YES;
        else {
            NSLog(@"adding begins");
            for (S3ObjectSummary *obj in result.objectSummaries) {
                // will be added ONLY if new
                [self addNewVybeWithKey:[obj key] forTribe:buckName];
            }
            NSLog(@"adding done");
            [self downloadTribeVybesFor:buckName];
            return YES;
        }
      } @catch (AmazonServiceException *exception) {
          NSLog(@"[MyTribe]AWS Error: %@", exception);
          return NO;
    } @catch (NSException *exception) {
        NSLog(@"[MyTribe]Exception: %@", exception);
        return NO;
    } @catch (NSError *err) {
        NSLog(@"[MyTribe]Error: %@", err);
        return NO;
    }
    return YES;
}



- (void)addNewVybeWithKey:(NSString *)key forTribe:(NSString *)name{
    if ( [self vybeWithKey:key forTribe:name] )
        return;
    NSInteger i = 0;
    VYBVybe *newVybe = [[VYBVybe alloc] init];
    NSDate *dateObj = [self extractDateFrom:key];
    [newVybe setTimeStamp:dateObj];
    
    for (; i < [[myTribesVybes objectForKey:name] count]; i++) {
        if ([newVybe isFresherThan:[[myTribesVybes objectForKey:name] objectAtIndex:i]]) {
            break;
        }
    }
    
    //NSLog(@"adding a new tribe vybe at %d:%@", i, key);

    [newVybe setTribeName:name];
    [newVybe setVybeKey:key];
    [newVybe setTribeVybePathWith:name];
    [newVybe setDeviceId:[self extractDeviceIdFrom:key]];
    [newVybe setDownStatus:DOWNFRESH];
    [[myTribesVybes objectForKey:name] insertObject:newVybe atIndex:i];
    //[self saveChanges];
}

/**
 * Helper Functions
 **/

- (NSString *)extractDeviceIdFrom:(NSString *)str {
    NSCharacterSet *delimiters = [NSCharacterSet characterSetWithCharactersInString:@"[]"];
    NSArray *strings = [str componentsSeparatedByCharactersInSet:delimiters];
    // Extracts and saves deviceId information
    return [strings objectAtIndex:1];
    // Extracts and saves date information
}

/* Returns a date object from the key string */
- (NSDate *)extractDateFrom:(NSString *)str {
    //NSLog(@"encoding string: %@", str);
    NSCharacterSet *delimiters = [NSCharacterSet characterSetWithCharactersInString:@"[]"];
    NSArray *strings = [str componentsSeparatedByCharactersInSet:delimiters];
    // Extracts date information
    NSString *dateString = [strings objectAtIndex:2];
    NSDate *date = [dFormatter dateFromString:dateString];
    //NSLog(@"after encoding: %@", date);
    return date;
}


- (void)listVybes {
    for (VYBVybe *v in myTribesVybes) {
        NSLog(@"tribe vybe[%d]:%@", [v downStatus], [v vybeKey]);
    }
}

#pragma mark AmazonServiceRequestDelegate methods

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
    S3GetObjectRequest *getReq = (S3GetObjectRequest *)request;
    NSLog(@"[%@]DOWN SUCCESS", [getReq bucket]);
    VYBVybe *v = [self vybeWithKey:request.requestTag forTribe:[getReq bucket]];
    NSString *videoPath = [v tribeVideoPath];
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:videoPath];
    NSData *videoReceived = [[NSData alloc] initWithData:response.body];
    [videoReceived writeToURL:outputURL atomically:YES];
    
    [self saveThumbnailImageForVybe:v];

    [self changeDownStatusFor:request.requestTag forTribe:[getReq bucket] withStatus:DOWNLOADED];
    
    [self downloadTribeVybesFor:[getReq bucket]];
    
    videoReceived = nil;
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"Error occured while receiving a file");
    S3GetObjectRequest *getReq = (S3GetObjectRequest *)request;
    [self changeDownStatusFor:request.requestTag forTribe:[getReq bucket] withStatus:DOWNFRESH];
}

- (void)saveThumbnailImageForVybe:(VYBVybe *)v {
    NSURL *url = [[NSURL alloc] initFileURLWithPath:[v tribeVideoPath]];
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
    NSURL *thumbURL = [[NSURL alloc] initFileURLWithPath:[v tribeThumbnailPath]];
    [thumbData writeToURL:thumbURL atomically:YES];
}

- (NSString *)videoPathAtIndex:(NSInteger)index forTribe:(NSString *)name{
    return [[[myTribesVybes objectForKey:name] objectAtIndex:index] tribeVideoPath];
}

- (NSString *)thumbPathAtIndex:(NSInteger)index forTribe:(NSString *)name{
    return [[[myTribesVybes objectForKey:name] objectAtIndex:index] tribeThumbnailPath];
}

- (NSArray *)tribes {
    NSArray *tribes = [myTribesVybes allKeys];
    tribes = [tribes sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    return tribes;
}


- (NSString *)myTribesArchivePath {
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    
    return [documentDirectory stringByAppendingPathComponent:@"myTribes.archive"];
}

- (BOOL)saveChanges {
    //NSLog(@"Tribe Store saving");
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

- (void)downloadTribeVybesFor:(NSString *)tribeName {
    if ([self hasDownloadingVybeAlreadyFor:tribeName]) {
        NSLog(@"already downloading something for this tribe");
        return;
    }
    VYBVybe *v = [self mostRecentVybeToBeDownloadedFor:tribeName];
    if (!v) {
        NSLog(@"nothing to be downloaded");
        return;
    }
    S3GetObjectRequest *gor = [[S3GetObjectRequest alloc] initWithKey:[v vybeKey] withBucket:tribeName];
    gor.delegate = self;
    gor.requestTag = [v vybeKey];
    [v setDownStatus:DOWNLOADING];
    [self.s3 getObject:gor];
    NSLog(@"[%@]DOWN BEGIN", tribeName);
}

- (BOOL)hasDownloadingVybeAlreadyFor:(NSString *)tribeName {
    for (VYBVybe *v in [myTribesVybes objectForKey:tribeName]) {
        if ([v downStatus] == DOWNLOADING)
            return YES;
    }
    return NO;
}

- (VYBVybe *)mostRecentVybeToBeDownloadedFor:(NSString *)tribeName {
    for (VYBVybe *v in [myTribesVybes objectForKey:tribeName]) {
        if ([v downStatus] == DOWNFRESH)
            return v;
    }
    return nil;
}


- (BOOL)clear {
    NSLog(@"Tribe Store cache clearing");
    NSError *error;
    for (NSString *tribeName in [myTribesVybes allKeys]) {
        for (VYBVybe *v in [myTribesVybes objectForKey:tribeName]) {
            // Delete the video file from local storage
            NSURL *vidURL = [[NSURL alloc] initFileURLWithPath:[v tribeVideoPath]];
            [[NSFileManager defaultManager] removeItemAtURL:vidURL error:&error];
            if (error) {
                NSLog(@"[clear] Removing a video failed: %@", error);
            } else {
                NSLog(@"[clear] Removing a video success: %@", error);
            }
            // Delete the image file from local storage
            NSURL *thumbURL = [[NSURL alloc] initFileURLWithPath:[v tribeThumbnailPath]];
            [[NSFileManager defaultManager] removeItemAtURL:thumbURL error:&error];
            if (error) {
                NSLog(@"[clear] Removing a thumbnail image failed: %@", error);
            }
        }
    }
    myTribesVybes = nil;
    [self saveChanges];
    return YES;
}

- (void)analyzeTribe:(NSString *)tribe {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    for (VYBVybe *v in [myTribesVybes objectForKey:tribe]) {
        NSString *deviceId = [v deviceId];
        if ( [dictionary objectForKey:deviceId] ) {
            NSMutableArray *array = [dictionary objectForKey:deviceId];
            [array addObject:[v vybeKey]];
        } else {
            NSMutableArray *array = [[NSMutableArray alloc] init];
            [dictionary setObject:array forKey:deviceId];
        }
    }
    NSInteger numVybes = 0;
    for (NSString *deviceId in [dictionary allKeys]) {
        NSInteger temp = [[dictionary objectForKey:deviceId] count];
        NSLog(@"User[%@] took %d vybes", deviceId, temp);
        numVybes = numVybes + temp;
    }
    NSLog(@"There are %d vybes.", numVybes);
    NSLog(@"There are %d people who vybed.", [[dictionary allKeys] count]);
    
}


@end
