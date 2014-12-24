//
//  VYBWelcomeViewController.m
//  VybeTen
//
//  Created by Mohammed Tangestani on 2014-10-08.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBWelcomeViewController.h"
#import "VYBAppDelegate.h"
#import "VYBUtility.h"
#import "VYBCache.h"

#import "VybeTen-Swift.h"

@implementation VYBWelcomeViewController

#pragma mark - Lifecycle

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBAppDelegateParseLocalDatastoreReadyNotification object:nil];
}

- (void)loadView {
  UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
  [backgroundImageView setImage:[UIImage imageNamed:@"Default.png"]];
  self.view = backgroundImageView;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(welcomeUser) name:VYBAppDelegateParseLocalDatastoreReadyNotification object:nil];
  
  // Parse Initialization
  [[WelcomeManager sharedInstance] setUpParseEnvironment];
}

- (void)welcomeUser {
  // If not logged in, present login view controller
  if (![PFUser currentUser]) {
    [(VYBAppDelegate*)[[UIApplication sharedApplication] delegate] presentFirstPage];
    return;
  } else {
    [(VYBAppDelegate*)[[UIApplication sharedApplication] delegate] proceedToMainInterface];
    // Refresh current user with server side data -- checks if user is still valid and so on
    [[PFUser currentUser] fetchInBackgroundWithTarget:self selector:@selector(refreshCurrentUserCallbackWithResult:error:)];
  }
}

#pragma mark - Private

- (void)refreshCurrentUserCallbackWithResult:(PFObject *)refreshedObject error:(NSError *)error {
  // A kPFErrorObjectNotFound error on currentUser refresh signals a deleted user
  if (error && error.code == kPFErrorObjectNotFound) {
    NSLog(@"User does not exist.");
    [(VYBAppDelegate*)[[UIApplication sharedApplication] delegate] logOut];
    return;
  }
  else {
    // Update Config file from cloud
    [[ConfigManager sharedInstance] fetchIfNeeded];
    
    [self updateGoogleAnalytics];
    
    // Update myFlags cache
    PFRelation *myFlags = [[PFUser currentUser] relationForKey:kVYBUserFlagsKey];
    PFQuery *query = [myFlags query];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
      if (!error) {
        for (PFObject *pfObj in objects) {
          [[VYBCache sharedCache] setAttributesForVybe:pfObj flaggedByCurrentUser:YES];
        }
      }
    }];
    
    // Update blockedUsers cache
    PFRelation *blockedUsers = [[PFUser currentUser] relationForKey:kVYBUserBlockedUsersKey];
    PFQuery *userQuery = [blockedUsers query];
    [userQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
      if (!error) {
        [[VYBCache sharedCache] setBlockedUsers:objects forUser:[PFUser currentUser]];
      }
    }];
    
    // Update my bumps
    PFQuery *bumpQuery = [PFQuery queryWithClassName:kVYBActivityClassKey];
    [bumpQuery whereKey:kVYBActivityTypeKey equalTo:kVYBActivityTypeLike];
    [bumpQuery includeKey:kVYBActivityVybeKey];
    [bumpQuery whereKey:kVYBActivityFromUserKey equalTo:[PFUser currentUser]];
    [bumpQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
      if (!error) {
        for (PFObject *activity in objects) {
          [[VYBCache sharedCache] setAttributesForVybe:activity[kVYBActivityVybeKey] likers:@[[PFUser currentUser]] commenters:nil likedByCurrentUser:YES];
        }
      }
    }];
  }
}

- (void)updateGoogleAnalytics {
#ifdef DEBUG
#else
  // GA stuff - Setting User ID
  id tracker = [[GAI sharedInstance] defaultTracker];
  if (tracker) {
    [tracker set:@"&uid" value:[PFUser currentUser].username];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"UX"
                                                          action:@"User Logged In"
                                                           label:nil
                                                           value:nil] build]];
    // GA stuff - User Group Dimension
    if ([[ConfigManager sharedInstance] currentUserExcludedFromAnalytics]) {
      NSString *tribeName = @"Founders";
      [tracker set:[GAIFields customDimensionForIndex:2] value:tribeName];
    }
    else {
      NSString *tribeName = @"Beta Users";
      [tracker set:[GAIFields customDimensionForIndex:2] value:tribeName];
    }
  }
#endif
}

@end