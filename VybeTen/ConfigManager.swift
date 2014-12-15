//
//  ConfigManager.swift
//  VybeTen
//
//  Created by Jinsu Kim on 12/14/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit

private var _sharedInstance = ConfigManager()
private let _refreshInterval: NSTimeInterval = 60 * 60 * 3
struct DateSingleton {
  static var lastRefresh: NSDate? = nil
}

class ConfigManager: NSObject {
  var config: PFConfig!
  
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
        } else {
          self.config = PFConfig.currentConfig()
        }
        DateSingleton.lastRefresh = NSDate()
      }
    }
  }
  
  
}
