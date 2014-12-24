//
//  WelcomeManager.swift
//  VybeTen
//
//  Created by Jinsu Kim on 12/23/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit

private let _sharedInstance = WelcomeManager()

class WelcomeManager: NSObject {
  private var _launchOptions: [NSObject : AnyObject]!
  private let parse_setup_queue = dispatch_queue_create("com.vybe.app.welcomeManager.parse.setup.queue", DISPATCH_QUEUE_SERIAL)
  
  class var sharedInstance : WelcomeManager {
    return _sharedInstance
  }
  
  func setLaunchOptions(dictObj: NSDictionary?) {
    if let options = dictObj as? [NSObject : AnyObject] {
      _launchOptions = options
    }
  }
  
  func setUpParseEnvironment() {
    dispatch_async(parse_setup_queue, { () -> Void in
//      Parse.enableLocalDatastore()
      
      ParseCrashReporting.enable()
      
      Parse.setApplicationId(PARSE_APPLICATION_ID_DEV, clientKey: PARSE_CLIENT_KEY_DEV)
      
      // Clearing Push-noti Badge number
      var currentInstallation = PFInstallation.currentInstallation()
      if currentInstallation.badge != 0 {
        currentInstallation.badge = 0
        currentInstallation.saveEventually()
      }
      
      // Access Control
      var defaultACL = PFACL()
      // Enable public read access by default, with any newly created PFObjects belonging to the current user
      defaultACL.setPublicReadAccess(true)
      PFACL.setDefaultACL(defaultACL, withAccessForCurrentUser: true)
      
      //    // Refresh current user with server side data -- checks if user is still valid and so on
      //    [[PFUser currentUser] fetchInBackgroundWithTarget:self selector:@selector(refreshCurrentUserCallbackWithResult:error:)];
      
      
      if self._launchOptions != nil && self._launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] != nil {
        return
      } else {
        if !ConfigManager.sharedInstance.currentUserExcludedFromAnalytics() {
          PFAnalytics.trackAppOpenedWithLaunchOptionsInBackground(self._launchOptions, block: nil)
        }
      }

      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        NSNotificationCenter.defaultCenter().postNotificationName(VYBAppDelegateParseLocalDatastoreReadyNotification, object: nil)
      })
    })
  }
  
  func updateCurrentInstallationWithDeviceToken(deviceToken: NSData) {
    dispatch_async(parse_setup_queue, { () -> Void in
      var currentInstallation = PFInstallation.currentInstallation()
      currentInstallation.setDeviceTokenFromData(deviceToken)
      currentInstallation.saveEventually()
    })
  }
  
//  
//  - (void)refreshCurrentUserCallbackWithResult:(PFObject *)refreshedObject error:(NSError *)error {
//  // A kPFErrorObjectNotFound error on currentUser refresh signals a deleted user
//  if (error && error.code == kPFErrorObjectNotFound) {
//  NSLog(@"User does not exist.");
//  [(VYBAppDelegate*)[[UIApplication sharedApplication] delegate] logOut];
//  return;
//  }
//  else {
//  // Update Config file from cloud
//  [[ConfigManager sharedInstance] fetchIfNeeded];
//  
//  [self updateGoogleAnalytics];
//  
//  // Update myFlags cache
//  PFRelation *myFlags = [[PFUser currentUser] relationForKey:kVYBUserFlagsKey];
//  PFQuery *query = [myFlags query];
//  [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
//  if (!error) {
//  for (PFObject *pfObj in objects) {
//  [[VYBCache sharedCache] setAttributesForVybe:pfObj flaggedByCurrentUser:YES];
//  }
//  }
//  }];
//  
//  // Update blockedUsers cache
//  PFRelation *blockedUsers = [[PFUser currentUser] relationForKey:kVYBUserBlockedUsersKey];
//  PFQuery *userQuery = [blockedUsers query];
//  [userQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
//  if (!error) {
//  [[VYBCache sharedCache] setBlockedUsers:objects forUser:[PFUser currentUser]];
//  }
//  }];
//  
//  // Update my bumps
//  PFQuery *bumpQuery = [PFQuery queryWithClassName:kVYBActivityClassKey];
//  [bumpQuery whereKey:kVYBActivityTypeKey equalTo:kVYBActivityTypeLike];
//  [bumpQuery includeKey:kVYBActivityVybeKey];
//  [bumpQuery whereKey:kVYBActivityFromUserKey equalTo:[PFUser currentUser]];
//  [bumpQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
//  if (!error) {
//  for (PFObject *activity in objects) {
//  [[VYBCache sharedCache] setAttributesForVybe:activity[kVYBActivityVybeKey] likers:@[[PFUser currentUser]] commenters:nil likedByCurrentUser:YES];
//  }
//  }
//  }];
//  }
//  }
//  
//  - (void)updateGoogleAnalytics {
//  #ifdef DEBUG
//  #else
//  // GA stuff - Setting User ID
//  id tracker = [[GAI sharedInstance] defaultTracker];
//  if (tracker) {
//  [tracker set:@"&uid" value:[PFUser currentUser].username];
//  [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"UX"
//  action:@"User Logged In"
//  label:nil
//  value:nil] build]];
//  // GA stuff - User Group Dimension
//  if ([[ConfigManager sharedInstance] currentUserExcludedFromAnalytics]) {
//  NSString *tribeName = @"Founders";
//  [tracker set:[GAIFields customDimensionForIndex:2] value:tribeName];
//  }
//  else {
//  NSString *tribeName = @"Beta Users";
//  [tracker set:[GAIFields customDimensionForIndex:2] value:tribeName];
//  }
//  }
//  #endif
//  }

}
