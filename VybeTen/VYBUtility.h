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

+ (void)processFacebookProfilePictureData:(NSData *)data;
//+ (void)createTribeWithName:(NSString *)aName inBackgroundWithCompletion:(void (^)(BOOL succeeded, NSError *error))completionBlock;
//+ (NSString *)generateUniqueFileName;
+ (void)saveThumbnailImageForVybeWithFilePath:(NSString *)filePath;
+ (NSString *)localizedDateStringFrom:(NSDate *)aDate;
+ (void)followUserInBackground:(PFUser *)fUser block:(void (^) (BOOL succeed, NSError *err))completionBlock;
+ (void)unfollowUserEventually:(PFUser *)fUser;

#pragma mark Display Name

+ (NSString *)firstNameForDisplayName:(NSString *)displayName;


@end
