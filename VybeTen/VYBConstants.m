//
//  VYBConstants.m
//  VybeTen
//
//  Created by jinsuk on 3/8/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBConstants.h"

#pragma mark - NSNotification

NSString *const VYBAppDelegateApplicationDidReceiveRemoteNotification = @"com.vybe.app.AppDelegate.applicationDidReceiveRemoteNotification";
NSString *const VYBAppDelegateApplicationDidBecomeActiveNotification               = @"com.vybe.app.AppDelegate.applicationDidBecomeActive";
NSString *const VYBAppDelegateApplicationDidEnterBackgourndNotification = @"com.vybe.app.AppDelegate.applicationDidEnterBackground";
NSString *const VYBAppDelegateParseLocalDatastoreReadyNotification = @"com.vybe.app.appDelegate.parseLocalDatastoreReady";
NSString *const VYBFreshVybeFeedFetchedFromRemoteNotification = @"com.vybe.app.utility.freshFeedFetched";
NSString *const VYBUtilityVybesLoadedNotification = @"com.vybe.app.utility.vybesLoaded";
NSString *const VYBUtilityActivityCountUpdatedNotification = @"com.vybe.app.utility.activityCountUpdated";
NSString *const VYBUtilityUserLikedUnlikedVybeCallbackFinishedNotification     = @"com.vybe.app.utility.userLikedUnlikedVybeCallbackFinished";
NSString *const VYBCacheFreshVybeCountChangedNotification       = @"com.vybe.app.cache.freshVybeCountChanged";
NSString *const VYBSwipeContainerControllerWillMoveToActivityScreenNotification = @"com.vybe.app.swipeContainerController.willMoveToActivityScreen";
NSString *const VYBCacheRefreshedBumpActivitiesForCurrentUser = @"com.vybe.app.cache.refreshedBumpActivitiesForCurrentUser";


#pragma mark - NSUserDefaults
NSString *const kVYBUserDefaultsCacheFacebookFriendsKey         = @"com.vybe.app.userDefaults.cache.facebookFriends";
NSString *const kVYBUserDefaultsActivityLastRefreshKey                  = @"com.vybe.app.userDefaults.ActivityLastRefresh";

NSString *const kVYBUserDefaultsNotificationPermissionKey       = @"com.vybe.app.userDefaults.notification.permission";
NSString *const kVYBUserDefaultsNotificationPermissionUndeterminedKey = @"com.vybe.app.userDefaults.notification.permission.undetermined";
NSString *const kVYBUserDefaultsNotificationPermissionDeniedKey = @"com.vybe.app.userDefaults.notification.permission.denied";
NSString *const kVYBUserDefaultsNotificationPermissionGrantedKey = @"com.vybe.app.userDefaults.notification.permission.granted";

NSString *const kVYBUserDefaultsAudioAccessPermissionKey        = @"com.vybe.app.userDefaults.audio.permission";
NSString *const kVYBUserDefaultsAudioAccessPermissionDeniedKey  = @"com.vybe.app.userDefaults.audio.permission.denied";
NSString *const kVYBUserDefaultsAudioAccessPermissionUndeterminedKey = @"com.vybe.app.userDefaults.audio.permission.undetermined";
NSString *const kVYBUserDefaultsAudioAccessPermissionGrantedKey = @"com.vybe.app.userDefaults.audio.permission.granted";

NSString *const kVYBUserDefaultsVideoAccessPermissionKey        = @"com.vybe.app.userDefaults.video.permission";
NSString *const kVYBUserDefaultsVideoAccessPermissionDeniedKey  = @"com.vybe.app.userDefaults.video.permission.denied";
NSString *const kVYBUserDefaultsVideoAccessPermissionUndeterminedKey = @"com.vybe.app.userDefaults.video.permission.undetermined";
NSString *const kVYBUserDefaultsVideoAccessPermissionGrantedKey = @"com.vybe.app.userDefaults.video.permission.granted";

NSString *const kVYBUserDefaultsUserPromptsSeenKey = @"com.vybe.app.userDefaults.userPrompts.seen";


#pragma mark - PFObject User Class
// field keys
NSString *const kVYBUserUsernameKey                             = @"username";
NSString *const kVYBUserProfilePicSmallKey                      = @"profilePictureSmall";
NSString *const kVYBUserProfilePicMediumKey                     = @"profilePictureMedium";
NSString *const kVYBUserLastVybedZoneKey                        = @"lastVybedZone";
NSString *const kVYBUserLastVybedTimeKey                        = @"lastVybedTime";
NSString *const kVYBUserFreshFeedKey                            = @"freshFeed";
NSString *const kVYBUserLastRefreshedKey                        = @"lastRefreshed";
NSString *const kVYBUserBlockedUsersKey                         = @"blockedUsers";
NSString *const kVYBUserTermsAgreedKey                          = @"termsAgreed";
NSString *const kVYBUserPromptsSeenKey                          = @"userPromptsSeen";
NSString *const kVYBUserFlagsKey                                = @"flags";



/*
NSString *const kVYBUserDisplayNameKey                          = @"displayName";
NSString *const kVYBUserFacebookIDKey                           = @"facebookId";
NSString *const kVYBUserPhotoIDKey                              = @"photoId";

NSString *const kVYBUserFacebookFriendsKey                      = @"facebookFriends";
NSString *const kVYBUserAlreadyAutoFollowedFacebookFriendsKey   = @"userAlreadyAutoFollowedFacebookFriends";
NSString *const kVYBUserLastVybedTime                           = @"lastVybedTime";
NSString *const kVYBUserMostRecentVybeKey                       = @"mostRecentVybe";
*/

#pragma mark - PFObject Vybe Class
// class key
NSString *const kVYBVybeClassKey                                = @"Vybe";

// field keys
NSString *const kVYBVybeVideoKey                                = @"video";
NSString *const kVYBVybeThumbnailKey                            = @"thumbnail";
NSString *const kVYBVybeUserKey                                 = @"user";
NSString *const kVYBVybeTimestampKey                            = @"timestamp";
NSString *const kVYBVybeGeotag                                  = @"location";
NSString *const kVYBVybeTypePublicKey                           = @"isPublic";
NSString *const kVYBVybeLocationStringKey                       = @"locationString";
NSString *const kVYBVybeCountryCodeKey                          = @"countryCode";
NSString *const kVYBVybeTagKey                                  = @"tag";
NSString *const kVYBVybeZoneNameKey                             = @"zoneName";
NSString *const kVYBVybeZoneIDKey                               = @"zoneID";
NSString *const kVYBVybeZoneLatitudeKey                         = @"zoneLatitude";
NSString *const kVYBVybeZoneLongitudeKey                        = @"zoneLongitude";
NSString *const kVYBVybeHashtagsKey                             = @"hashtags";

#pragma mark - Cached Vybe Attributes
// keys
NSString *const kVYBVybeAttributesIsLikedByCurrentUserKey         = @"isLikedByCurrentUser";
NSString *const kVYBVybeAttributesIsFlaggedByCurrentUserKey       = @"isFlaggedByCurrentUser";
NSString *const kVYBVybeAttributesLikeCountKey                    = @"likeCount";
NSString *const kVYBVybeAttributesLikersKey                       = @"likers";
NSString *const kVYBVybeAttributesCommentCountKey                 = @"commentCount";
NSString *const kVYBVybeAttributesCommentersKey                   = @"commenters";
NSString *const kVYBVybeAttributesNearbyCountKey                  = @"nearbyCount";

#pragma mark - PFObject Hashtag Class
NSString *const kVYBHashtagClassKey                               = @"Hashtag";

NSString *const kVYBHashtagNameKey                                = @"name";
NSString *const kVYBHashtagVybesKey                               = @"vybes";
NSString *const kVYBHashtagLowercaseKey                           = @"name_lowercase";
//NSString *const kVYBHashTagZoneKey                                = @"zone";

#pragma mark - PFObject Activity Class
// Class key
NSString *const kVYBActivityClassKey                            = @"Activity";

// Field keys
NSString *const kVYBActivityTypeKey                             = @"type";
NSString *const kVYBActivityFromUserKey                         = @"fromUser";
NSString *const kVYBActivityToUserKey                           = @"toUser";
NSString *const kVYBActivityContentKey                          = @"content";
NSString *const kVYBActivityVybeKey                             = @"vybe";
NSString *const kVYBActivityTimestampKey                        = @"timestamp";


// Type values
NSString *const kVYBActivityTypeFollow                          = @"follow";
NSString *const kVYBActivityTypeLike                            = @"like";
NSString *const kVYBActivityTypeComment                         = @"comment";


#pragma mark - Cached User Attributes
// keys
NSString *const kVYBUserAttributesVybeCountKey                  = @"vybeCount";
NSString *const kVYBUserAttributesIsFollowedByCurrentUserKey    = @"isFollowedByCurrentUser";
NSString *const kVYBUserAttributesBlockedUsersKey               = @"blockedUsers";
NSString *const kVYBUserAttributesBumpsForMeKey                 = @"bumpsForMe";
NSString *const kVYBUserAttributesMyBumpsKey                    = @"myBumps";

#pragma mark - Installation Class
// Field keys
NSString *const kVYBInstallationUserKey                         = @"user";


#pragma mark - PFPush Notification Payload Keys

NSString *const kAPNSAlertKey                                   = @"alert";
NSString *const kAPNSBadgeKey                                   = @"badge";
NSString *const kAPNSSoundKey                                   = @"sound";

NSString *const kVYBPushPayloadPayloadTypeKey                   = @"p";
NSString *const kVYBPushPayloadPayloadTypeActivityKey           = @"a";
NSString *const kVYBPushPayloadPayloadTypeVyveKey               = @"v";

NSString *const kVYBPushPayloadActivityTypeKey                  = @"t";
NSString *const kVYBPushPayloadActivityFollowKey                = @"f";
NSString *const kPAPPushPayloadActivityLikeKey                  = @"l";

NSString *const kVYBPushPayloadActivityFromUserObjectIdKey      = @"fu";
NSString *const kVYBPushPayloadActivityToUserObjectIdKey        = @"tu";

NSString *const kVYBPushPayloadVybeIDKey                        = @"vid";
NSString *const kVYBPushPayloadVybeUserKey                      = @"vu";
