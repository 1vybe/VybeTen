//
//  VYBConstants.m
//  VybeTen
//
//  Created by jinsuk on 3/8/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBConstants.h"

#pragma mark - NSUserDefaults
NSString *const kVYBUserDefaultsCacheFacebookFriendsKey         = @"com.vybe.app.userDefaults.cache.facebookFriends";


#pragma mark - PFObject User Class
// field keys
NSString *const kVYBUserDisplayNameKey                          = @"displayName";
NSString *const kVYBUserFacebookIDKey                           = @"facebookId";
NSString *const kVYBUserPhotoIDKey                              = @"photoId";
NSString *const kVYBUserProfilePicSmallKey                      = @"profilePictureSmall";
NSString *const kVYBUserProfilePicMediumKey                     = @"profilePictureMedium";
NSString *const kVYBUserFacebookFriendsKey                      = @"facebookFriends";
NSString *const kVYBUserAlreadyAutoFollowedFacebookFriendsKey   = @"userAlreadyAutoFollowedFacebookFriends";


#pragma mark - PFObject Vybe Class
// class key
NSString *const kVYBVybeClassKey                                = @"Vybe";

// field keys
NSString *const kVYBVybeVideoKey                                = @"video";
NSString *const kVYBVybeThumbnailKey                            = @"thumbnail";
NSString *const kVYBVybeTribeKey                                = @"tribe";
NSString *const kVYBVybeUserKey                                 = @"user";
NSString *const kVYBVybeTimestampKey                            = @"timestamp";
NSString *const kVYBVybeGeotag                                  = @"geotag";


#pragma mark - PFObject Tribe Class
// class key
NSString *const kVYBTribeClassKey                               = @"Tribe";

// field keys
NSString *const kVYBTribeNameKey                                = @"name";
NSString *const kVYBTribeTypeKey                                = @"type";


#pragma mark - PFObject Activity Class
// Class key
NSString *const kVYBActivityClassKey                            = @"Activity";

// Field keys
NSString *const kVYBActivityTypeKey                             = @"type";
NSString *const kVYBActivityFromUserKey                         = @"fromUser";
NSString *const kVYBActivityToUserKey                           = @"toUser";
NSString *const kVYBActivityContentKey                          = @"content";
NSString *const kVYBActivityVybeKey                             = @"vybe";
NSString *const kVYBActivityTribeKey;

// Type values
NSString *const kVYBActivityTypeFollow                          = @"follow";
NSString *const kVYBActivityTypeJoined;


#pragma mark - Cached User Attributes
// keys
NSString *const kVYBUserAttributesVybeCountKey                  = @"vybeCount";
NSString *const kVYBUserAttributesTribeCountKey                 = @"tribeCount";
NSString *const kVYBUserAttributesIsFollowedByCurrentUserKey    = @"isFollowedByCurrentUser";


#pragma mark - Installation Class
// Field keys
NSString *const kVYBInstallationUserKey = @"user";

@implementation VYBConstants

@end
