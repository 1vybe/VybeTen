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

struct FeaturedChannel {
  var eventName: String
  var zoneID: String
  var fromDate: NSDate
  var toDate: NSDate
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
  
  func customZones() -> [Zone]? {
    var customZones: [Zone]?
    if let configObj = self.config?["customZones"] as? [String: AnyObject] {
      if let listObj = configObj["customZones"] as? [AnyObject] {
        for zObj in listObj {
          if let zName = zObj["name"] as? String {
            if let zID = zObj["id"] as? String {
              var zone = Zone(name: zName, zoneID: zID)
              if let lat = zObj["latitude"] as? NSNumber {
                if let lng = zObj["longitude"] as? NSNumber {
                  let zCoord = CLLocationCoordinate2D(latitude: lat.doubleValue, longitude: lng.doubleValue)
                  zone.coordinate = zCoord
                }
              }
              
              if customZones == nil {
                customZones = [zone]
              } else {
                customZones = customZones! + [zone]
              }
            }
          }
        }
      }
    }
    
    return customZones
  }
  
  func currentUserExcludedFromAnalytics() -> Bool {
    let currConfig = PFConfig.currentConfig()
    var founders: [String]
    if let array = currConfig["founders"] as? [String] {
      founders = array
    }
    else {
      founders = ["jart", "W7", "mo", "Boodi", "solomon"]
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
  
  func startTimeForMap() -> NSDate {
    if let timestamp = PFConfig.currentConfig().objectForKey("startTimeForMap") as? NSDate {
      return timestamp
    } else {
      // By default everything within the past week
      let aWeekAgo = NSDate(timeIntervalSinceNow: -1 * 60 * 60 * 24 * 7)
      return aWeekAgo
    }
  }
  
  func activeTTL() -> NSTimeInterval? {
    if let ttl = PFConfig.currentConfig().objectForKey("activeTTL") as? Double {
      return ttl
    }
    return nil
  }
}
