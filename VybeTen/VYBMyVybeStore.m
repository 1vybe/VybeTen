//
//  VYBVybeStore.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 24..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AdSupport/ASIdentifierManager.h>
#import "VYBMyVybeStore.h"
#import "VYBMyVybe.h"
#import "VYBConstants.h"
#import "VYBUtility.h"

@implementation VYBMyVybeStore

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
        // Load saved videos from Vybe's Documents directory
        NSString *path = [self myVybesArchivePath];
        myVybes = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        if (!myVybes)
            myVybes = [[NSArray alloc] init];
        uploadQueue = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)addVybe:(VYBMyVybe *)aVybe {
    NSMutableArray *newArray = [NSMutableArray arrayWithArray:myVybes];
    [newArray addObject:aVybe];
    myVybes = newArray;
}

- (void)uploadVybe:(VYBMyVybe *)aVybe {
    NSData *thumbnail = [NSData dataWithContentsOfFile:[aVybe thumbnailFilePath]];
    NSData *video = [NSData dataWithContentsOfFile:[aVybe videoFilePath]];
  
    PFFile *thumbnailFile = [PFFile fileWithData:thumbnail];
    PFFile *videoFile = [PFFile fileWithData:video];
    
    PFObject *vybe = [aVybe parseObjectVybe];

    PFACL *vybeACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [vybeACL setPublicReadAccess:YES];
    vybe.ACL = vybeACL;

    [thumbnailFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [videoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    [vybe setObject:thumbnailFile forKey:kVYBVybeThumbnailKey];
                    [vybe setObject:videoFile forKey:kVYBVybeVideoKey];
                    [VYBUtility reverseGeoCode:[vybe objectForKey:kVYBVybeGeotag] withCompletion:^(NSArray *placemarks, NSError *error) {
                        if (!error) {
                            NSString *location = [VYBUtility convertPlacemarkToLocation:placemarks[0]];
                            [vybe setObject:location forKey:kVYBVybeLocationName];
                        }
                        [vybe saveEventually];
                        [self clearLocalCacheForVybe:aVybe];
                    }];
                } else {
                    [self saveReverseGeocodeForVybe:aVybe];
                }
            }];
        } else {
            [self saveReverseGeocodeForVybe:aVybe];
        }
    }];
}

- (void)saveReverseGeocodeForVybe:(VYBMyVybe *)aVybe {
    PFObject *vybePF = [aVybe parseObjectVybe];
    
    [VYBUtility reverseGeoCode:[vybePF objectForKey:kVYBVybeGeotag] withCompletion:^(NSArray *placemarks, NSError *error) {
        if (!error) {
            NSString *location = [VYBUtility convertPlacemarkToLocation:placemarks[0]];
            [aVybe setLocationName:location];
        }
    }];
}

- (void)uploadDelayedVybe:(VYBMyVybe *)aVybe {
    [uploadQueue addObject:aVybe];
    [self removeVybe:aVybe];

    NSData *thumbnail = [NSData dataWithContentsOfFile:[aVybe thumbnailFilePath]];
    NSData *video = [NSData dataWithContentsOfFile:[aVybe videoFilePath]];
    
    PFFile *thumbnailFile = [PFFile fileWithData:thumbnail];
    PFFile *videoFile = [PFFile fileWithData:video];
    
    PFObject *vybe = [aVybe parseObjectVybe];
    
    PFACL *vybeACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [vybeACL setPublicReadAccess:YES];
    vybe.ACL = vybeACL;
    
    [thumbnailFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [videoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    [vybe setObject:thumbnailFile forKey:kVYBVybeThumbnailKey];
                    [vybe setObject:videoFile forKey:kVYBVybeVideoKey];
                    [vybe saveEventually];
                    [self clearLocalCacheForVybe:aVybe];
                    [uploadQueue removeObject:aVybe];
                    [self uploadDelayedVybes];
                } else {
                    [uploadQueue removeObject:aVybe];
                    [self addVybe:aVybe];
                }
            }];
        } else {
            [uploadQueue removeObject:aVybe];
            [self addVybe:aVybe];
        }
    }];
}


- (void)uploadDelayedVybes {
    if (myVybes.count < 1 ) {
        return;
    }
    //NSLog(@"There are %ui vybes to be uploaded", myVybes.count);
    VYBMyVybe *delayedVybe = [myVybes firstObject];
    [self uploadDelayedVybe:delayedVybe];
}


- (void)clearLocalCacheForVybe:(VYBMyVybe *)aVybe {
    NSURL *thumbnailURL = [[NSURL alloc] initFileURLWithPath:[aVybe thumbnailFilePath]];
    NSURL *videoURL = [[NSURL alloc] initFileURLWithPath:[aVybe videoFilePath]];
    
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtURL:thumbnailURL error:&error];
    if (error) {
        NSLog(@"Cached my vybe was NOT deleted");
    }
    [[NSFileManager defaultManager] removeItemAtURL:videoURL error:&error];
    if (error) {
        NSLog(@"Cached my vybe was NOT deleted");
    }
    

}

- (void)removeVybe:(VYBMyVybe *)aVybe {
    NSMutableArray *newArray = [NSMutableArray arrayWithArray:myVybes];
    [newArray removeObject:aVybe];
    myVybes = newArray;
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


@end
