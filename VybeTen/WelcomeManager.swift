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
  private var _launchOptions: [NSObject : AnyObject]?
  private let parse_setup_queue = dispatch_queue_create("com.vybe.app.welcomeManager.parse.setup.queue", DISPATCH_QUEUE_SERIAL)
  
  class var sharedInstance : WelcomeManager {
    return _sharedInstance
  }
  
  func setLaunchOptions(dictObj: NSDictionary!) {
    if dictObj != nil {
      _launchOptions = dictObj as [NSObject : AnyObject]
    }
  }
  
  func launchOptions() -> [NSObject : AnyObject]? {
    return _launchOptions
  }
  
  func setUpParseEnvironment() {
    dispatch_async(parse_setup_queue, { () -> Void in
      Parse.enableLocalDatastore()
      
      ParseCrashReporting.enable()
      
      Parse.setApplicationId(PARSE_APPLICATION_ID_DEV, clientKey: PARSE_CLIENT_KEY_DEV)
      
      // Clearing Push-noti Badge number
      var currentInstallation = PFInstallation.currentInstallation()
      if currentInstallation.badge != 0 {
        currentInstallation.badge = 0
        currentInstallation.saveEventually(nil)
      }
      
      // Access Control
      var defaultACL = PFACL()
      // Enable public read access by default, with any newly created PFObjects belonging to the current user
      defaultACL.setPublicReadAccess(true)
      PFACL.setDefaultACL(defaultACL, withAccessForCurrentUser: true)
      
      if self._launchOptions != nil && self._launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] != nil {
        return
      } else {
        if !ConfigManager.sharedInstance.currentUserExcludedFromAnalytics() {
          PFAnalytics.trackAppOpenedWithLaunchOptionsInBackground(self._launchOptions, block: nil)
        }
      }
    })
  }
  
  func checkLogInStatus() {
    dispatch_async(parse_setup_queue, { () -> Void in
      if PFUser.currentUser() == nil {
        if let vybeAppDelegate = UIApplication.sharedApplication().delegate as? VYBAppDelegate {
          dispatch_async(dispatch_get_main_queue(), { () -> Void in
            vybeAppDelegate.presentFirstPageViewControllerAnimated(true)
          })
        }
      } else {
        PFUser.currentUser().fetchInBackgroundWithTarget(self, selector: ("fetchCurrentUserDataWithResult:error:"))
      }
    })
  }
  
  func updateCurrentInstallationWithDeviceToken(deviceToken: NSData) {
    dispatch_async(parse_setup_queue, { () -> Void in
      var currentInstallation = PFInstallation.currentInstallation()
      currentInstallation.setDeviceTokenFromData(deviceToken)
      currentInstallation.saveEventually(nil)
    })
  }
  
  func fetchCurrentUserDataWithResult(userObj: AnyObject, error: NSError!) {
    if error != nil {
      if error.code == kPFErrorObjectNotFound {
        if let vybeAppDel = UIApplication.sharedApplication().delegate as? VYBAppDelegate {
          vybeAppDel.logOut()
        }
        return
      }
    } else {
      // NOTE: - a break point here causes a crash
      // Update config file from cloud
      ConfigManager.sharedInstance.fetchIfNeeded()
      
      // Update Google Analytics
      self.updateGoogleAnalytics()
      
      // Clear feed that was stored LOCALLY from last session
      PFObject.unpinAllObjectsInBackgroundWithName("MyFreshFeed", block: nil)
      
      // Reset all user list
      PFObject.unpinAllObjectsInBackgroundWithName("AllOtherUsers", block: { (success: Bool, error: NSError!) -> Void in
        let query = PFUser.query()
        query.whereKey(kVYBUserUsernameKey, notEqualTo:userObj[kVYBUserUsernameKey])
        query.findObjectsInBackgroundWithBlock({ (result: [AnyObject]!, error: NSError!) -> Void in
          if result != nil {
            PFObject.pinAllInBackground(result, withName: "AllOtherUsers", block: { (success: Bool, error: NSError!) -> Void in
              if let vybeAppDelegate = UIApplication.sharedApplication().delegate as? VYBAppDelegate {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                  vybeAppDelegate.proceedToMainInterface()
                })
              }
            })
          }
        })
      })
      
      // Update myFlags cache
      let myFlags = PFUser.currentUser().relationForKey(kVYBUserFlagsKey)
      var flagQuery = myFlags.query()
      flagQuery.findObjectsInBackgroundWithBlock({ (result: [AnyObject]!, error: NSError!) -> Void in
        if error == nil {
          for vybeObj in result as! [PFObject] {
            VYBCache.sharedCache().setAttributesForVybe(vybeObj, flaggedByCurrentUser: true)
          }
        }
      })
      
      // Update blockedUsers cache
      let blockedUsers = PFUser.currentUser().relationForKey(kVYBUserBlockedUsersKey)
      var blockQuery = blockedUsers.query()
      blockQuery.findObjectsInBackgroundWithBlock({ (result: [AnyObject]!, error: NSError!) -> Void in
        if error == nil {
          VYBCache.sharedCache().setBlockedUsers(result, forUser: PFUser.currentUser())
        }
      })
    }
  }
  
  func updateGoogleAnalytics() {
#if DEBUG
#else
    if let tracker = GAI.sharedInstance().defaultTracker {
      tracker.set("&uid", value: PFUser.currentUser().username)
      tracker.send(GAIDictionaryBuilder.createEventWithCategory("UX", action: "User Logged In", label: nil, value: nil).build() as [NSObject : AnyObject])
      
      if ConfigManager.sharedInstance.currentUserExcludedFromAnalytics() {
        let tribeName = "Founders"
        tracker.set(GAIFields.customDimensionForIndex(2), value: tribeName)
      } else {
        let tribeName = "Beta Users"
        tracker.set(GAIFields.customDimensionForIndex(2), value: tribeName)
      }
    }
#endif
  }

}
