//
//  VYBUtility.h
//  VybeTen
//
//  Created by jinsuk on 5/15/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import <AssetsLibrary/AssetsLibrary.h>

@class VYBVybe;
@interface VYBUtility : NSObject

+ (void)getNewActivityCountWithCompletion:(void (^)(BOOL succeeded, NSError *error))completionBlock;
+ (void)updateLastRefreshForCurrentUser;

+ (void)likeVybeInBackground:(id)vybe block:(void (^)(BOOL succeeded, NSError *error))completionBlock;
+ (void)unlikeVybeInBackground:(id)vybe block:(void (^)(BOOL succeeded, NSError *error))completionBlock;

+ (PFQuery *)queryForActivitiesOnVybe:(PFObject *)vybe cachePolicy:(PFCachePolicy)cachePolicy;

+ (void)fetchFreshVybeFeedWithCompletion:(void (^)(BOOL succeeded, NSError *error))completionBlock;

//+ (void)saveThumbnailImageForVybeWithFilePath:(NSString *)filePath;
+ (void)saveThumbnailImageForVybe:(VYBVybe *)mVybe;
+ (NSString *)localizedDateStringFrom:(NSDate *)aDate;
+ (NSString *)reverseTime:(NSDate *)aDate;
+ (void)reverseGeoCode:(PFGeoPoint *)aLocation withCompletion:(void (^)(NSArray *placemarks, NSError *error))completionBlock;
+ (NSString *)convertPlacemarkToLocation:(CLPlacemark *)placemark;
+ (CGAffineTransform)getTransformFromOrientation:(NSInteger)orientation;
+ (void)showToastWithImage:(UIImage *)aIamge title:(NSString *)title;
+ (UIImage*) maskImage:(UIImage *)image withMask:(UIImage *)maskImage;

#pragma mark Display Name

+ (NSString *)firstNameForDisplayName:(NSString *)displayName;


@end
