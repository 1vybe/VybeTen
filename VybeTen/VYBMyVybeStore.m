//
//  VYBVybeStore.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 24..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <AWSRuntime/AWSRuntime.h>
#import <AVFoundation/AVFoundation.h>
#import <AdSupport/ASIdentifierManager.h>
#import "VYBMyVybeStore.h"
#import "VYBVybe.h"
#import "VYBConstants.h"

@implementation VYBMyVybeStore
@synthesize s3 = _s3;

+ (VYBMyVybeStore *)sharedStore {
    static VYBMyVybeStore *sharedStore = nil;
    if (!sharedStore) {
        sharedStore = [[super allocWithZone:nil] init];
    }
    
    return sharedStore;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [self sharedStore];
}

- (id)init {
    self = [super init];
    if (self) {
        // Retrieves this device's unique ID
        adId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
        // Load saved videos from Vybe's Documents directory
        NSString *path = [self myVybesArchivePath];
        myVybes = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        if (!myVybes)
            myVybes = [[NSMutableArray alloc] init];
        // Initialize S3 client
        @try {
            self.s3 = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
            self.s3.endpoint = [AmazonEndpoints s3Endpoint:US_EAST_1];
        } @catch (AmazonServiceException *exception) {
            NSLog(@"[MyVybe]S3 init failed: %@", exception);
        }
    }
    
    return self;
}

- (NSArray *)myVybes {
    return myVybes;
}

- (void)addVybe:(VYBVybe *)v {
    [myVybes addObject:v];
    NSLog(@"added a new vybe");

    @try {
        // Save the thumbnail image for the captured video on local Documents directory
        [self saveThumbnailImageFor:v];
        
        // Upload the saved video to S3
        [self processDelegateUploadForVybe:v];
    
        // Update myVybes
        [self saveChanges];
    }@catch (NSError *err) {
        NSLog(@"Error occured while adding a vybe:%@", err);
    }
}

- (BOOL)removeVybe:(VYBVybe *)v {
    NSError *error;
    NSLog(@"Removing vybe from %@: %@", [v tribeName], [v vybeKey]);
    // First delete it from S3
    @try {
        S3DeleteObjectResponse *response = [self.s3 deleteObjectWithKey:[v vybeKey] withBucket:[v tribeName]];
        if ([response hasClockSkewError]) {
            response = [self.s3 deleteObjectWithKey:[v vybeKey] withBucket:[v tribeName]];
            if ([response hasClockSkewError]) {
                NSLog(@"[removeVybe] ClockSkewError");
                return NO;
            }
        }
        NSLog(@"removed from S3:%@", response.headers);
    } @catch (AmazonServiceException *exception) {
        NSLog(@"[removeVybe]: S3 exception %@", exception);
        // If the bucket is already erased, it will go on and erase from your phone too
        if (![exception.errorCode isEqualToString:@"NoSuchBucket"])
            return NO;
    }
    // Delete the video file from local storage
    NSURL *vidURL = [[NSURL alloc] initFileURLWithPath:[v videoPath]];
    [[NSFileManager defaultManager] removeItemAtURL:vidURL error:&error];
    if (error) {
        NSLog(@"[removeVybe] Removing a video failed");
        NSLog(@"%@", vidURL);
        NSLog(@"%@", [v videoPath]);
    }
    else {
        NSLog(@"[removeVybe] Removing a video success");
        NSLog(@"%@", vidURL);
        NSLog(@"%@", [v videoPath]);
    }
    // Delete the image file from local storage
    NSURL *thumbURL = [[NSURL alloc] initFileURLWithPath:[v thumbnailPath]];
    [[NSFileManager defaultManager] removeItemAtURL:thumbURL error:&error];
    if (error)
        NSLog(@"[removeVybe] Removing a thumbnail image failed: %@", error);
    // Delete from myVybes
    for (VYBVybe *vy in myVybes) {
        if ([vy vybeKey] == [v vybeKey]) {
            [myVybes removeObject:vy];
            break;
        }
    }
    NSLog(@"after removal myVybes has %d", [myVybes count]);
    return YES;
}

- (NSString *)myVybesArchivePath {
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    
    return [documentDirectory stringByAppendingPathComponent:@"myVybes.archive"];
}

- (BOOL)saveChanges {
    NSString *path = [self myVybesArchivePath];
    return [NSKeyedArchiver archiveRootObject:myVybes toFile:path];
}

- (void)listVybes {
    for (VYBVybe *v in myVybes) {
        NSLog(@"Vybe[%d]:%@", [v upStatus], [v videoPath]);
    }
}

- (void)saveThumbnailImageFor:(VYBVybe *)v {
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
    NSData *thumbData = UIImageJPEGRepresentation(thumb, 0.3);
    NSURL *thumbURL = [[NSURL alloc] initFileURLWithPath:[v thumbnailPath]];
    [thumbData writeToURL:thumbURL atomically:YES];
}

/**
 * Functions related to uploading to AWS S3
 **/
- (void)processDelegateUploadForVybe:(VYBVybe *)v {
    NSURL *videoURL = [[NSURL alloc] initFileURLWithPath:[v videoPath]];
    NSData *videoData = [NSData dataWithContentsOfURL:videoURL];
    //NSString *keyString = [NSString stringWithFormat:@"%@/%@.mov", adId, [v timeStamp]];
    /*
    if (![v vybeKey]) {
        NSLog(@"fixing vybeKey");
        NSCharacterSet *delimiters = [NSCharacterSet characterSetWithCharactersInString:@"["];
        NSString *vykey = @"[";
        NSString *vidPath = [[[v videoPath] componentsSeparatedByCharactersInSet:delimiters] objectAtIndex:1];
        vykey = [vykey stringByAppendingString:vidPath];
        [v setVybeKey:vykey];
    }
    */
    NSString *keyString = [v vybeKey];

    S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:keyString inBucket:[v tribeName] ];

    por.contentType = @"video/quicktime";
    por.data = videoData;
    por.delegate = self;
    por.requestTag = keyString;

    @try {
        [self.s3 putObject:por];
        [v setUpStatus:UPLOADING];
        NSLog(@"UPLOAD STARTED for %@ Tribe: %@", [v tribeName], [v vybeKey]);
    }@catch (AmazonServiceException *exception) {
        NSLog(@"Upload Failed: %@", exception);
    }
}

- (void)delayedUploadsBegin {
    if ([self hasUploadingVybeAlready]) {
        return;
    }
    VYBVybe *v = [self mostRecentVybeToBeUploaded];
    if (!v)
        return;

    [self processDelegateUploadForVybe:v];
}

- (void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response {
    S3GetObjectRequest *getReq = (S3GetObjectRequest *)request;
    NSLog(@"UPLOAD SUCCESS for %@ Tribe: %@", [getReq bucket], request.requestTag);

    //[self listVybes];
    [self changeUpStatusFor:request.requestTag withStatus:UPLOADED];
    
    [self delayedUploadsBegin];
    // Start next
    /* TODO: Saving changes to myVybesStore's status is redundant */
    //[self saveChanges];
    //[self listVybes];

}

- (void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error {
    S3GetObjectRequest *getReq = (S3GetObjectRequest *)request;
    NSLog(@"UPLOAD FAILED for %@ Tribe: %@", [getReq bucket], request.requestTag);
    [self changeUpStatusFor:request.requestTag withStatus:UPFRESH];

}

- (void)changeUpStatusFor:(NSString *)key withStatus:(int)status{
    for (VYBVybe *v in myVybes) {
        if ( [[v vybeKey] isEqualToString:key] ) {
            [v setUpStatus:status];
        }
    }
}

- (BOOL)hasUploadingVybeAlready{
    for (VYBVybe *v in myVybes) {
        if ([v upStatus] == UPLOADING)
            return YES;
    }
    return NO;
}

- (VYBVybe *)mostRecentVybeToBeUploaded {
    for (VYBVybe *v in myVybes) {
        if ([v upStatus] == UPFRESH)
            return v;
    }
    return nil;
}



@end
