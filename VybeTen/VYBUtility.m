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

#import "VybeTen-Swift.h"

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

+ (void)clearTempDirectory {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSURL *path = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    NSArray* temp = [fm contentsOfDirectoryAtPath:NSTemporaryDirectory() error:NULL];
    for (NSString *file in temp) {
      NSURL *filePath = [path URLByAppendingPathComponent:file];
      NSError *error;
      NSDictionary* attrs = [fm attributesOfItemAtPath:[filePath path] error:&error];
      if (attrs != nil) {
        NSDate *date = (NSDate*)[attrs objectForKey: NSFileCreationDate];
        // Delete all files created more than 3 days ago
        if ([date timeIntervalSinceNow] < -60 * 60 * 24 * 3 ) {
          [fm removeItemAtPath:[filePath path] error:&error];
        }
      }
    }
  });
}


#pragma mark - Like Vybes

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

+ (void)updateBumpCountInBackground:(PFObject *)vybe withBlock:(void (^)(BOOL succeeded))completionBlock {
  PFQuery *query = [self queryForActivitiesOnVybe:vybe cachePolicy:kPFCachePolicyNetworkOnly];
  [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    if (!error) {
      NSMutableArray *likers = [NSMutableArray array];
      BOOL isLikedByCurrentUser = NO;
      
      for (PFObject *activity in objects) {
        if ([[activity objectForKey:kVYBActivityTypeKey] isEqualToString:kVYBActivityTypeLike] && [activity objectForKey:kVYBActivityFromUserKey]) {
          [likers addObject:[activity objectForKey:kVYBActivityFromUserKey]];
        }
        if ([[[activity objectForKey:kVYBActivityFromUserKey] objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
          if ([[activity objectForKey:kVYBActivityTypeKey] isEqualToString:kVYBActivityTypeLike]) {
            isLikedByCurrentUser = YES;
          }
        }
      }
      
      [[VYBCache sharedCache] setAttributesForVybe:vybe likers:likers commenters:@[] likedByCurrentUser:isLikedByCurrentUser];
      
      completionBlock(YES);
    }
    else {
      completionBlock(NO);
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

+ (void)fetchActiveZones:(void (^)(NSArray *zones, NSError *error))completionBlock {
  NSString *functionName = @"get_active_vybes";
  [PFCloud callFunctionInBackground:functionName withParameters:@{} block:^(NSArray *vybes, NSError *error) {
    if (!error) {
      NSArray *zones = [self groupByZonesFromVybes:vybes];
      if (completionBlock)
        completionBlock(zones, nil);
    }
    else {
      if (completionBlock)
        completionBlock(nil, error);
    }
  }];
  
}

+ (NSArray *)groupByZonesFromVybes:(NSArray *)vybes {
  NSMutableArray *zones = [[NSMutableArray alloc] init];
  for (PFObject *aVybe in vybes) {
    Zone *zone = [[Zone alloc] initWithName:aVybe[kVYBVybeZoneNameKey] zoneID:aVybe[kVYBVybeZoneIDKey]];
    PFGeoPoint *geoPoint = aVybe[kVYBVybeGeotag];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:geoPoint.latitude longitude:geoPoint.longitude];
    zone.coordinate = [location coordinate];
    if ( ! [self array:zones containsZone:zone] ) {
      [zones addObject:zone];
    }
  }
  return zones;
}

+ (BOOL)array:(NSArray *)zones containsZone:(Zone *)zone {
  for (Zone *aZone in zones) {
    if ([aZone.zoneID isEqualToString:zone.zoneID]) {
      return YES;
    }
  }
  return NO;
}



#pragma mark Thumbnail

+ (BOOL)saveThumbnailImageForVybe:(VYBVybe *)mVybe {
  NSURL *url = [[NSURL alloc] initFileURLWithPath:[mVybe videoFilePath]] ;
  // Generating and saving a thumbnail for the captured vybe
  AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
  AVAssetImageGenerator *generate = [[AVAssetImageGenerator alloc] initWithAsset:asset];
  // To transform the snapshot to be in the orientation the video was taken with
  [generate setAppliesPreferredTrackTransform:YES];
  NSError *err = NULL;
  CMTime time = CMTimeMake(1, 60);
  CGImageRef imgRef = [generate copyCGImageAtTime:time actualTime:NULL error:&err];
  if (err) {
    NSLog(@"Error getting a frame for thumbnail");
  }
  UIImage *tempImg = [[UIImage alloc] initWithCGImage:imgRef];
  NSData *thumbData = UIImageJPEGRepresentation(tempImg, 0.3);
  NSURL *thumbURL = [[NSURL alloc] initFileURLWithPath:[mVybe thumbnailFilePath]];
  BOOL success = [thumbData writeToURL:thumbURL options:NSDataWritingAtomic error:&err];
  if (!success)
    NSLog(@"Error saving thumbnail image: %@", err);
  else
    NSLog(@"[utility] thumbnail successfully saved");
  return success;
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

+ (NSString *)timeStringForPlayer:(NSDate *)aDate {
  double timePassed = [[NSDate date] timeIntervalSinceDate:aDate];
  if (timePassed < 60 * 3) {
    return [self reverseTime:aDate];
  }
  
  return [self simpleLocalizedDateStringFrom:aDate];
}

+ (NSString *)simpleLocalizedDateStringFrom:(NSDate *)aDate {
  static NSDateFormatter *simpleDateFormatterLocalized = nil;
  if (!simpleDateFormatterLocalized) {
    simpleDateFormatterLocalized = [[NSDateFormatter alloc] init];
    // TODO: Localize timezone
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    [simpleDateFormatterLocalized setTimeZone:timeZone];
    [simpleDateFormatterLocalized setDateFormat:@"MMM dd h:mm a"];
  }
  return [simpleDateFormatterLocalized stringFromDate:aDate];
}

+ (NSString *)localizedDateStringFrom:(NSDate *)aDate {
  static NSDateFormatter *dFormatterLocalized = nil;
  if (!dFormatterLocalized) {
    dFormatterLocalized = [[NSDateFormatter alloc] init];
    // TODO: Localize timezone
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    [dFormatterLocalized setTimeZone:timeZone];
    [dFormatterLocalized setDateFormat:@"MMM dd, yyyy HH:mm"];
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
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:[[UIApplication sharedApplication] delegate].window];
    [[[UIApplication sharedApplication] delegate].window addSubview:hud];
    hud.mode = MBProgressHUDModeCustomView;
    if (aIamge) {
      UIImageView *imageView = [[UIImageView alloc] initWithImage:aIamge];
      hud.customView = imageView;
    }
    hud.labelText = title;
    [hud show:YES];
    [hud hide:YES afterDelay:1.0];
  });
}

+ (void)showUploadProgressBarFromBottom:(UIView *)aView {
  UIView *progressView = [[[NSBundle mainBundle] loadNibNamed:@"UploadProgressBottomBar" owner:nil options:nil] firstObject];
  [aView addSubview:progressView];
  [progressView setFrame:CGRectMake(0, aView.bounds.size.height - progressView.bounds.size.height, progressView.bounds.size.width, progressView.bounds.size.height)];
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

+ (UIImage*)maskImage:(UIImage *)image withMask:(UIImage *)maskImage {
  
  CGImageRef maskRef = maskImage.CGImage;
  
  CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                      CGImageGetHeight(maskRef),
                                      CGImageGetBitsPerComponent(maskRef),
                                      CGImageGetBitsPerPixel(maskRef),
                                      CGImageGetBytesPerRow(maskRef),
                                      CGImageGetDataProvider(maskRef), NULL, false);
  
  CGImageRef masked = CGImageCreateWithMask([image CGImage], mask);
  UIImage *simpleImg = [UIImage imageWithCGImage:masked];
  
  CGImageRelease(mask);
  CGImageRelease(masked);
  return simpleImg;
}

@end
