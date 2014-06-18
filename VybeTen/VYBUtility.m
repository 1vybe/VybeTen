//
//  VYBUtility.m
//  VybeTen
//
//  Created by jinsuk on 5/15/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "VYBUtility.h"
#import "VYBCache.h"
#import "VYBConstants.h"
#import "UIImage+ResizeAdditions.h"
#import "VYBMyVybeStore.h"

@implementation VYBUtility

#pragma mark Facebook

+ (void)processFacebookProfilePictureData:(NSData *)newProfilePictureData {
    if (newProfilePictureData.length == 0) {
        return;
    }
    
    // The user's Facebook profile picture is cached to disk. Check if the cached profile picture data matches the incoming profile picture. If it does, avoid uploading this data to Parse.

    NSURL *cachesDirectoryURL = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject]; // iOS Caches directory
    
    NSURL *profilePictureCacheURL = [cachesDirectoryURL URLByAppendingPathComponent:@"FacebookProfilePicture.jpg"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[profilePictureCacheURL path]]) {
        // We have a cached Facebook profile picture
        
        NSData *oldProfilePictureData = [NSData dataWithContentsOfFile:[profilePictureCacheURL path]];
        
        if ([oldProfilePictureData isEqualToData:newProfilePictureData]) {
            return;
        }
    }
    
    UIImage *image = [UIImage imageWithData:newProfilePictureData];
    
    UIImage *mediumImage = [image thumbnailImage:280 transparentBorder:0 cornerRadius:140 interpolationQuality:kCGInterpolationHigh];
    UIImage *smallRoundedImage = [image thumbnailImage:64 transparentBorder:0 cornerRadius:32 interpolationQuality:kCGInterpolationLow];
    
    NSData *mediumImageData = UIImagePNGRepresentation(mediumImage); // using JPEG for larger pictures
    NSData *smallRoundedImageData = UIImagePNGRepresentation(smallRoundedImage);
    
    if (mediumImageData.length > 0) {
        PFFile *fileMediumImage = [PFFile fileWithData:mediumImageData];
        [fileMediumImage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                [[PFUser currentUser] setObject:fileMediumImage forKey:kVYBUserProfilePicMediumKey];
                [[PFUser currentUser] saveEventually];
            }
            
        }];
    }
    
    if (smallRoundedImageData.length > 0) {
        PFFile *fileSmallRoundedImage = [PFFile fileWithData:smallRoundedImageData];
        [fileSmallRoundedImage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                [[PFUser currentUser] setObject:fileSmallRoundedImage forKey:kVYBUserProfilePicSmallKey];
                [[PFUser currentUser] saveEventually];
            }
            
        }];
    }
}

+ (void)saveThumbnailImageForVybeWithFilePath:(NSString *)filePath {
    NSURL *url = [[NSURL alloc] initFileURLWithPath:[filePath stringByAppendingPathExtension:@"mov"]] ;
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
    NSURL *thumbURL = [[NSURL alloc] initFileURLWithPath:[filePath stringByAppendingPathExtension:@"jpeg"]];
    [thumbData writeToURL:thumbURL atomically:YES];
    
}


#pragma mark - Follow/ Unfollow Activity

+ (void)followUserInBackground:(PFUser *)fUser block:(void (^)(BOOL, NSError *))completionBlock {
    PFObject *followActivity = [PFObject objectWithClassName:kVYBActivityClassKey];
    [followActivity setObject:kVYBActivityTypeFollow forKey:kVYBActivityTypeKey];
    [followActivity setObject:[PFUser currentUser] forKey:kVYBActivityFromUserKey];
    [followActivity setObject:fUser forKey:kVYBActivityToUserKey];
 
    PFACL *followACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [followACL setPublicReadAccess:YES];
    followActivity.ACL = followACL;
    
    [followActivity saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            if (completionBlock) {
                completionBlock(succeeded, error);
            }
        } else {
            [[VYBCache sharedCache] setFollowStatus:NO user:fUser];
        }
    }];
    
    [[VYBCache sharedCache] setFollowStatus:YES user:fUser];
}

+ (void)unfollowUserEventually:(PFUser *)fUser {
    PFQuery *query = [PFQuery queryWithClassName:kVYBActivityClassKey];
    [query whereKey:kVYBActivityTypeKey equalTo:kVYBActivityTypeFollow];
    [query whereKey:kVYBActivityFromUserKey equalTo:[PFUser currentUser]];
    [query whereKey:kVYBActivityToUserKey equalTo:fUser];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *activities, NSError *error) {
        if (!error) {
            for (PFObject *activity in activities) {
                [activity deleteEventually];
            }
        }
    }];
    
    [[VYBCache sharedCache] setFollowStatus:NO user:fUser];
}


#pragma mark Display Name

+ (NSString *)firstNameForDisplayName:(NSString *)displayName {
    if (!displayName || displayName.length == 0) {
        return @"Someone";
    }
    
    NSArray *displayNameComponents = [displayName componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *firstName = [displayNameComponents objectAtIndex:0];
    if (firstName.length > 100) {
        // truncate to 100 so that it fits in a Push payload
        firstName = [firstName substringToIndex:100];
    }
    return firstName;
}


+ (NSString *)localizedDateStringFrom:(NSDate *)aDate {
    static NSDateFormatter *dFormatterLocalized = nil;
    if (!dFormatterLocalized) {
        dFormatterLocalized = [[NSDateFormatter alloc] init];
        // TODO: Localize timezone
        NSLog(@"local timezone is %@", [NSTimeZone localTimeZone]);
        NSTimeZone *timeZone = [NSTimeZone localTimeZone];
        [dFormatterLocalized setTimeZone:timeZone];
        [dFormatterLocalized setDateFormat:@"MM/dd HH:mm"];
    }
    return [dFormatterLocalized stringFromDate:aDate];
}

@end
