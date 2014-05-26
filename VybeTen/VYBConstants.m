//
//  VYBConstants.m
//  VybeTen
//
//  Created by jinsuk on 3/8/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBConstants.h"

#pragma mark - NSNotification
NSString *const VYBAppDelegateApplicationDidReceiveRemoteNotification = @"com.vybe.app.appDelegate.applicationDidReceiveRemoteNotification";
NSString *const VYBSyncViewControllerDidChangeSyncTribe               = @"com.vybe.app.SyncViewController.didChangeSyncTribe";

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
NSString *const kVYBTribeCreatorKey                             = @"creator";
NSString *const kVYBTribeTypeKey                                = @"type";
//TODO: CLOUD CODE for incrementing vybeCount key when a new PFOject(Vybe) is saved
NSString *const kVYBTribeVybeCountKey                           = @"vybeCount";
//TODO: CLOUD CODE for incrementing membersCount key when a new PFObject(Tribe) is saved with members or member are added later
NSString *const kVYBTribeMembersCountKey                        = @"membersCount";
NSString *const kVYBTribeMembersKey                             = @"members";
NSString *const kVYBTribeThumbnailKey                           = @"thumbnail";

// type values
NSString *const kVYBTribeTypePrivate                            = @"private";
NSString *const kVYBTribeTypePublic                             = @"public";

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
NSString *const kVYBUserAttributesSyncTribeKey                  = @"syncTribe";
NSString *const kVYBUserAttributesVybeCountKey                  = @"vybeCount";
NSString *const kVYBUserAttributesTribeCountKey                 = @"tribeCount";
NSString *const kVYBUserAttributesIsFollowedByCurrentUserKey    = @"isFollowedByCurrentUser";


#pragma mark - Cached Tribe Attributes
// keys
NSString *const kVYBTribeAttributesLastWatchedVybeKey           = @"lastWatchedVybe";
NSString *const kVYBTribeAttributesVybeCountKey                 = @"vybeCount";
NSString *const kVYBTribeAttributesMemberCountKey               = @"memberCount";
NSString *const kVYBTribeAttributesMembersKey                   = @"members";
NSString *const kVYBUserAttributesTribesKey                     = @"tribes";


#pragma mark - Installation Class
// Field keys
NSString *const kVYBInstallationUserKey = @"user";

@implementation VYBConstants

@end
