//
//  VYBConstants.h
//  VybeTen
//
//  Created by jinsuk on 3/8/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//
#define IS_IPHONE_5     ( [[UIScreen mainScreen] bounds].size.height == 568 )

#define ACCESS_KEY_ID   @"AKIAJVN4HPJ6VBOKP7XA"
#define SECRET_KEY      @"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"
#define BUCKET_NAME     @"amino"

#define UPFRESH         1
#define UPLOADING       2
#define UPLOADED        3

#define DOWNFRESH       1
#define DOWNLOADING     2
#define DOWNLOADED      3

#define HOCKEY_APP_ID   @"f6bbe32e11800913add864bbd07ebcee"

#define FONT_SIZE_DEFAULT       18
#define FONT_SIZE_BIG           20
#define FONT_SIZE_SMALL         16
#define DEFAULT_FONT(s)         [UIFont fontWithName:@"Montreal-Xlight" size:s]
#define FONT_MENU               DEFAULT_FONT(FONT_SIZE_BIG)
#define FONT_TITLE              DEFAULT_FONT(FONT_SIZE_DEFAULT)
#define FONT_TITLE_SMALL        DEFAULT_FONT(FONT_SIZE_SMALL)


#pragma mark - NSNotification
extern NSString *const VYBAppDelegateApplicationDidReceiveRemoteNotification;
extern NSString *const VYBSyncViewControllerDidChangeSyncTribe;


#pragma mark - NSUserDefaults
extern NSString *const kVYBUserDefaultsCacheFacebookFriendsKey;


#pragma mark - PFObject User Class
// field keys
extern NSString *const kVYBUserDisplayNameKey;
extern NSString *const kVYBUserFacebookIDKey;
extern NSString *const kVYBUserProfilePicSmallKey;
extern NSString *const kVYBUserProfilePicMediumKey;
extern NSString *const kVYBUserFacebookFriendsKey;


#pragma mark - PFObject Vybe Class
// class key
extern NSString *const kVYBVybeClassKey;

// field keys
extern NSString *const kVYBVybeVideoKey;
extern NSString *const kVYBVybeThumbnailKey;
extern NSString *const kVYBVybeTribeKey;
extern NSString *const kVYBVybeUserKey;
extern NSString *const kVYBVybeTimestampKey;
extern NSString *const kVYBVybeGeotag;


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
extern NSString *const kVYBTribeThumbnailKey;


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
extern NSString *const kVYBActivityTypeJoined;

#pragma mark - Cached User Attributes
// keys
extern NSString *const kVYBUserAttributesSyncTribeKey;
extern NSString *const kVYBUserAttributesVybeCountKey;
extern NSString *const kVYBUserAttributesTribeCountKey;
extern NSString *const kVYBUserAttributesIsFollowedByCurrentUserKey;
extern NSString *const kVYBUserAttributesTribesKey;

#pragma mark - Cached Tribe Attributes
// keys
extern NSString *const kVYBTribeAttributesVybeCountKey;
extern NSString *const kVYBTribeAttributesMemberCountKey;
extern NSString *const kVYBTribeAttributesMembersKey;
extern NSString *const kVYBTribeAttributesLastWatchedVybeKey;


#pragma mark - Installation Class

// Field keys
extern NSString *const kVYBInstallationUserKey;

@interface VYBConstants : NSObject
@end
