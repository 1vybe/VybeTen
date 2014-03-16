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
        NSLog(@"This device's unique ID: %@", adId);
        // Load saved videos from Vybe's Documents directory
        NSString *path = [self myVybesArchivePath];
        myVybes = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        if (!myVybes)
            myVybes = [[NSMutableArray alloc] init];
        [self listVybes];
        // Initialize S3 client
        @try {
            self.s3 = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
            self.s3.endpoint = [AmazonEndpoints s3Endpoint:US_WEST_2];
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
    NSLog(@"adding a new vybe");
    [myVybes addObject:v];

    // Save the thumbnail image for the captured video on local Documents directory
    [self saveThumbnailImageFor:v];
    
    // Upload the saved video to S3
    [self processDelegateUploadForVybe:v];
    
    // Update myVybes
    [self saveChanges];
}

- (void)removeVybe:(VYBVybe *)v {
    [myVybes removeObjectIdenticalTo:v];
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
    NSData *thumbData = UIImageJPEGRepresentation(thumb, 1);
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
    if (![v vybeKey]) {
        NSLog(@"fixing vybeKey");
        NSCharacterSet *delimiters = [NSCharacterSet characterSetWithCharactersInString:@"["];
        NSString *vykey = @"[";
        NSString *vidPath = [[[v videoPath] componentsSeparatedByCharactersInSet:delimiters] objectAtIndex:1];
        vykey = [vykey stringByAppendingString:vidPath];
        [v setVybeKey:vykey];
    }

    NSString *keyString = [v vybeKey];

    S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:keyString inBucket:@"vybes"];

    por.contentType = @"video/quicktime";
    por.data = videoData;
    por.delegate = self;
    por.requestTag = keyString;
    @try {
        [self.s3 putObject:por];
        [v setUpStatus:UPLOADING];
    }@catch (AmazonServiceException *exception) {
        NSLog(@"Upload Failed: %@", exception);
    }
    NSLog(@"uploading started for: %@", keyString);
}

- (void)delayedUploadsBegin {
    NSLog(@"delayedUploadedBegin");
    for (VYBVybe *v in myVybes) {
        if ([v upStatus] == UPFRESH) {
            NSLog(@"let's try uploading again for %@", [v vybeKey]);
            [self processDelegateUploadForVybe:v];
        }
    }
}

- (void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response {
    NSLog(@"UPLOAD SUCCESS for: %@", request.requestTag);
    //[self listVybes];
    [self changeUpStatusFor:request.requestTag withStatus:UPLOADED];
    /* TODO: Saving changes to myVybesStore's status is redundant */
    //[self saveChanges];
    //[self listVybes];

}

- (void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"UPLOAD FAILED for: %@", request.requestTag);

    [self changeUpStatusFor:request.requestTag withStatus:UPFRESH];

}

- (void)changeUpStatusFor:(NSString *)key withStatus:(int)status{
    for (VYBVybe *v in myVybes) {
        if ( [[v vybeKey] isEqualToString:key] ) {
            [v setUpStatus:status];
        }
    }
}



@end
