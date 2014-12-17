//
//  ConfigManager.swift
//  VybeTen
//
//  Created by Jinsu Kim on 12/14/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit

private var _sharedInstance = ConfigManager()
//private let _refreshInterval: NSTimeInterval = 60 * 60 * 3
private let _refreshInterval: NSTimeInterval = 0
struct DateSingleton {
  static var lastRefresh: NSDate? = nil
}

class ConfigManager: NSObject {
  var config: PFConfig?
  
  class var sharedInstance: ConfigManager {
    return _sharedInstance;
  }
  
  override init() {
    super.init()
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "fetchIfNeeded", name: UIApplicationWillEnterForegroundNotification, object: nil)
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
  }
  
  func fetchIfNeeded() {
    let lastRefreshDate: NSDate? = DateSingleton.lastRefresh
    
    if lastRefreshDate == nil || lastRefreshDate!.timeIntervalSinceNow * -1.0 > _refreshInterval {
      PFConfig.getConfigInBackgroundWithBlock { (config: PFConfig!, error: NSError!) -> Void in
        if error == nil {
          self.config = config
        }
        else {
          self.config = PFConfig.currentConfig()
        }
        DateSingleton.lastRefresh = NSDate()
      }
    }
  }
  
  func featuredZoneID() -> String? {
    if let zoneID = self.config?["featuredZoneID"] as? String {
      return zoneID
    }
    
    // New City Gas
    return "4f722440e4b0995f2face125"
  }
  
  func currentUserExcludedFromAnalytics() -> Bool {
    let currConfig = PFConfig.currentConfig()
    var founders: [String]
    if let array = currConfig["founders"] as? [String] {
      founders = array
    }
    else {
      founders = ["jart", "W7", "mo", "Boodi", "jinsu", "solomon"]
    }
    for username in founders {
      if let currUser = PFUser.currentUser() {
        if let currUsername = currUser.objectForKey(kVYBUserUsernameKey) as? String {
          if currUsername == username {
            return true
          }
        }
      }
      else {
        // no currentUser at this time so exclude it
        return true
      }
    }
    
    return false
  }
}
