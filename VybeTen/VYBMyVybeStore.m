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
#import "NSMutableArray+VYBVybe.h"

@interface VYBMyVybeStore () {
  VYBVybe *_currVybe;
  
  NSMutableArray *_vybesToUpload;
  dispatch_queue_t _oldUploadQueue;
}
@property (nonatomic) int currentUploadPercent;


@end

@implementation VYBMyVybeStore {
  BOOL _uploadingOldVybes;
}
@synthesize currentUploadPercent, currentUploadStatus;

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
    _uploadingOldVybes = NO;
    
    currentUploadPercent = 0;
    currentUploadStatus = CurrentUploadStatusIdle;
    
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
}

- (void)setCurrZone:(Zone *)currZone {
  _currZone = currZone;
  // Update current vybe's zone here
  if (_currVybe) {
    [_currVybe setVybeZone:_currZone];
  }
}


- (void)uploadCurrentVybe {
  [self setCurrentUploadStatus:CurrentUploadStatusUploading];
  
  VYBVybe *vybeToUpload = [[VYBVybe alloc] initWithVybeObject:_currVybe];
  
  NSData *video = [NSData dataWithContentsOfFile:[vybeToUpload videoFilePath]];
  PFFile *videoFile = [PFFile fileWithData:video];
  
  [videoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    if (!error) {
      PFObject *vybe = [vybeToUpload parseObject];
      [vybe setObject:videoFile forKey:kVYBVybeVideoKey];
      
      NSData *thumbnail = [NSData dataWithContentsOfFile:[vybeToUpload thumbnailFilePath]];
      if (thumbnail) {
        PFFile *thumbnailFile = [PFFile fileWithData:thumbnail];
        [vybe setObject:thumbnailFile forKey:kVYBVybeThumbnailKey];
        [thumbnailFile saveInBackground];
      }
      
      [vybe saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
          [self didUploadVybe:vybeToUpload];
        } else {
          [self uploadingFailedWith:vybeToUpload];
        }
      }];
    } else {
      [self uploadingFailedWith:vybeToUpload];
    }
  } progressBlock:^(int percentDone) {
    [self setCurrentUploadPercent:percentDone];
  }];
  
  // Update user lastVybeLocation and lastVybeTime field.
  [[PFUser currentUser] setObject:[NSDate date] forKey:kVYBUserLastVybedTimeKey];
  [[PFUser currentUser] saveInBackground];
  
}


- (void)didUploadVybe:(VYBVybe *)cVybe {
  NSAssert(cVybe, @"did upload a vybe but currVybe is nil now");
  
  // GA stuff
  id tracker = [[GAI sharedInstance] defaultTracker];
  if (tracker) {
    // upload success metric for capture_video event
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"capture_video" label:@"success" value:nil] build]];
  }
  
  if (!_uploadingOldVybes) {
    [self setCurrentUploadStatus:CurrentUploadStatusSuccess];
  }
  
  @synchronized (_vybesToUpload) {
    // It's possible that Parse retried to upload and succedded before uplaodDelayedVybe was called on that old vybe
    [_vybesToUpload removeVybeObject:cVybe];
    [self saveChanges];
  }
  NSLog(@"clearing cache for fresh vybe");
  [self clearLocalCacheForVybe:cVybe];
  [VYBUtility showToastWithImage:[UIImage imageNamed:@"button_check.png"] title:@"Posted"];
}

- (void)uploadingFailedWith:(VYBVybe *)vybeToUpload {
  [self setCurrentUploadStatus:CurrentUploadStatusFailed];
  
  [self saveVybe:vybeToUpload];
  
  // GA stuff
  id tracker = [[GAI sharedInstance] defaultTracker];
  if (tracker) {
    // upload saved metric for capture_video event
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"capture_video" label:@"saved" value:nil] build]];
  }
  _currVybe = nil;
}

- (void)saveVybe:(VYBVybe *)vybeToSave {
  BOOL success = NO;
  @synchronized (_vybesToUpload) {
    [_vybesToUpload addVybeObject:vybeToSave];
    success = [self saveChanges];
  }
  
  if (success) {
    [VYBUtility showToastWithImage:[UIImage imageNamed:@"button_check.png"] title:@"Saved"];
  }
}

- (void)startUploadingSavedVybes {
  BOOL parseIsReachable = [(VYBAppDelegate *)[UIApplication sharedApplication].delegate isParseReachable];
  if ( ! parseIsReachable ) {
    return;
  }
  
  if (_uploadingOldVybes)
    return;
  
  if (_vybesToUpload.count < 1) {
    return;
  }
  
  _uploadingOldVybes = YES;
  [self setCurrentUploadStatus:CurrentUploadStatusUploading];
  
  dispatch_async(_oldUploadQueue, ^{
    [self uploadSavedVybe];
  });
}

- (void)uploadSavedVybe {
  VYBVybe *oldVybe;
  
  @synchronized (_vybesToUpload) {
    if (_vybesToUpload.count < 1) {
      _uploadingOldVybes = NO;
      [self setCurrentUploadStatus:CurrentUploadStatusSuccess];
      
      return;
    }
    
    oldVybe = [_vybesToUpload firstObject];
  }
  
  BOOL success = [self uploadSavedVybe:oldVybe];
  
  @synchronized (_vybesToUpload) {
    if (success) {
      [_vybesToUpload removeVybeObject:oldVybe];
      [self saveChanges];
    }
  }
  
  if (success) {
    // GA stuff
    id tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker) {
      // upload recovered metric for capture_video event
      [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action" action:@"capture_video" label:@"recovered" value:nil] build]];
    }
    NSLog(@"uploaded old vybe: %@", [oldVybe parseObject]);
    
    [self clearLocalCacheForVybe:oldVybe];
    [self uploadSavedVybe];
  }
  else {
    [self setCurrentUploadStatus:CurrentUploadStatusFailed];
  }
}

- (BOOL)uploadSavedVybe:(VYBVybe *)aVybe {
  if (!aVybe)
    return NO;
  
  PFObject *vybe = [aVybe parseObject];
  
  NSData *video = [NSData dataWithContentsOfFile:[aVybe videoFilePath]];
  NSData *thumbnail = [NSData dataWithContentsOfFile:[aVybe thumbnailFilePath]];
  
  if ( ! video ) {
    [_vybesToUpload removeVybeObject:aVybe];
    [self saveChanges];
    return YES;
  }
  //NSAssert(video, @"cached video does not exist");
  //NSAssert(thumbnail, @"cached thumbnail does not exist");
  
  PFFile *videoFile = [PFFile fileWithData:video];
  [vybe setObject:videoFile forKey:kVYBVybeVideoKey];
  BOOL success = [videoFile save];
  if (thumbnail) {
    PFFile *thumbnailFile = [PFFile fileWithData:thumbnail];
    [vybe setObject:thumbnailFile forKey:kVYBVybeThumbnailKey];
    success = [thumbnailFile save];
  }
  
  if ( ! success )
    return NO;
  
  success = [vybe save];
  
  if ( ! success )
    return NO;
  
  /*
   // Only update current user's lastVybedTime and lastVybeLocation if this vybe is fresher
   NSDate *currUserLastVybedTime = [[PFUser currentUser] objectForKey:kVYBUserLastVybedTimeKey];
   if (currUserLastVybedTime &&
   ([currUserLastVybedTime timeIntervalSinceDate:vybe[kVYBVybeTimestampKey]] < 0)) {
   [[PFUser currentUser] setObject:[NSDate date] forKey:kVYBUserLastVybedTimeKey];
   success = [[PFUser currentUser] save];
   
   return success;
   }
   */
  return YES;
}


- (void)clearLocalCacheForVybe:(VYBVybe *)aVybe {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSURL *videoURL = [[NSURL alloc] initFileURLWithPath:[aVybe videoFilePath]];
    NSURL *thumbnailURL = [[NSURL alloc] initFileURLWithPath:[aVybe thumbnailFilePath]];
    
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtURL:videoURL error:&error];
    if (!error) {
      NSLog(@"local cache for video cleared");
    } else {
      NSLog(@"local cache for video clear FAILED");
    }
    [[NSFileManager defaultManager] removeItemAtURL:thumbnailURL error:&error];
    if (!error) {
      NSLog(@"local cache for thumbnail cleared");
    } else {
      NSLog(@"local cache for thumbnail clear FAILED");
    }
  });
}

- (VYBVybe *)currVybe {
  return _currVybe;
}

- (NSArray *)savedVybes {
  return [NSArray arrayWithArray:_vybesToUpload];
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
