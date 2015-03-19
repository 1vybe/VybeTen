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
+ (void)updateBumpCountInBackground:(PFObject *)vybe withBlock:(void (^)(BOOL succeeded))completionBlock;

+ (PFQuery *)queryForActivitiesOnVybe:(PFObject *)vybe cachePolicy:(PFCachePolicy)cachePolicy;

+ (void)saveThumbnailImageForVybe:(VYBVybe *)mVybe;
+ (NSString *)timeStringForPlayer:(NSDate *)aDate;
+ (NSString *)localizedDateStringFrom:(NSDate *)aDate;
+ (NSString *)reverseTime:(NSDate *)aDate;
+ (NSString *)reverseTimeShorthand:(NSDate *)aDate;
+ (NSDate *)dateFromDateString:(NSString *)dateString;
+ (void)reverseGeoCode:(PFGeoPoint *)aLocation withCompletion:(void (^)(NSArray *placemarks, NSError *error))completionBlock;
+ (NSString *)convertPlacemarkToLocation:(CLPlacemark *)placemark;
+ (CGAffineTransform)getTransformFromOrientation:(NSInteger)orientation;
+ (UIImage*)maskImage:(UIImage *)image withMask:(UIImage *)maskImage;

+ (void)showUploadProgressBarFromBottom:(UIView *)aView;
+ (void)showToastWithImage:(UIImage *)aIamge title:(NSString *)title;

+ (void)clearTempDirectory;

#pragma mark Display Name

+ (NSString *)firstNameForDisplayName:(NSString *)displayName;


@end
