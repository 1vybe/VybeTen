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
#import "VYBMyVybeStore.h"

@implementation VYBUtility

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
        NSLog(@"local timezone is %@", [NSTimeZone localTimeZone]);
        NSTimeZone *timeZone = [NSTimeZone localTimeZone];
        [dFormatterLocalized setTimeZone:timeZone];
        [dFormatterLocalized setDateFormat:@"MM/dd HH:mm"];
    }
    return [dFormatterLocalized stringFromDate:aDate];
}

@end
