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
            self.s3.endpoint = [AmazonEndpoints s3Endpoint:US_WEST_2];
        } @catch (AmazonServiceException *exception) {
            NSLog(@"[MyTribe]S3 init failed: %@", exception);
        }
        // Load saved videos from Tribe's Documents directory
        NSString *path = [self myTribeArchivePath];
        myTribeVybes = [NSKeyedUnarchiver unarchiveObjectWithFile:path];

        if (!myTribeVybes) {
            myTribeVybes = [[NSMutableArray alloc] init];
            [self syncMyTribeWithCloud];
        }
    }
    
    return self;
}

- (NSArray *)myTribeVybes {
    return myTribeVybes;
}

- (void)syncMyTribeWithCloud {
    @try {
        NSLog(@"Synching My Tribe with cloud");
        // TODO: listObjectsInBucket request should be run in background
        NSArray *objects = [self.s3 listObjectsInBucket:@"vybes"];
        NSLog(@"there are %d objects", [objects count]);
        // Download all the vybes for this tribe
        // TODO: Download only new vybes
        for (S3ObjectSummary *obj in objects) {
            S3GetObjectRequest *gor = [[S3GetObjectRequest alloc] initWithKey:[obj key] withBucket:@"vybes"];
            gor.delegate = self;
            gor.requestTag = [obj key];
            [myTribeVybes addObject:[obj key]];
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
    // Path to save in a temporary storage in document directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *videoPath = [documentsDirectory stringByAppendingPathComponent:@"Tribe"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:videoPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:videoPath withIntermediateDirectories:YES attributes:nil error:nil];
    videoPath = [videoPath stringByAppendingPathComponent:request.requestTag];
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:videoPath];
    NSData *received = [[NSData alloc] initWithData:response.body];
    [received writeToURL:outputURL atomically:YES];
    [self saveThumbnailImageForVideo:videoPath];
    
    NSLog(@"File received: %@", response.request.requestTag);
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"Error occured while receiving a file");
}

- (void)saveThumbnailImageForVideo:(NSString *)path {
    NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
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
    NSString *thumbPath = [path stringByReplacingOccurrencesOfString:@".mov" withString:@".jpeg"];
    NSURL *thumbURL = [[NSURL alloc] initFileURLWithPath:thumbPath];
    [thumbData writeToURL:thumbURL atomically:YES];
}

- (NSString *)videoPathAtIndex:(NSInteger)index {
    // Path to save in a temporary storage in document directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *videoPath = [documentsDirectory stringByAppendingPathComponent:@"Tribe"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:videoPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:videoPath withIntermediateDirectories:YES attributes:nil error:nil];
    videoPath = [videoPath stringByAppendingPathComponent:[myTribeVybes objectAtIndex:index]];
    
    return videoPath;
}

- (NSString *)thumbPathAtIndex:(NSInteger)index {
    // Path to save in a temporary storage in document directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *thumbPath = [documentsDirectory stringByAppendingPathComponent:@"Tribe"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:thumbPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:thumbPath withIntermediateDirectories:YES attributes:nil error:nil];
    thumbPath = [thumbPath stringByAppendingPathComponent:[myTribeVybes objectAtIndex:index]];
    thumbPath = [thumbPath stringByReplacingOccurrencesOfString:@".mov" withString:@".jpeg"];
    
    return thumbPath;
}

- (NSString *)myTribeArchivePath {
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    
    return [documentDirectory stringByAppendingPathComponent:@"myTribe.archive"];
}

- (BOOL)saveChanges {
    NSString *path = [self myTribeArchivePath];
    
    return [NSKeyedArchiver archiveRootObject:myTribeVybes toFile:path];
}


@end
