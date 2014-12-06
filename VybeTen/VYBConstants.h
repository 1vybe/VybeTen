//
//  VYBConstants.h
//  VybeTen
//
//  Created by jinsuk on 3/8/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//
#define IS_IPHONE_5     ( [[UIScreen mainScreen] bounds].size.height == 568 )

#define VYBE_LENGTH_SEC 15
#define VYBE_TTL_HOURS  24
#define UPFRESH         1
#define UPLOADING       2
#define UPLOADED        3

#define DOWNFRESH       1
#define DOWNLOADING     2
#define DOWNLOADED      3


/* House */
#define PARSE_APPLICATION_ID        @"gYVd0gSQavfnxcvIyFhns8j0KKyp0XHekKdrjJkC"
#define PARSE_CLIENT_KEY            @"6y6eMRZq5GAa5ihS2GSjFB0xwmnuatvuJBhYQ1Af"
#define HOCKEY_APP_ID               @"66e11a95d2af956652e5f4efa38af51e"
#define GA_TRACKING_ID              @"UA-49584125-4"

/* WORLD
#define GA_TRACKING_ID              @"UA-49584125-3"
#define PARSE_APPLICATION_ID        @"m5Im7uDcY5rieEbPyzRfV2Dq6YegS3kAQwxiDMFZ"
#define PARSE_CLIENT_KEY            @"WLqeqlf4qVVk5jF6yHSWGxw3UzUQwUtmAk9vCPfB"
*/

#define COLOR_MAIN              [UIColor colorWithRed:255.0/255.0 green:81.0/255.0 blue:81.0/255.0 alpha:1]
#define COLOR_LOC_NAME_LABEL    [UIColor colorWithRed:76.0/255.0 green:76.0/255.0 blue:76.0/255.0 alpha:1]
#define COLOR_CONTROL_BG        [UIColor colorWithRed:224.0/255.0 green:224.0/255.0 blue:224.0/255.0 alpha:1]
#define COLOR_CONTROL_LINE      [UIColor colorWithRed:157.0/255.0 green:157.0/255.0 blue:157.0/255.0 alpha:1]


#define FONT_SIZE_DEFAULT       18
#define FONT_SIZE_BIG           20
#define FONT_SIZE_SMALL         16
#define DEFAULT_FONT(s)         [UIFont fontWithName:@"Montreal-Xlight" size:s]
#define FONT_MENU               DEFAULT_FONT(FONT_SIZE_BIG)
#define FONT_LOC_NAME_LABEL     DEFAULT_FONT(FONT_SIZE_DEFAULT)
#define FONT_TITLE_SMALL        DEFAULT_FONT(FONT_SIZE_SMALL)


typedef enum {
    VYBCapturePageIndex = 0,
    VYBActivityPageIndex = 1
} VYBPageControllerIndex;

typedef enum {
  CurrentUploadStatusIdle = 0,
  CurrentUploadStatusUploading,
  CurrentUploadStatusFailed,
  CurrentUploadStatusSuccess
} CurrentUploadStatus;


#pragma mark - NSNotification
extern NSString *const VYBAppDelegateApplicationDidReceiveRemoteNotification;
extern NSString *const VYBAppDelegateApplicationDidBecomeActiveNotification;
extern NSString *const VYBAppDelegateApplicationDidEnterBackgourndNotification;
extern NSString *const VYBFreshVybeFeedFetchedFromRemoteNotification;
extern NSString *const VYBUtilityVybesLoadedNotification;
extern NSString *const VYBCacheFreshVybeCountChangedNotification;
extern NSString *const VYBUtilityActivityCountUpdatedNotification;
extern NSString *const VYBUtilityUserLikedUnlikedVybeCallbackFinishedNotification;
extern NSString *const VYBMyVybeStoreLocationFetchedNotification;


#pragma mark - NSUserDefaults
extern NSString *const kVYBUserDefaultsCacheFacebookFriendsKey;
extern NSString *const kVYBUserDefaultsActivityLastRefreshKey;

extern NSString *const kVYBUserDefaultsNotificationPermissionKey;
extern NSString *const kVYBUserDefaultsNotificationPermissionUndeterminedKey;
extern NSString *const kVYBUserDefaultsNotificationPermissionDeniedKey;
extern NSString *const kVYBUserDefaultsNotificationPermissionGrantedKey;

extern NSString *const kVYBUserDefaultsAudioAccessPermissionKey;
extern NSString *const kVYBUserDefaultsAudioAccessPermissionDeniedKey;
extern NSString *const kVYBUserDefaultsAudioAccessPermissionUndeterminedKey;
extern NSString *const kVYBUserDefaultsAudioAccessPermissionGrantedKey;

extern NSString *const kVYBUserDefaultsVideoAccessPermissionKey;
extern NSString *const kVYBUserDefaultsVideoAccessPermissionDeniedKey;
extern NSString *const kVYBUserDefaultsVideoAccessPermissionUndeterminedKey;
extern NSString *const kVYBUserDefaultsVideoAccessPermissionGrantedKey;


#pragma mark - PFObject User Class
// field keys
extern NSString *const kVYBUserUsernameKey;
extern NSString *const kVYBUserProfilePicSmallKey;
extern NSString *const kVYBUserProfilePicMediumKey;
extern NSString *const kVYBUserLastVybedZoneKey;
extern NSString *const kVYBUserLastVybedTimeKey;
extern NSString *const kVYBUserFreshFeedKey;
extern NSString *const kVYBUserLastRefreshedKey;
extern NSString *const kVYBUserBlockedUsersKey;
extern NSString *const kVYBUserTermsAgreedKey;
extern NSString *const kVYBUserTribeKey;



#pragma mark - PFObject Vybe Class
// class key
extern NSString *const kVYBVybeClassKey;

// field keys
extern NSString *const kVYBVybeVideoKey;
extern NSString *const kVYBVybeThumbnailKey;
extern NSString *const kVYBVybeUserKey;
extern NSString *const kVYBVybeTimestampKey;
extern NSString *const kVYBVybeGeotag;
extern NSString *const kVYBVybeTypePublicKey;
extern NSString *const kVYBVybeLocationStringKey;
extern NSString *const kVYBVybeCountryCodeKey;
extern NSString *const kVYBVybeTagKey;
extern NSString *const kVYBVybeZoneNameKey;
extern NSString *const kVYBVybeZoneIDKey;
extern NSString *const kVYBVybeZoneLatitudeKey;
extern NSString *const kVYBVybeZoneLongitudeKey;
/*
extern NSString *const kVYBVybeTribeKey;
extern NSString *const kVYBVybeCountryCodeKey;
extern NSString *const kVYBVybeStateNameKey;
extern NSString *const kVYBVybeCityNameKey;
*/

#pragma mark - Cached Vybe Attributes
// keys
extern NSString *const kVYBVybeAttributesIsLikedByCurrentUserKey;
extern NSString *const kVYBVybeAttributesLikeCountKey;
extern NSString *const kVYBVybeAttributesLikersKey;
extern NSString *const kVYBVybeAttributesCommentCountKey;
extern NSString *const kVYBVybeAttributesCommentersKey;
extern NSString *const kVYBVybeAttributesNearbyCountKey;


#pragma mark - PFObject Region Class
// class key
extern NSString *const kVYBRegionClassKey;

// field keys
extern NSString *const kVYBRegionNameKey;
extern NSString *const kVYBRegionTypeKey;
extern NSString *const kVYBRegionCodeKey;
extern NSString *const kVYBRegionThumbnailKey;
extern NSString *const kVYBRegionUnlockCountKey;

extern NSString *const kVYBRegionTypeCountryKey;
extern NSString *const kVYBRegionTypeStateKey;
extern NSString *const kVYBRegionTypeCityKey;

#pragma mark - PFObject Tribe Class
// class key
extern NSString *const kVYBTribeClassKey;

// field keys
extern NSString *const kVYBTribeNameKey;
extern NSString *const kVYBTribeCreatorKey;
extern NSString *const kVYBTribeTypeKey;
extern NSString *const kVYBTribeVybeCountKey;
extern NSString *const kVYBTribeMembersCountKey;
extern NSString *const kVYBTribeMembersKey;
extern NSString *const kVYBTribeNewestVybeKey;

// type values
extern NSString *const kVYBTribeTypePrivate;
extern NSString *const kVYBTribeTypePublic;


#pragma mark - PFObject Activity Class
// Class key
extern NSString *const kVYBActivityClassKey;

// Field keys
extern NSString *const kVYBActivityTypeKey;
extern NSString *const kVYBActivityFromUserKey;
extern NSString *const kVYBActivityToUserKey;
extern NSString *const kVYBActivityContentKey;
extern NSString *const kVYBActivityVybeKey;

// Type values
extern NSString *const kVYBActivityTypeFollow;
extern NSString *const kVYBActivityTypeLike;
extern NSString *const kVYBActivityTypeComment;

#pragma mark - Cached User Attributes
// keys
extern NSString *const kVYBUserAttributesSyncTribeKey;
extern NSString *const kVYBUserAttributesVybeCountKey;
extern NSString *const kVYBUserAttributesTribeCountKey;
extern NSString *const kVYBUserAttributesIsFollowedByCurrentUserKey;


#pragma mark - Cached Tribe Attributes
// keys
extern NSString *const kVYBTribeAttributesLastWatchedVybeKey;
extern NSString *const kVYBTribeAttributesVybeCountKey;
extern NSString *const kVYBTribeAttributesMemberCountKey;
extern NSString *const kVYBTribeAttributesMembersKey;
extern NSString *const kVYBUserAttributesTribesKey;


#pragma mark - Installation Class
// Field keys
extern NSString *const kVYBInstallationUserKey;


#pragma mark - PFPush Notification Payload Keys

extern NSString *const kAPNSAlertKey;
extern NSString *const kAPNSBadgeKey;
extern NSString *const kAPNSSoundKey;

extern NSString *const kVYBPushPayloadPayloadTypeKey;
extern NSString *const kVYBPushPayloadPayloadTypeActivityKey;
extern NSString *const kVYBPushPayloadPayloadTypeVyveKey;
extern NSString *const kVYBPushPayloadPayloadTypeTribeKey;

extern NSString *const kVYBPushPayloadActivityTypeKey;
extern NSString *const kVYBPushPayloadActivityFollowKey;
extern NSString *const kPAPPushPayloadActivityLikeKey;

extern NSString *const kVYBPushPayloadActivityFromUserObjectIdKey;
extern NSString *const kVYBPushPayloadActivityToUserObjectIdKey;

extern NSString *const kVYBPushPayloadVybeIDKey;
extern NSString *const kVYBPushPayloadVybeUserKey;


@interface VYBConstants : NSObject
@end
