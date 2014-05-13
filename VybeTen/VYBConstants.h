//
//  VYBConstants.h
//  VybeTen
//
//  Created by jinsuk on 3/8/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//


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


#pragma mark - Cached User Attributes
// keys
extern NSString *const kVYBUserAttributesPhotoCountKey;
extern NSString *const kVYBUserAttributesIsFollowedByCurrentUserKey;

#pragma mark - PFObject User Class
// Field keys
extern NSString *const kVYBUserDisplayNameKey;
extern NSString *const kVYBUserFacebookIDKey;
extern NSString *const kVYBUserPhotoIDKey;
extern NSString *const kVYBUserProfilePicSmallKey;
extern NSString *const kVYBUserProfilePicMediumKey;
extern NSString *const kVYBUserFacebookFriendsKey;
extern NSString *const kVYBUserAlreadyAutoFollowedFacebookFriendsKey;


@interface VYBConstants : NSObject
@end
