//
//  VYBUtility.h
//  VybeTen
//
//  Created by jinsuk on 5/15/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface VYBUtility : NSObject

+ (void)saveThumbnailImageForVybeWithFilePath:(NSString *)filePath;
+ (NSString *)localizedDateStringFrom:(NSDate *)aDate;
+ (void)reverseGeoCode:(PFGeoPoint *)aLocation withCompletion:(void (^)(NSArray *placemarks, NSError *error))completionBlock;
+ (NSString *)convertPlacemarkToLocation:(CLPlacemark *)placemark;


#pragma mark Display Name

+ (NSString *)firstNameForDisplayName:(NSString *)displayName;


@end
