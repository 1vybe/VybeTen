//
//  VYBMyTribeStore.m
//
//  myTribes is an array to keep track of tribes.
//  **ASSUMPTION: Tribe names are unique.
//
//  Created by Kim Jin Su on 2014. 3. 8..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <AWSRuntime/AWSRuntime.h>
#import <AdSupport/ASIdentifierManager.h>
#import <AVFoundation/AVFoundation.h>
#import "VYBMyTribeStore.h"
#import "VYBConstants.h"
#import "VYBS3Connector.h"

@implementation VYBMyTribeStore {
    NSDateFormatter *dFormatter;
    NSTimeZone *timeZone;
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
        /* TODO: timeZone should be the timezone of the place vybe was taken */
        timeZone = [NSTimeZone timeZoneWithAbbreviation:@"EST"];
        [dFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss:SSS"];
        [dFormatter setTimeZone:timeZone];

        @try {
            // Initializing S3 client
            self.s3 = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
            self.s3.endpoint = [AmazonEndpoints s3Endpoint:US_EAST_1];
        } @catch (AmazonServiceException *exception) {
            NSLog(@"[MyTribe]S3 init failed: %@", exception);
        }
        // Load saved videos from Tribe's Documents directory

        NSString *myTribesPath = [self myTribesArchivePath];
        myTribes = [NSKeyedUnarchiver unarchiveObjectWithFile:myTribesPath];
        NSString *trendingPath = [self trendingTribesArchivePath];
        trendingTribes = [NSKeyedUnarchiver unarchiveObjectWithFile:trendingPath];
        
        if (!myTribes)
            myTribes = [[NSMutableArray alloc] init];
        if (!trendingTribes)
            trendingTribes = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSArray *)myTribes {
    return myTribes;
}

- (NSMutableArray *)featuredTribes {
    NSMutableArray *featured = [[NSMutableArray alloc] init];
    
    return featured;
}

- (void)setMyTribes:(NSMutableArray *)tribes {
    myTribes = tribes;
}


- (BOOL)addNewTribe:(NSString *)tribeName {
    @try {
        S3CreateBucketRequest *request = [[S3CreateBucketRequest alloc] initWithName:tribeName];
        [self.s3 createBucket:request];
        NSLog(@"A new tribe added");
        VYBTribe *newTribe = [[VYBTribe alloc] initWithTribeName:tribeName];
        [myTribes addObject:newTribe];
    } @catch (AmazonServiceException *exception){
        NSLog(@"[MyTribe addNewTribe] Amazon Service Error: %@", exception);
        return NO;
    } @catch (AmazonClientException *exception) {
        NSLog(@"[MyTribe addNewTribe] Amazon Client Error: %@", exception);
        return NO;
    }
    return YES;
}

- (void)refreshTribesWithCompletion:(void (^)(NSError *err))block {
    NSLog(@"Async Refreshing Tribes");
    S3ListBucketsRequest *bucketReq = [[S3ListBucketsRequest alloc] init];
    VYBS3Connector *s3connector = [[VYBS3Connector alloc] initWithClient:self.s3 completionBlock:block];
    [s3connector setCompletionBlock:block];
    [s3connector startTribeListRequest:bucketReq];
}

- (void)syncWithCloudForTribe:(NSString *)name withCompletionBlock:(void (^)(NSError *err))block {
    //NSLog(@"Already existing %u vybes in %@ Tribe", [[myTribesVybes objectForKey:name] count], name);
    NSLog(@"Synching with %@ Tribe", name);
    // Tribe name is bucket name is S3
    S3ListObjectsRequest *lor = [[S3ListObjectsRequest alloc] initWithName:name];
    VYBS3Connector *connector = [[VYBS3Connector alloc] initWithClient:self.s3 completionBlock:block];
    [connector startTribeVybesRequest:lor];
}


- (BOOL)hasTribe:(NSString *)trname {
    for (VYBTribe *t in myTribes) {
        if ( [[t tribeName] isEqualToString:trname] )
            return YES;
    }
    return NO;
}

- (VYBTribe *)tribe:(NSString *)name {
    for (VYBTribe *t in myTribes) {
        if ( [[t tribeName] isEqualToString:name] )
            return t;
    }
    return nil;
}

/*
- (void)addNewVybeWithKey:(NSString *)key forTribe:(NSString *)name{
    VYBTribe *newT = [self tribe:name];
    if ( [self vybeWithKey:key forTribe:name] )
        return;
    NSInteger i = 0;
    VYBVybe *newVybe = [[VYBVybe alloc] init];
    NSDate *dateObj = [self extractDateFrom:key];
    [newVybe setTimeStamp:dateObj];
    
    for (; i < [[newT vybes] count]; i++) {
        if ([newVybe isFresherThan:[[newT vybes] objectAtIndex:i]]) {
            break;
        }
    }
    
    //NSLog(@"adding a new tribe vybe at %d:%@", i, key);

    [newVybe setTribeName:name];
    [newVybe setVybeKey:key];
    [newVybe setTribeVybePathWith:name];
    //[newVybe setDeviceId:[self extractDeviceIdFrom:key]];
    [newVybe setDownStatus:DOWNFRESH];
    [[myTribesVybes objectForKey:name] insertObject:newVybe atIndex:i];
    //[self saveChanges];
}
 */

/**
 * Helper Functions
 **/

- (NSDateFormatter *)presetDateFormatter {
    return dFormatter;
}

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
    for (VYBVybe *v in myTribes) {
        NSLog(@"tribe vybe[%d]:%@", [v downStatus], [v vybeKey]);
    }
}

#pragma mark AmazonServiceRequestDelegate methods

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
    S3GetObjectRequest *getReq = (S3GetObjectRequest *)request;
    NSLog(@"[%@]DOWN SUCCESS", [getReq bucket]);
    VYBTribe *tribe = [self tribe:[getReq bucket]];
    VYBVybe *v = [tribe vybeWithKey:request.requestTag];
    NSString *videoPath = [v tribeVideoPath];
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:videoPath];
    NSData *videoReceived = [[NSData alloc] initWithData:response.body];
    [videoReceived writeToURL:outputURL atomically:YES];
    
    //[tribe changeDownStatusFor:request.requestTag withStatus:DOWNLOADED];
    [v setDownStatus:DOWNLOADED];
    [self saveThumbnailImageForVybe:v];
    
    [self downloadTribeVybesFor:tribe];
    
    videoReceived = nil;
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"Error occured while receiving a file");
    S3GetObjectRequest *getReq = (S3GetObjectRequest *)request;
    VYBTribe *tribe = [self tribe:[getReq bucket]];
    [tribe changeDownStatusFor:request.requestTag withStatus:DOWNFRESH];
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
    NSData *thumbData = UIImageJPEGRepresentation(thumb, 0.3);
    NSURL *thumbURL = [[NSURL alloc] initFileURLWithPath:[v tribeThumbnailPath]];
    [thumbData writeToURL:thumbURL atomically:YES];
}

- (NSString *)videoPathAtIndex:(NSInteger)index forTribe:(NSString *)name{
    VYBTribe *tribe = [self tribe:name];
    VYBVybe *vybe = [[tribe vybes] objectAtIndex:index];
    return [vybe tribeVideoPath];
}

- (NSString *)thumbPathAtIndex:(NSInteger)index forTribe:(NSString *)name{
    VYBTribe *tribe = [self tribe:name];
    VYBVybe *vybe = [[tribe vybes] objectAtIndex:index];
    return [vybe tribeThumbnailPath];
}

- (NSString *)thumbPathAtIndex:(NSInteger)index forTribe:(NSString *)name alreadyDownloaded:(BOOL)down{
    VYBTribe *tribe = [self tribe:name];
    NSInteger cnt = 0;
    for (NSInteger i = [[tribe vybes] count] - 1; i >= 0; i--) {
        VYBVybe *v = [[tribe vybes] objectAtIndex:i];
        if ([v downStatus] == DOWNLOADED) {
            if (cnt == index)
                return [v tribeThumbnailPath];
            else
                cnt++;
        }
    }
    return nil;
}

- (void)downloadFeaturedWithCompletion:(void (^) (NSError *err))block {
    NSLog(@"Synching for FEATURED");
    // Tribe name is bucket name is S3
    S3ListObjectsRequest *featuredReq = [[S3ListObjectsRequest alloc] initWithName:@"vybes-featured"];
    VYBS3Connector *connector = [[VYBS3Connector alloc] initWithClient:self.s3 completionBlock:block];
    [connector startFeaturedRequest:featuredReq];
    

}

- (void)downloadTrendingWithCompletion:(void (^) (NSError *err))block {
    NSLog(@"Synching for TRENDING");
    S3ListObjectsRequest *trendingReq = [[S3ListObjectsRequest alloc] initWithName:@"vybes-trending"];
    VYBS3Connector *connector = [[VYBS3Connector alloc] initWithClient:self.s3 completionBlock:block];
    [connector startTrendingRequest:trendingReq];
    
}


/*
- (NSArray *)tribes {
    NSArray *tribes = [myTribesVybes allKeys];
    tribes = [tribes sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    return tribes;
}
*/

- (NSString *)myTribesArchivePath {
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    
    return [documentDirectory stringByAppendingPathComponent:@"myTribes.archive"];
}

- (NSString *)featuredTribesArchivePath {
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    
    return [documentDirectory stringByAppendingPathComponent:@"featuredTribes.archive"];
}

- (NSString *)trendingTribesArchivePath {
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    
    return [documentDirectory stringByAppendingPathComponent:@"trendingTribes.archive"];
}

- (BOOL)saveChanges {
    //NSLog(@"Tribe Store saving");
    NSString *myTribesPath = [self myTribesArchivePath];
    NSString *tTribesPath = [self trendingTribesArchivePath];

    return [NSKeyedArchiver archiveRootObject:myTribes toFile:myTribesPath] && [NSKeyedArchiver archiveRootObject:trendingTribes toFile:tTribesPath];
}



- (void)downloadTribeVybesFor:(VYBTribe *)tribe {
    if ([tribe hasDownloadingVybe]) {
        NSLog(@"already downloading something for this tribe");
        return;
    }
    //VYBVybe *v = [self mostRecentVybeToBeDownloadedFor:tribeName];
    VYBVybe *v = [tribe oldestVybeToBeDownloaded];
    
    if (!v) {
        NSLog(@"nothing to be downloaded");
        return;
    }
    S3GetObjectRequest *gor = [[S3GetObjectRequest alloc] initWithKey:[v vybeKey] withBucket:[tribe tribeName]];
    gor.delegate = self;
    gor.requestTag = [v vybeKey];
    [v setDownStatus:DOWNLOADING];
    [self.s3 getObject:gor];
    NSLog(@"[%@]DOWN BEGIN", [tribe tribeName]);
}

/*
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
*/

@end
