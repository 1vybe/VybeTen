//
//  VYBUtility.h
//  VybeTen
//
//  Created by jinsuk on 5/15/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
@class VYBMyVybe;

@interface VYBUtility : NSObject
+ (void)clearLocalCacheForVybe:(VYBMyVybe *)aVybe;
//+ (void)saveThumbnailImageForVybeWithFilePath:(NSString *)filePath;
+ (void)saveThumbnailImageForVybe:(VYBMyVybe *)mVybe;
+ (NSString *)localizedDateStringFrom:(NSDate *)aDate;
+ (NSString *)reverseTime:(NSDate *)aDate;
+ (void)reverseGeoCode:(PFGeoPoint *)aLocation withCompletion:(void (^)(NSArray *placemarks, NSError *error))completionBlock;
+ (NSString *)convertPlacemarkToLocation:(CLPlacemark *)placemark;
+ (void)showToastWithImage:(UIImage *)aIamge title:(NSString *)title;


#pragma mark Display Name

+ (NSString *)firstNameForDisplayName:(NSString *)displayName;


@end
