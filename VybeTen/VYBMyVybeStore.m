//
//  VYBVybeStore.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 24..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
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

/*
- (void)saveReverseGeocodeForVybe:(VYBMyVybe *)aVybe {
    PFObject *vybePF = [aVybe parseObjectVybe];
    
    [VYBUtility reverseGeoCode:[vybePF objectForKey:kVYBVybeGeotag] withCompletion:^(NSArray *placemarks, NSError *error) {
        if (!error) {
            NSString *location = [VYBUtility convertPlacemarkToLocation:placemarks[0]];
            //[aVybe setLocationName:location];
        }
    }];
}
*/

- (void)uploadDelayedVybe:(VYBMyVybe *)aVybe {
    NSData *video = [NSData dataWithContentsOfFile:[aVybe videoFilePath]];
    
    PFFile *videoFile = [PFFile fileWithData:video];
    
    PFObject *pVybe = [aVybe parseObjectVybe];
    
    PFACL *vybeACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [vybeACL setPublicReadAccess:YES];
    pVybe.ACL = vybeACL;
    
    [videoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [pVybe setObject:videoFile forKey:kVYBVybeVideoKey];
            [self clearLocalCacheForVybe:aVybe];
            [self removeVybe:aVybe];
            [pVybe saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    [self uploadDelayedVybes];

                } else {
                    [pVybe saveEventually];
                }
            }];
        } else {
            [self addVybe:aVybe];
        }
    }];
}


- (void)uploadDelayedVybes {
    if (myVybes.count < 1) {
        return;
    }
    VYBMyVybe *delayedVybe = [myVybes firstObject];
    [self removeVybe:delayedVybe];
    [self uploadDelayedVybe:delayedVybe];
}


- (void)clearLocalCacheForVybe:(VYBMyVybe *)aVybe {
    NSURL *videoURL = [[NSURL alloc] initFileURLWithPath:[aVybe videoFilePath]];
    
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtURL:videoURL error:&error];
    if (error) {
        NSLog(@"[Store] Cached my vybe was NOT deleted");
    } else {
        NSLog(@"[Store] Cached my vybe was DELETED");
    }
}

- (void)removeVybe:(VYBMyVybe *)aVybe {
    NSMutableArray *newArray = [NSMutableArray arrayWithArray:myVybes];
    [newArray removeObject:aVybe];
    myVybes = newArray;
}

- (void)setCurrVybe:(VYBMyVybe *)aVybe {
    _currVybe = aVybe;
}

- (VYBMyVybe *)currVybe {
    return _currVybe;
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
