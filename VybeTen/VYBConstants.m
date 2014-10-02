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
NSString *const VYBFreshVybeFeedFetchedFromRemoteNotification = @"com.vybe.app.utility.freshFeedFetched";
NSString *const VYBHubScreenVybesLoadedNotification = @"com.vybe.app.hub.vybesLoaded";
NSString *const VYBUtilityUserLikedUnlikedVybeCallbackFinishedNotification     = @"com.vybe.app.utility.userLikedUnlikedVybeCallbackFinished";
NSString *const VYBAppDelegateApplicationDidBecomeActive               = @"com.vybe.app.AppDelegate.applicationDidBecomeActive";
NSString *const VYBCacheFreshVybeCountChangedNotification       = @"com.vybe.app.cache.freshVybeCountChanged";

#pragma mark - NSUserDefaults
NSString *const kVYBUserDefaultsCacheFacebookFriendsKey         = @"com.vybe.app.userDefaults.cache.facebookFriends";
NSString *const kVYBUserDefaultsActivityLastRefreshKey                  = @"com.vybe.app.userDefaults.ActivityLastRefresh";


#pragma mark - PFObject User Class
// field keys
NSString *const kVYBUserUsernameKey                             = @"username";
NSString *const kVYBUserProfilePicSmallKey                      = @"profilePictureSmall";
NSString *const kVYBUserProfilePicMediumKey                     = @"profilePictureMedium";
NSString *const kVYBUserLastVybedLocationKey                    = @"lastVybedLocation";
NSString *const kVYBUserLastVybedTimeKey                        = @"lastVybedTime";
NSString *const kVYBUserFreshFeedKey                            = @"freshFeed";


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
NSString *const kVYBVybeTribeKey                                = @"tribe";
NSString *const kVYBVybeUserKey                                 = @"user";
NSString *const kVYBVybeTimestampKey                            = @"timestamp";
NSString *const kVYBVybeGeotag                                  = @"location";
NSString *const kVYBVybeTypePublicKey                           = @"isPublic";
NSString *const kVYBVybeLocationStringKey                       = @"locationString";
NSString *const kVYBVybeCountryCodeKey                          = @"countryCode";

/*
 NSString *const kVYBVybeCountryCodeKey                          = @"countryCode";
 NSString *const kVYBVybeStateNameKey                            = @"stateName";
 NSString *const kVYBVybeCityNameKey                             = @"cityName";
*/

#pragma mark - Cached Photo Attributes
// keys
NSString *const kVYBVybeAttributesIsLikedByCurrentUserKey = @"isLikedByCurrentUser";
NSString *const kVYBVybeAttributesLikeCountKey            = @"likeCount";
NSString *const kVYBVybeAttributesLikersKey               = @"likers";
NSString *const kVYBVybeAttributesCommentCountKey         = @"commentCount";
NSString *const kVYBVybeAttributesCommentersKey           = @"commenters";

#pragma mark - PFObject Region Class
// class key
NSString *const kVYBRegionClassKey                                = @"Region";

// field keys
NSString *const kVYBRegionNameKey                                 = @"name";
NSString *const kVYBRegionTypeKey                                 = @"type";
NSString *const kVYBRegionCodeKey                                 = @"code";
NSString *const kVYBRegionThumbnailKey                            = @"thumbnail";
NSString *const kVYBRegionUnlockCountKey                          = @"unlockCount";

NSString *const kVYBRegionTypeCountryKey                          = @"country";
NSString *const kVYBRegionTypeStateKey                            = @"state";
NSString *const kVYBRegionTypeCityKey                             = @"city";


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
NSString *const kVYBTribeNewestVybeKey                          = @"newestVybe";

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

// Type values
NSString *const kVYBActivityTypeFollow                          = @"follow";
NSString *const kVYBActivityTypeLike                            = @"like";
NSString *const kVYBActivityTypeComment                         = @"comment";


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
NSString *const kVYBInstallationUserKey                         = @"user";


#pragma mark - PFPush Notification Payload Keys

NSString *const kAPNSAlertKey                                   = @"alert";
NSString *const kAPNSBadgeKey                                   = @"badge";
NSString *const kAPNSSoundKey                                   = @"sound";

NSString *const kVYBPushPayloadPayloadTypeKey                   = @"p";
NSString *const kVYBPushPayloadPayloadTypeActivityKey           = @"a";
NSString *const kVYBPushPayloadPayloadTypeVyveKey               = @"v";
NSString *const kVYBPushPayloadPayloadTypeTribeKey              = @"t";

NSString *const kVYBPushPayloadActivityTypeKey                  = @"t";
NSString *const kVYBPushPayloadActivityFollowKey                = @"f";
NSString *const kPAPPushPayloadActivityLikeKey                  = @"l";

NSString *const kVYBPushPayloadActivityFromUserObjectIdKey      = @"fu";
NSString *const kVYBPushPayloadActivityToUserObjectIdKey        = @"tu";

NSString *const kVYBPushPayloadVybeIDKey                        = @"vid";
NSString *const kVYBPushPayloadVybeUserKey                      = @"vu";
