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
NSString *const VYBAppDelegateHandlePushPlayActivityNotification =
    @"com.vybe.app.AppDelegate.handlePush.playActivity";

NSString *const CloudUtilityPointUpdatedByCurrentUserNotification = @"com.vybe.app.CloudUtility.pointUpdatedByCurrentUser";

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
NSString *const kVYBUserDefaultsLastRefreshKey     = @"com.vybe.app.userDefaults.lastRefresh";

#pragma mark - PFObject User Class
// field keys
NSString *const kVYBUserUsernameKey                             = @"username";
NSString *const kVYBUserPointScoreKey                           = @"pointScore";
NSString *const kVYBUserLastRefreshedKey                        = @"lastRefreshed";
NSString *const kVYBUserBlockedUsersKey                         = @"blockedUsers";
NSString *const kVYBUserTermsAgreedKey                          = @"termsAgreed";
NSString *const kVYBUserPromptsSeenKey                          = @"userPromptsSeen";
NSString *const kVYBUserFlagsKey                                = @"flags";

//NSString *const kVYBUserProfilePicSmallKey                      = @"profilePictureSmall";
//NSString *const kVYBUserProfilePicMediumKey                     = @"profilePictureMedium";
//NSString *const kVYBUserLastVybedZoneKey                        = @"lastVybedZone";
//NSString *const kVYBUserLastVybedTimeKey                        = @"lastVybedTime";
//NSString *const kVYBUserFreshFeedKey                            = @"feed";

#pragma mark - PFObject Vybe Class
// class key
NSString *const kVYBVybeClassKey                                = @"Vybe";

// field keys
NSString *const kVYBVybeVideoKey                                = @"video";
NSString *const kVYBVybeThumbnailKey                            = @"thumbnail";
NSString *const kVYBVybeUserKey                                 = @"user";
NSString *const kVYBVybeTimestampKey                            = @"timestamp";
NSString *const kVYBVybeGeotagKey                               = @"location";
//NSString *const kVYBVybePointScoreKey                           = @"pointScore";

//NSString *const kVYBVybeTribeKey                                = @"tribe";
//NSString *const kVYBVybeTypePublicKey                           = @"isPublic";
//NSString *const kVYBVybeLocationStringKey                       = @"locationString";
//NSString *const kVYBVybeCountryCodeKey                          = @"countryCode";
//NSString *const kVYBVybeTagKey                                  = @"tag";
//NSString *const kVYBVybeZoneNameKey                             = @"zoneName";
//NSString *const kVYBVybeZoneIDKey                               = @"zoneID";
//NSString *const kVYBVybeZoneLatitudeKey                         = @"zoneLatitude";
//NSString *const kVYBVybeZoneLongitudeKey                        = @"zoneLongitude";
//NSString *const kVYBVybeHashtagsKey                             = @"hashtags";

#pragma mark - PFObject Point Class
NSString *const kVYBPointClassKey                              = @"Point";
NSString *const kVYBPointVybeKey                               = @"vybe";
NSString *const kVYBPointUserKey                               = @"user";

NSString *const kVYBPointTypeKey                               = @"type";
NSString *const kVYBPointTypeUpKey                             = @"up";
NSString *const kVYBPointTypeDownKey                           = @"down";

#pragma mark - PFObject Tribe Class
// class key
NSString *const kVYBTribeClassKey                               = @"Tribe";

// field keys
NSString *const kVYBTribeNameKey                                = @"name";
NSString *const kVYBTribeLastVybeKey                            = @"lastVybe";
NSString *const kVYBTribeCoordinatorKey                         = @"coordinator";
NSString *const kVYBTribeMembersKey                             = @"members";

NSString *const kVYBTribeDescriptionKey                         = @"description";
NSString *const kVYBTribeGeoTagKey                              = @"geoTag";
NSString *const kVYBTribeTypeIsPublicKey                        = @"isPublic";

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

#pragma mark - PFObject Hashtag Class
NSString *const kVYBHashtagClassKey                               = @"Hashtag";

NSString *const kVYBHashtagNameKey                                = @"name";
NSString *const kVYBHashtagVybesKey                               = @"vybes";
NSString *const kVYBHashtagLowercaseKey                           = @"name_lowercase";
//NSString *const kVYBHashTagZoneKey                                = @"zone";

#pragma mark - Cached User Attributes
// keys
NSString *const kVYBUserAttributesVybeCountKey                  = @"vybeCount";
NSString *const kVYBUserAttributesIsFollowedByCurrentUserKey    = @"isFollowedByCurrentUser";
NSString *const kVYBUserAttributesBlockedUsersKey               = @"blockedUsers";
NSString *const kVYBUserAttributesBumpsForMeKey                 = @"bumpsForMe";
NSString *const kVYBUserAttributesMyBumpsKey                    = @"myBumps";

#pragma mark - Cached Vybe Attributes
// keys
NSString *const kVYBVybeAttributesPointScoreKey                   = @"pointScore";
NSString *const kVYBVybeAttributesPointTypeByCurrentUserKey       = @"pointType";
NSString *const kVYBVybeAttributesPointTypeNoneKey                  = @"none";
NSString *const kVYBVybeAttributesPointTypeUpKey                  = @"upPoint";
NSString *const kVYBVybeAttributesPointTypeDownKey                = @"downPoint";

NSString *const kVYBVybeAttributesIsLikedByCurrentUserKey         = @"isLikedByCurrentUser";
NSString *const kVYBVybeAttributesIsFlaggedByCurrentUserKey       = @"isFlaggedByCurrentUser";
NSString *const kVYBVybeAttributesLikeCountKey                    = @"likeCount";
NSString *const kVYBVybeAttributesLikersKey                       = @"likers";
NSString *const kVYBVybeAttributesCommentCountKey                 = @"commentCount";
NSString *const kVYBVybeAttributesCommentersKey                   = @"commenters";
NSString *const kVYBVybeAttributesNearbyCountKey                  = @"nearbyCount";


#pragma mark - Installation Class
// Field keys
NSString *const kVYBInstallationUserKey                         = @"user";


#pragma mark - PFPush Notification Payload Keys

NSString *const kAPNSAlertKey                                   = @"alert";
NSString *const kAPNSBadgeKey                                   = @"badge";
NSString *const kAPNSSoundKey                                   = @"sound";

NSString *const kVYBPushPayloadPayloadTypeKey                   = @"p";
NSString *const kVYBPushPayloadPayloadTypeVybeKey               = @"v";
NSString *const kVYBPushPayloadTribeIDKey                       = @"tid";

NSString *const kVYBPushPayloadPayloadTypeActivityKey           = @"a";
NSString *const kVYBPushPayloadActivityTypeKey                  = @"t";
NSString *const kVYBPushPayloadActivityTypeFollowKey            = @"f";
NSString *const kVYBPushPayloadActivityTypeLikeKey              = @"l";
NSString *const kVYBPushPayloadActivityFromUserObjectIdKey      = @"fu";
NSString *const kVYBPushPayloadActivityIDKey                    = @"pid";
NSString *const kVYBPushPayloadActivityToUserObjectIdKey        = @"tu";




