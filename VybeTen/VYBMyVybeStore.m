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
    }
    
    return self;
}

- (void)addVybe:(VYBMyVybe *)aVybe {
    NSMutableArray *newArray = [NSMutableArray arrayWithArray:myVybes];
    [newArray addObject:aVybe];
    myVybes = newArray;
}

/*
- (NSString *)videoPathWithKey:(NSString *)aKey {
    return [aKey stringByAppendingPathExtension:@"mov"];
}

- (NSString *)thumbnailPathWithKey:(NSString *)aKey {
    return [aKey stringByAppendingPathExtension:@"jpeg"];
}
*/

- (void)uploadVybe:(VYBMyVybe *)aVybe {
    VYBMyVybe *vybeToGo;
    for (VYBMyVybe *v in myVybes) {
        if ( [aVybe.uniqueFileName isEqualToString:v.uniqueFileName] ) {
            vybeToGo = v;
            break;
        }
    }
    if (!vybeToGo) {
        return;
    }
    
    NSData *thumbnail = [NSData dataWithContentsOfFile:[vybeToGo thumbnailFilePath]];
    NSData *video = [NSData dataWithContentsOfFile:[vybeToGo videoFilePath]];
  
    PFFile *thumbnailFile = [PFFile fileWithData:thumbnail];
    PFFile *videoFile = [PFFile fileWithData:video];
    
    PFObject *vybe = [vybeToGo parseObjectVybe];

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
                    [self removeVybe:vybeToGo];
                }
            }];
        }
    }];
}

/*
- (void)uploadVybeForKey:(NSString *)aKey {

    
 
    
    [thumbnailFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [videoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                                   [vybe saveE]
                    [vybe saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if (succeeded) {
                            // Send out NSNotification
                            NSLog(@"New vybe successfully posted.");
                            // Remove the vybe from upload queue
                            [self removeVybeWithKey:aKey];
                        }
                    }];
                } else {
                    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Network Temporarily Unavailable. Your vybe will be posted later. :) " message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [av show];
                    NSLog(@"Error: [MyVybeStore] uploading video failed.");
                }
            }];
        } else {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Network Temporarily Unavailable. Your vybe will be posted later. :) " message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [av show];
            NSLog(@"Error: [MyVybeStore] uploading thumbnail failed.");
        }
    }];
}
*/

- (void)removeVybe:(VYBMyVybe *)aVybe {
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
