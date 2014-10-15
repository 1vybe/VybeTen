//
//  VYBUtility.m
//  VybeTen
//
//  Created by jinsuk on 5/15/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "AVAsset+VideoOrientation.h"
#import "UIImage+FixOrientation.h"
#import "NSMutableArray+PFObject.h"
#import "VYBUtility.h"
#import "VYBCache.h"
#import "VYBConstants.h"
#import "VYBMyVybeStore.h"

@implementation VYBUtility

#pragma mark - Activity
+ (void)getNewActivityCountWithCompletion:(void (^)(BOOL succeeded, NSError *error))completionBlock {
    if (![PFUser currentUser]) {
        return;
    }
    
    PFQuery *query = [PFQuery queryWithClassName:kVYBActivityClassKey];
    [query whereKey:kVYBActivityToUserKey equalTo:[PFUser currentUser]];
    NSDate *someTimeAgo = [NSDate dateWithTimeIntervalSinceNow:-3600 * VYBE_TTL_HOURS];
    // only get activities that a user has not seen yet
    NSDate *lastRefresh = [[PFUser currentUser] objectForKey:kVYBUserLastRefreshedKey];
    if (lastRefresh && ([lastRefresh timeIntervalSinceDate:someTimeAgo] > 0))
        someTimeAgo = lastRefresh;
    [query whereKey:@"createdAt" greaterThanOrEqualTo:someTimeAgo];
    [query orderByDescending:@"createdAt"];
    [query includeKey:kVYBActivityFromUserKey];
    [query includeKey:kVYBActivityVybeKey];
    
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (!error) {
            [[VYBCache sharedCache] setActivityCount:number];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:VYBUtilityActivityCountUpdatedNotification object:nil];
            });
            
            if (completionBlock)
                completionBlock(YES, nil);
        } else {
            if (completionBlock)
                completionBlock(NO, error);
        }
    }];
}

+ (void)updateLastRefreshForCurrentUser {
    // Set cached activity count to 0
    [[VYBCache sharedCache] setActivityCount:0];
    // Post notification so the count gets updated on capture screen
    [[NSNotificationCenter defaultCenter] postNotificationName:VYBUtilityActivityCountUpdatedNotification object:nil];
    // Update lastRefreshed of current user to now
    PFObject *currUsr = [PFUser currentUser];
    
    [currUsr setObject:[NSDate date] forKey:kVYBUserLastRefreshedKey];
    [currUsr saveInBackground];
    
    // Set icon bagde to 0
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation.badge = 0;
    [currentInstallation saveInBackground];
    
}


#pragma mark Like Vybes

+ (void)likeVybeInBackground:(id)vybe block:(void (^)(BOOL succeeded, NSError *error))completionBlock {
    // First update cache to show changes right away
    NSArray *cLikers = [[VYBCache sharedCache] likersForVybe:vybe];
    if (cLikers)
        cLikers = [cLikers arrayByAddingObject:[PFUser currentUser]];
    else
        cLikers = [NSArray arrayWithObject:[PFUser currentUser]];
    [[VYBCache sharedCache] setAttributesForVybe:vybe likers:cLikers commenters:nil likedByCurrentUser:YES];
    
    PFQuery *queryExistingLikes = [PFQuery queryWithClassName:kVYBActivityClassKey];
    [queryExistingLikes whereKey:kVYBActivityVybeKey equalTo:vybe];
    [queryExistingLikes whereKey:kVYBActivityTypeKey equalTo:kVYBActivityTypeLike];
    [queryExistingLikes whereKey:kVYBActivityFromUserKey equalTo:[PFUser currentUser]];
    [queryExistingLikes setCachePolicy:kPFCachePolicyNetworkOnly];
    [queryExistingLikes findObjectsInBackgroundWithBlock:^(NSArray *activities, NSError *error) {
        if (!error) {
            for (PFObject *activity in activities) {
                [activity deleteInBackground];
            }
        }
        
        // proceed to creating new like
        PFObject *likeActivity = [PFObject objectWithClassName:kVYBActivityClassKey];
        [likeActivity setObject:kVYBActivityTypeLike forKey:kVYBActivityTypeKey];
        [likeActivity setObject:[PFUser currentUser] forKey:kVYBActivityFromUserKey];
        [likeActivity setObject:[vybe objectForKey:kVYBVybeUserKey] forKey:kVYBActivityToUserKey];
        [likeActivity setObject:vybe forKey:kVYBActivityVybeKey];
        
        PFACL *likeACL = [PFACL ACLWithUser:[PFUser currentUser]];
        [likeACL setPublicReadAccess:YES];
        [likeACL setWriteAccess:YES forUser:[vybe objectForKey:kVYBVybeUserKey]];
        likeActivity.ACL = likeACL;
        
        [likeActivity saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (completionBlock) {
                completionBlock(succeeded,error);
            }
            
            // refresh cache
            PFQuery *query = [VYBUtility queryForActivitiesOnVybe:vybe cachePolicy:kPFCachePolicyNetworkOnly];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (!error) {
                    
                    NSMutableArray *likers = [NSMutableArray array];
                    NSMutableArray *commenters = [NSMutableArray array];
                    
                    BOOL isLikedByCurrentUser = NO;
                    
                    for (PFObject *activity in objects) {
                        if ([[activity objectForKey:kVYBActivityTypeKey] isEqualToString:kVYBActivityTypeLike] && [activity objectForKey:kVYBActivityFromUserKey]) {
                            [likers addObject:[activity objectForKey:kVYBActivityFromUserKey]];
                        } else if ([[activity objectForKey:kVYBActivityTypeKey] isEqualToString:kVYBActivityTypeComment] && [activity objectForKey:kVYBActivityFromUserKey]) {
                            [commenters addObject:[activity objectForKey:kVYBActivityFromUserKey]];
                        }
                        
                        if ([[[activity objectForKey:kVYBActivityFromUserKey] objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
                            if ([[activity objectForKey:kVYBActivityTypeKey] isEqualToString:kVYBActivityTypeLike]) {
                                isLikedByCurrentUser = YES;
                            }
                        }
                    }
                    
                    [[VYBCache sharedCache] setAttributesForVybe:vybe likers:likers commenters:commenters likedByCurrentUser:isLikedByCurrentUser];
                }
                
//                [[NSNotificationCenter defaultCenter] postNotificationName:VYBUtilityUserLikedUnlikedVybeCallbackFinishedNotification object:vybe userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:succeeded] forKey:VYBVybeDetailsViewControllerUserLikedUnlikedVybeNotificationUserInfoLikedKey]];
            }];
            
        }];
    }];
    
}

+ (void)unlikeVybeInBackground:(id)vybe block:(void (^)(BOOL succeeded, NSError *error))completionBlock {
    // First update cache to show changes right away
    NSMutableArray *cLikers = [NSMutableArray arrayWithArray:[[VYBCache sharedCache] likersForVybe:vybe]];
    if (cLikers)
        [cLikers removePFObject:[PFUser currentUser]];
    else {
        
    }
    [[VYBCache sharedCache] setAttributesForVybe:vybe likers:cLikers commenters:nil likedByCurrentUser:NO];
    
    PFQuery *queryExistingLikes = [PFQuery queryWithClassName:kVYBActivityClassKey];
    [queryExistingLikes whereKey:kVYBActivityVybeKey equalTo:vybe];
    [queryExistingLikes whereKey:kVYBActivityTypeKey equalTo:kVYBActivityTypeLike];
    [queryExistingLikes whereKey:kVYBActivityFromUserKey equalTo:[PFUser currentUser]];
    [queryExistingLikes setCachePolicy:kPFCachePolicyNetworkOnly];
    [queryExistingLikes findObjectsInBackgroundWithBlock:^(NSArray *activities, NSError *error) {
        if (!error) {
            for (PFObject *activity in activities) {
                [activity deleteInBackground];
            }
            
            if (completionBlock) {
                completionBlock(YES,nil);
            }
            
            // refresh cache
            PFQuery *query = [VYBUtility queryForActivitiesOnVybe:vybe cachePolicy:kPFCachePolicyNetworkOnly];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (!error) {
                    
                    NSMutableArray *likers = [NSMutableArray array];
                    NSMutableArray *commenters = [NSMutableArray array];
                    
                    BOOL isLikedByCurrentUser = NO;
                    
                    for (PFObject *activity in objects) {
                        if ([[activity objectForKey:kVYBActivityTypeKey] isEqualToString:kVYBActivityTypeLike]) {
                            [likers addObject:[activity objectForKey:kVYBActivityFromUserKey]];
                        } else if ([[activity objectForKey:kVYBActivityTypeKey] isEqualToString:kVYBActivityTypeComment]) {
                            [commenters addObject:[activity objectForKey:kVYBActivityFromUserKey]];
                        }
                        
                        if ([[[activity objectForKey:kVYBActivityFromUserKey] objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
                            if ([[activity objectForKey:kVYBActivityTypeKey] isEqualToString:kVYBActivityTypeLike]) {
                                isLikedByCurrentUser = YES;
                            }
                        }
                    }
                    
                    [[VYBCache sharedCache] setAttributesForVybe:vybe likers:likers commenters:commenters likedByCurrentUser:isLikedByCurrentUser];
                }
                
//                [[NSNotificationCenter defaultCenter] postNotificationName:PAPUtilityUserLikedUnlikedPhotoCallbackFinishedNotification object:vybe userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:PAPPhotoDetailsViewControllerUserLikedUnlikedPhotoNotificationUserInfoLikedKey]];
            }];
            
        } else {
            if (completionBlock) {
                completionBlock(NO,error);
            }
        }
    }];  
}

#pragma mark Activities

+ (PFQuery *)queryForActivitiesOnVybe:(PFObject *)vybe cachePolicy:(PFCachePolicy)cachePolicy {
    PFQuery *queryLikes = [PFQuery queryWithClassName:kVYBActivityClassKey];
    [queryLikes whereKey:kVYBActivityVybeKey equalTo:vybe];
    [queryLikes whereKey:kVYBActivityTypeKey equalTo:kVYBActivityTypeLike];
    
    PFQuery *queryComments = [PFQuery queryWithClassName:kVYBActivityClassKey];
    [queryComments whereKey:kVYBActivityVybeKey equalTo:vybe];
    [queryComments whereKey:kVYBActivityTypeKey equalTo:kVYBActivityTypeComment];
    
    PFQuery *query = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects:queryLikes,queryComments,nil]];
    [query setCachePolicy:cachePolicy];
    [query includeKey:kVYBActivityFromUserKey];
    [query includeKey:kVYBActivityVybeKey];
    
    return query;
}

#pragma mark - Feed
+ (void)fetchFreshVybeFeedWithCompletion:(void (^)(BOOL succeeded, NSError *error))completionBlock {
    if (![PFUser currentUser]) {
        return;
    }
    
    NSString *functionName = @"get_fresh_vybes";
    [PFCloud callFunctionInBackground:functionName withParameters:@{} block:^(NSArray *objects, NSError *error) {
        if (error) {
            if (completionBlock) {
                completionBlock(NO, error);
            }
        } else {
            if (objects) {
                for (PFObject *nVybe in objects) {
                    if ([nVybe isKindOfClass:[NSNull class]])
                        continue;
                    [[VYBCache sharedCache] addFreshVybe:nVybe];
                }
                
                // Only set lastRefresh after inital vybe loading
                if ( [[VYBCache sharedCache] vybesByLocation] )
                    [[VYBCache sharedCache] setLastRefresh:[NSDate date]];
                
                if (completionBlock) {
                    completionBlock(YES, nil);
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:VYBFreshVybeFeedFetchedFromRemoteNotification object:self];
                });
            }
        }
    }];
    
}

+ (void)getVybesByLocationAndByUserInBackground {
    [self getVybesByLocationAndByUser:nil];
}

+ (void)getVybesByLocationAndByUser:(void (^)(BOOL succeeded, NSError *error))completionBlock {
    if ( ! [PFUser currentUser] )
        return;
    
    PFQuery *query = [PFQuery queryWithClassName:kVYBVybeClassKey];
    // 24 TTL checking
    NSDate *someTimeAgo = [[NSDate alloc] initWithTimeIntervalSinceNow:-3600 * VYBE_TTL_HOURS];
    [query whereKey:kVYBVybeTimestampKey greaterThanOrEqualTo:someTimeAgo];
    // Don't include urself
    [query whereKey:kVYBVybeUserKey notEqualTo:[PFUser currentUser]];
    [query whereKeyExists:kVYBVybeLocationStringKey];
    [query whereKey:kVYBVybeLocationStringKey notEqualTo:@""];
    [query setLimit:1000];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (PFObject *obj in objects) {
                NSString *locString = obj[kVYBVybeLocationStringKey];
                NSArray *token = [locString componentsSeparatedByString:@","];
                if (token.count != 3)
                    continue;
                
                //NOTE: we discard the first location field (neighborhood)
                NSString *keyString = [NSString stringWithFormat:@"%@,%@", token[1], token[2]];
                [[VYBCache sharedCache] addVybe:obj forLocation:keyString];
                [[VYBCache sharedCache] addVybe:obj forUser:obj[kVYBVybeUserKey]];
            }
            [self getUsersByLocation:completionBlock];
        } else {
            if (completionBlock)
                completionBlock(NO, error);
        }
    }];
}

+ (void)getUsersByLocation:(void (^)(BOOL succeeded, NSError *error))completionBlock {
    PFQuery *query = [PFUser query];
    // 24 TTL checking
    NSDate *someTimeAgo = [[NSDate alloc] initWithTimeIntervalSinceNow:-3600 * VYBE_TTL_HOURS];
    [query whereKey:kVYBUserLastVybedTimeKey greaterThanOrEqualTo:someTimeAgo];
    [query whereKey:kVYBUserUsernameKey notEqualTo:[PFUser currentUser][kVYBUserUsernameKey]];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (PFObject *aUser in objects) {
                NSArray *token = [aUser[kVYBUserLastVybedLocationKey] componentsSeparatedByString:@","];
                if (token.count != 3)
                    continue;
                
                //NOTE: we discard the first location field (neighborhood)
                NSString *keyString = [NSString stringWithFormat:@"%@,%@", token[1], token[2]];
                [[VYBCache sharedCache] addUser:aUser forLocation:keyString];
            }
            if (completionBlock)
                completionBlock(YES, nil);
        }
        else {
            if (completionBlock)
                completionBlock(NO, error);
        }
    }];
}


#pragma mark Thumbnail

+ (void)saveThumbnailImageForVybe:(VYBVybe *)mVybe {
    NSURL *url = [[NSURL alloc] initFileURLWithPath:[mVybe videoFilePath]] ;
    // Generating and saving a thumbnail for the captured vybe
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *generate = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    // To transform the snapshot to be in the orientation the video was taken with
    [generate setAppliesPreferredTrackTransform:YES];
    NSError *err = NULL;
    CMTime time = CMTimeMake(1, 60);
    CGImageRef imgRef = [generate copyCGImageAtTime:time actualTime:NULL error:&err];
    UIImage *tempImg = [[UIImage alloc] initWithCGImage:imgRef];
    NSData *thumbData = UIImageJPEGRepresentation(tempImg, 0.3);
    NSURL *thumbURL = [[NSURL alloc] initFileURLWithPath:[mVybe thumbnailFilePath]];
    BOOL success = [thumbData writeToURL:thumbURL atomically:YES];
    
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

+ (void)reverseGeoCode:(PFGeoPoint *)aLocation withCompletion:(void (^)(NSArray *, NSError *))completionBlock {
    if (!aLocation) {
        return;
    }
    CLLocation *location = [[CLLocation alloc] initWithLatitude:[aLocation latitude] longitude:[aLocation longitude]];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        completionBlock(placemarks, error);
    }];
}

+ (NSString *)convertPlacemarkToLocation:(CLPlacemark *)placemark {
    NSString *subLocalty = placemark.subLocality; // neighborhood
    NSString *localty = placemark.locality; // city
    //NSString *subAdminArea = placemark.subAdministrativeArea; // county
    NSString *adminArea = placemark.administrativeArea; // state
    //NSString *country = placemark.country; // country
    
    NSString *location = subLocalty;
    location = (location && location.length > 0) ? [location stringByAppendingFormat:@", %@", localty] : localty;
    //location = (subAdminArea && subAdminArea.length > 0) ? [location stringByAppendingFormat:@", %@", subAdminArea] : location;
    location = (adminArea && adminArea.length > 0) ? [location stringByAppendingFormat:@", %@", adminArea] : location;
    
    return location;
}

+ (NSString *)localizedDateStringFrom:(NSDate *)aDate {
    static NSDateFormatter *dFormatterLocalized = nil;
    if (!dFormatterLocalized) {
        dFormatterLocalized = [[NSDateFormatter alloc] init];
        // TODO: Localize timezone
        NSTimeZone *timeZone = [NSTimeZone localTimeZone];
        [dFormatterLocalized setTimeZone:timeZone];
        [dFormatterLocalized setDateFormat:@"MM/dd HH:mm"];
    }
    return [dFormatterLocalized stringFromDate:aDate];
}

+ (NSString *)reverseTime:(NSDate *)aDate {
    double timePassed = [[NSDate date] timeIntervalSinceDate:aDate];
    NSString *unit;
    int i;
    if (timePassed < 60) {
        i = timePassed / 1;
        unit = @"second";
    } else if (timePassed < 60 * 60) {
        i = timePassed / 60;
        unit = @"minute";
    } else if (timePassed < 3600 * 24.0) {
        i = timePassed / 3600;
        unit = @"hour";
    } else if (timePassed < 3600 * 24 * 7) {
        i = timePassed/ 3600 / 24;
        unit = @"day";
    } else if (timePassed < 3600 * 24 * 7 * 4) {
        i = timePassed / 3600 / 24 / 7;
        unit = @"week";
    } else if (timePassed < 3600 * 24 * 7 * 4 * 12) {
        i = timePassed / 3600 / 24 / 7 / 4;
        unit = @"month";
    } else {
        i = timePassed / 3600 / 24 / 7 / 4 / 12;
        unit = @"year";
    }
    
    if (i > 1) {
        unit = [unit stringByAppendingString:@"s"];
    }
    NSString *theTime = [NSString stringWithFormat:@"%d %@ ago", i, unit];
    
    return theTime;
}

+ (void)showToastWithImage:(UIImage *)aIamge title:(NSString *)title {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImageView *imageView = [[UIImageView alloc] initWithImage:aIamge];
        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:[[UIApplication sharedApplication] delegate].window];
        [[[UIApplication sharedApplication] delegate].window addSubview:hud];
        hud.mode = MBProgressHUDModeCustomView;
        hud.customView = imageView;
        hud.labelText = title;
        [hud show:YES];
        [hud hide:YES afterDelay:1.0];
    });
}

+ (CGAffineTransform)getTransformFromOrientation:(NSInteger)orientation {
    CGAffineTransform transform;
    switch (orientation) {
        case AVCaptureVideoOrientationPortrait:
            transform = CGAffineTransformMakeRotation(0);
            break;
        case AVCaptureVideoOrientationPortraitUpsideDown:
            transform = CGAffineTransformMakeRotation(M_PI);
            break;
        case AVCaptureVideoOrientationLandscapeLeft:
            transform = CGAffineTransformMakeRotation(M_PI_2);
            break;
        case AVCaptureVideoOrientationLandscapeRight:
            transform = CGAffineTransformMakeRotation(-M_PI_2);
            break;

    }
    
    return transform;
}

+ (UIImage*) maskImage:(UIImage *)image withMask:(UIImage *)maskImage {
    
    CGImageRef maskRef = maskImage.CGImage;
    
    CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);
    
    CGImageRef masked = CGImageCreateWithMask([image CGImage], mask);
    return [UIImage imageWithCGImage:masked];
}

@end
