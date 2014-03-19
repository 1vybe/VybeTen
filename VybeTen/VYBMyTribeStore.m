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
            myTribesVybes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSArray *)myTribesVybes {
    return myTribesVybes;
}

- (void)syncMyTribesWithCloud {
    NSLog(@"Already existing %u in myTribesVybes", [myTribesVybes count]);

    //[self listVybes];
    @try {
        NSLog(@"Synching My Tribe with cloud");
        S3ListObjectsRequest *lor = [[S3ListObjectsRequest alloc] initWithName:BUCKET_NAME];
        lor.delegate = self;
        lor.requestTag = @"listObjects";
        [self.s3 listObjects:lor];
      } @catch (AmazonServiceException *exception) {
        NSLog(@"[MyTribe]AWS Error: %@", exception);
    } @catch (NSException *exception) {
        NSLog(@"[MyTribe]Exception: %@", exception);

    } @catch (NSError *err) {
        NSLog(@"[MyTribe]Error: %@", err);
    }
}


- (void)addNewVybeWithKey:(NSString *)key {
    if ( [self vybeWithKey:key] )
        return;
    NSInteger i = 0;
    NSLog(@"basket size: %d", [myTribesVybes count]);
    for (; i < [myTribesVybes count]; i++) {
        VYBVybe *tempV = [[VYBVybe alloc] init];
        [tempV setTribeVybeKey:key];
        if (![tempV isFresherThan:[myTribesVybes objectAtIndex:i]]) {
            NSLog(@"OLDER");
            break;
        }
    }
    
    NSLog(@"adding a new tribe vybe at %d", i);

    VYBVybe *newVybe = [[VYBVybe alloc] init];
    [newVybe setTribeVybeKey:key];
    [newVybe setDownStatus:DOWNFRESH];
    [myTribesVybes insertObject:newVybe atIndex:i];
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

    if ( [request.requestTag isEqualToString:@"listObjects"] ) {
        NSLog(@"listing!!!!!!");
        S3ListObjectsResponse *listResponse = (S3ListObjectsResponse *)response;
        S3ListObjectsResult *result = listResponse.listObjectsResult;
        NSLog(@"There are %d in the server", [result.objectSummaries count]);
        if ([result.objectSummaries count] == 0)
            return;
                else {
            for (S3ObjectSummary *obj in result.objectSummaries) {
                S3GetObjectRequest *gor = [[S3GetObjectRequest alloc] initWithKey:[obj key] withBucket:BUCKET_NAME];
                gor.delegate = self;
                gor.requestTag = [obj key];
                // add only if it's new
                [self addNewVybeWithKey:[obj key]];
                if ([self downStatusForVybeWithKey:[obj key]] == DOWNFRESH ) {
                    NSLog(@"new downloading");
                    [self.s3 getObject:gor];
                }
            }

        }
    }
    else {
        NSLog(@"down success");
        VYBVybe *v = [self vybeWithKey:request.requestTag];
        NSString *videoPath = [v videoPath];
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:videoPath];
        NSData *received = [[NSData alloc] initWithData:response.body];
        [received writeToURL:outputURL atomically:YES];
        
        [self saveThumbnailImageForVybe:v];

        [self changeDownStatusFor:request.requestTag withStatus:DOWNLOADED];
    }
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"Error occured while receiving a file");
    [self changeDownStatusFor:request.requestTag withStatus:DOWNFRESH];
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

- (NSString *)videoPathAtIndex:(NSInteger)index {
    return [[myTribesVybes objectAtIndex:index] videoPath];
}

- (NSString *)thumbPathAtIndex:(NSInteger)index {
    return [[myTribesVybes objectAtIndex:index] thumbnailPath];
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

- (VYBVybe *)vybeWithKey:(NSString *)key {
    for (VYBVybe *v in myTribesVybes)
        if ( [[v vybeKey] isEqualToString:key] )
            return v;
    
    return nil;
}

- (void)changeDownStatusFor:(NSString *)key withStatus:(int)status{
    for (VYBVybe *v in myTribesVybes) {
        if ( [[v vybeKey] isEqualToString:key] ) {
            [v setDownStatus:status];
        }
    }
}

- (int)downStatusForVybeWithKey:(NSString *)key {
    for (VYBVybe *v in myTribesVybes) {
        if ( [[v vybeKey] isEqualToString:key] ) {
            return [v downStatus];
        }
    }
    
    return -1;
}


@end
