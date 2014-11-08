//
//  VYBVybeStore.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 24..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "VYBMyVybeStore.h"
#import "VYBAppDelegate.h"
#import "VYBVybe.h"
#import "VYBConstants.h"
#import "VYBUtility.h"
#import "VYBMyVybeStore.h"

@interface VYBMyVybeStore () {
    VYBVybe *_currVybe;
    dispatch_queue_t _currentUploadQueue;
    
    NSMutableArray *_vybesToUpload;
    dispatch_queue_t _oldUploadQueue;
}

@end
@implementation VYBMyVybeStore

static CLLocation *_bestLocation;
static BOOL _uploadingOldVybes = NO;

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
        _currentUploadQueue = dispatch_queue_create("vybestore current upload queue", DISPATCH_QUEUE_SERIAL);
        
        _oldUploadQueue = dispatch_queue_create("vybestore old upload queue", DISPATCH_QUEUE_SERIAL);
        
        // Load saved videos from Vybe's Documents directory
        NSString *path = [self myVybesArchivePath];
        _vybesToUpload = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:path]];
        if (!_vybesToUpload)
            _vybesToUpload = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)prepareNewVybe {
    PFObject *nVybe = [PFObject objectWithClassName:kVYBVybeClassKey];
    [nVybe setObject:[NSDate date] forKey:kVYBVybeTimestampKey];
    [nVybe setObject:[NSNumber numberWithBool:YES] forKey:kVYBVybeTypePublicKey];
    [nVybe setObject:[NSDate date] forKey:kVYBVybeTimestampKey];

    _currVybe = [[VYBVybe alloc] initWithParseObject:nVybe];
    
    // By default a vybe will be tagged to your last checked-in zone
    if (_currZone) {
        [_currVybe setVybeZone:_currZone];
    }
    
}

- (void)setCurrZone:(Zone *)currZone {
    _currZone = currZone;
    // Update current vybe's zone here
    if (_currVybe) {
        [_currVybe setVybeZone:_currZone];
    }
}


- (void)uploadCurrentVybe {
    
    dispatch_async(_currentUploadQueue, ^{
        VYBVybe *vybeToUpload = [[VYBVybe alloc] initWithVybeObject:_currVybe] ;
        
        [VYBUtility saveThumbnailImageForVybe:vybeToUpload];
        
//        if ( [(VYBAppDelegate *)[UIApplication sharedApplication].delegate isParseReachable] ) {
            NSData *video = [NSData dataWithContentsOfFile:[vybeToUpload videoFilePath]];
            NSData *thumbnail = [NSData dataWithContentsOfFile:[vybeToUpload thumbnailFilePath]];
            
            PFFile *videoFile = [PFFile fileWithData:video];
            PFFile *thumbnailFile = [PFFile fileWithData:thumbnail];
            
            UIProgressView *uploadProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
            [uploadProgressView setFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 50)];
            [[UIApplication sharedApplication].keyWindow addSubview:uploadProgressView];

            [thumbnailFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    [videoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if (!error) {
                            PFObject *vybe = [vybeToUpload parseObject];
                            [vybe setObject:videoFile forKey:kVYBVybeVideoKey];
                            [vybe setObject:thumbnailFile forKey:kVYBVybeThumbnailKey];
                            [vybe saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                if (succeeded) {
                                    [self didUploadVybe:vybeToUpload];
                                } else {
                                    [self currentUploadingFailed];
                                }
                                [uploadProgressView removeFromSuperview];
                            }];
                        } else {
                            [self currentUploadingFailed];
                            [uploadProgressView removeFromSuperview];
                        }
                    } progressBlock:^(int percentDone) {
                        uploadProgressView.progress = percentDone / 100.0;
                    }];
                } else {
                    [self currentUploadingFailed];
                    [uploadProgressView removeFromSuperview];
                }
            }];
            
            // Update user lastVybeLocation and lastVybeTime field.
            [[PFUser currentUser] setObject:[NSDate date] forKey:kVYBUserLastVybedTimeKey];
            [[PFUser currentUser] saveInBackground];
//        }
//        else {
//            [self currentUploadingFailed];
//        }
    });

}


- (void)didUploadVybe:(VYBVybe *)cVybe {
    NSAssert(cVybe, @"did upload a vybe but currVybe is nil now");
    @synchronized (_vybesToUpload) {
        // It's possible that Parse retried to upload and succedded before uplaodDelayedVybe was called on that old vybe
        if ( [_vybesToUpload containsObject:cVybe] ) {
            [_vybesToUpload removeObject:cVybe];
        }
    }
    
    [self clearLocalCacheForVybe:cVybe];
    [VYBUtility showToastWithImage:[UIImage imageNamed:@"button_check.png"] title:@"Posted"];
}

- (void)currentUploadingFailed {
    [self saveCurrentVybe];
    _currVybe = nil;
}

- (void)saveCurrentVybe {
    BOOL success = NO;
    @synchronized (_vybesToUpload) {
        [_vybesToUpload addObject:_currVybe];
        success = [self saveChanges];
    }
    
    if (success) {
        [VYBUtility showToastWithImage:[UIImage imageNamed:@"button_check.png"] title:@"Saved"];
    }
}

- (void)startUploadingOldVybes {
    BOOL parseIsReachable = [(VYBAppDelegate *)[UIApplication sharedApplication].delegate isParseReachable];
    if ( ! parseIsReachable ) {
        return;
    }
    
    if (_uploadingOldVybes)
        return;
    
    _uploadingOldVybes = YES;

    dispatch_async(_oldUploadQueue, ^{
        [self uploadDelayedVybe];
    });
}

- (void)uploadDelayedVybe {
    VYBVybe *oldVybe;
    
    @synchronized (_vybesToUpload) {
        if (_vybesToUpload.count < 1) {
            _uploadingOldVybes = NO;
            return;
        }
        
        oldVybe = [_vybesToUpload firstObject];
    }
    
    BOOL success = [self uploadVybe:oldVybe];
    
    @synchronized (_vybesToUpload) {
        if (success) {
            [_vybesToUpload removeObject:oldVybe];
            [self saveChanges];
        }
    }

    if (success) {
        [self clearLocalCacheForVybe:oldVybe];
        [self uploadDelayedVybe];
    }
}

- (BOOL)uploadVybe:(VYBVybe *)aVybe {
    if (!aVybe)
        return NO;
    
    PFObject *vybe = [aVybe parseObject];

    NSData *video = [NSData dataWithContentsOfFile:[aVybe videoFilePath]];
    NSData *thumbnail = [NSData dataWithContentsOfFile:[aVybe thumbnailFilePath]];
    
    if ( ! video )
        return NO;
    if ( ! thumbnail )
        return NO;
    //NSAssert(video, @"cached video does not exist");
    //NSAssert(thumbnail, @"cached thumbnail does not exist");

    PFFile *videoFile = [PFFile fileWithData:video];
    PFFile *thumbnailFile = [PFFile fileWithData:thumbnail];

    BOOL success = [thumbnailFile save];
    if ( ! success )
        return NO;
    success = [videoFile save];
    if ( ! success )
        return NO;

    [vybe setObject:videoFile forKey:kVYBVybeVideoKey];
    [vybe setObject:thumbnailFile forKey:kVYBVybeThumbnailKey];
    success = [vybe save];
    if ( ! success )
        return NO;
    
    [self clearLocalCacheForVybe:aVybe];
                
    // Only update current user's lastVybedTime and lastVybeLocation if this vybe is fresher
    NSDate *currUserLastVybedTime = [PFUser currentUser][kVYBUserLastVybedTimeKey];
    if (currUserLastVybedTime &&
        ([currUserLastVybedTime timeIntervalSinceDate:vybe[kVYBVybeTimestampKey]] < 0)) {
        [[PFUser currentUser] setObject:[NSDate date] forKey:kVYBUserLastVybedTimeKey];
        [[PFUser currentUser] setObject:[aVybe zoneID] forKey:kVYBUserLastVybedZoneKey];
        success = [[PFUser currentUser] save];
        
        return success;
    }
    return YES;
}


- (void)clearLocalCacheForVybe:(VYBVybe *)aVybe {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSURL *videoURL = [[NSURL alloc] initFileURLWithPath:[aVybe videoFilePath]];
        NSURL *thumbnailURL = [[NSURL alloc] initFileURLWithPath:[aVybe thumbnailFilePath]];
        
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtURL:videoURL error:&error];
        [[NSFileManager defaultManager] removeItemAtURL:thumbnailURL error:&error];
    });
}

- (VYBVybe *)currVybe {
    return _currVybe;
}

- (NSString *)myVybesArchivePath {
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    
    return [documentDirectory stringByAppendingPathComponent:@"myVybes.archive"];
}

- (BOOL)saveChanges {
    NSString *path = [self myVybesArchivePath];
    return [NSKeyedArchiver archiveRootObject:_vybesToUpload toFile:path];
}


@end
