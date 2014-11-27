//
//  ZoneStore.swift
//  VybeTen
//
//  Created by jinsuk on 11/6/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit

private let _zoneStoreSharedInstance = ZoneStore()

@objc class ZoneStore: NSObject {
  private var _activeZones = [Zone]()
  private var _unlockedZones = [Zone]() // unlocked zones group my vybes
  
  class var sharedInstance: ZoneStore {
    return _zoneStoreSharedInstance
  }
  
  func fetchActiveVybes(completionHandler: ((success: Bool) -> Void)) {
    // First clear cache
    //_activeZones = [Zone]()
    
    // Fetch ACTIVE zones
    let params = [:]
    PFCloud.callFunctionInBackground("get_active_vybes", withParameters:params) { (result: AnyObject!, error: NSError!) -> Void in
      if error == nil {
        let vybeObjects = result as [PFObject]
        // Group ACTIVE vybes into zones
        self.createActiveZonesFromVybes(vybeObjects)
        
        // Mark active zones as UNLOCKED
        self.unlockActiveZones()
        
        // Rearrange UNLOCKED zones by your most recent vybe timestamp
        self._unlockedZones.sort({ (zone1: Zone, zone2: Zone) -> Bool in
          let comparisonResult = zone1.myMostRecentVybeTimestamp.compare(zone2.myMostRecentVybeTimestamp)
          return comparisonResult == NSComparisonResult.OrderedDescending
        })
        
        // Fetch Fresh vybes for ACTIVE zones
        PFCloud.callFunctionInBackground("get_fresh_vybes", withParameters: params) { (result: AnyObject!, error: NSError!) -> Void in
          if error == nil {
            if let freshVybes = result as? [PFObject] {
              for fVybe in freshVybes {
                if let zone = self.activeZoneForVybe(fVybe) {
                  zone.addFreshVybe(fVybe)
                }
              }
              
              // Rearrange ACTIVE zones first by number of unwatched vybes and by most recent time
              self._activeZones.sort({ (zone1: Zone, zone2: Zone) -> Bool in
                if (zone1.freshContents.count == zone2.freshContents.count) {
                  let comparisonResult = zone1.mostRecentActiveVybeTimestamp.compare(zone2.mostRecentActiveVybeTimestamp)
                  return comparisonResult == NSComparisonResult.OrderedDescending
                }
                return zone1.freshContents.count > zone2.freshContents.count
              })
              
//              self.displayZoneInfo()
            }
          }
          completionHandler(success: true)
        }
      }
      else {
        completionHandler(success: false)
      }
    }
  }
  
  func didFetchUnlockedVybes(result: [AnyObject]!, completionHandler: ((success: Bool) -> Void)!) {
    // First clear cache
    _unlockedZones = [Zone]()
    
    if let vybes = result as? [PFObject] {
      // First Group UNLOCKED zones
      self.createUnlockedZonesFromVybes(vybes)
      
      self.fetchActiveVybes(completionHandler)
    }
    else {
      completionHandler(success: false)
    }
  }

  private func createUnlockedZonesFromVybes(result: [PFObject]) {
    for aVybe in result {
      self.putUnlockedVybeIntoZone(aVybe)
    }
  }
  
  private func putUnlockedVybeIntoZone(aVybe: PFObject) {
    if let zone = self.unlockedZoneForVybe(aVybe) {
      zone.addMyVybe(aVybe)
    }
    else {
      let zone = self.createZoneFromVybe(aVybe)
      zone.addMyVybe(aVybe)
      self.addUnlockedZone(zone)
    }
  }
  
  private func unlockedZoneForVybe(aVybe: PFObject) -> Zone? {
    var zoneID = "777"
    if let zID = aVybe[kVYBVybeZoneIDKey] as? String {
      zoneID = zID;
    }
    
    for uZone in _unlockedZones {
      if uZone.zoneID == zoneID {
        return uZone
      }
    }
    
    return nil
  }
  
  private func unlockedZoneForVybe(aVybe: VYBVybe) -> Zone? {
    let parseVybe = aVybe.parseObject()
    return self.unlockedZoneForVybe(parseVybe)
  }

  private func addUnlockedZone(zone: Zone) {
    _unlockedZones += [zone]
  }
  
  private func createActiveZonesFromVybes(vybes: [PFObject]) {
    for aVybe in vybes {
      self.putActiveVybeIntoZone(aVybe)
    }
    // We use the least active vybe time because later we want to remove old active zones
    var newActiveZones = [Zone]()
    if let leastActiveVybe = vybes.first {
      if let leastActiveTime = leastActiveVybe[kVYBVybeTimestampKey] as? NSDate {
        for aZone in _activeZones {
          let result = aZone.mostRecentActiveVybeTimestamp.compare(leastActiveTime)
          if result == NSComparisonResult.OrderedDescending {
            newActiveZones += [aZone]
          }
        }
      }
    }
    
    _activeZones = newActiveZones
  }
  
  private func putActiveVybeIntoZone(aVybe: PFObject) {
    // Zone exists. Only update popularity
    if let zone = self.activeZoneForVybe(aVybe) {
      zone.addActiveVybe(aVybe)
    }
        // Vybe comes from a new zone. Create a new zone
    else {
      let zone = self.createZoneFromVybe(aVybe)
      zone.addActiveVybe(aVybe)
      self.addActiveZone(zone)
    }
  }
  
  private func activeZoneForVybe(aVybe: PFObject) -> Zone? {
    var zoneID = "777"
    
    if aVybe[kVYBVybeZoneIDKey] != nil {
      zoneID = aVybe[kVYBVybeZoneIDKey] as String
    }
    
    for aZone in _activeZones {
      if aZone.zoneID == zoneID {
        return aZone
      }
    }
    
    return nil
  }

  private func addActiveZone(zone: Zone) {
    _activeZones += [zone]
  }

  private func unlockActiveZones() {
    for aZone in _activeZones {
      for uZone in _unlockedZones {
        if (uZone.zoneID == aZone.zoneID) {
          aZone.unlocked = true
        }
      }
    }
  }
  
  private func createZoneFromVybe(aVybe: PFObject) -> Zone {
    var zone: Zone!
    
    if let zoneID = aVybe[kVYBVybeZoneIDKey] as? String {
      let zoneName = aVybe[kVYBVybeZoneNameKey] as String
      zone = Zone(name: zoneName, zoneID: zoneID)
      var coordinate = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
      
      if let zLat = aVybe[kVYBVybeZoneLatitudeKey] as? Double {
        let zLng = aVybe[kVYBVybeZoneLongitudeKey] as Double
        coordinate = CLLocationCoordinate2D(latitude: zLat, longitude: zLng)
      }
      else {
        if let geoPoint = aVybe[kVYBVybeGeotag] as? PFGeoPoint {
            coordinate = CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
        }
      }
      
      zone.coordinate = coordinate
    }
    else {
      zone = Zone(name: "Earth", zoneID: "777")
    }
    
    zone.unlocked = false
    
    return zone
  }
  
  private func createZoneFromVybe(aVybe: VYBVybe) -> Zone {
    let parseObj = aVybe.parseObject()
    return self.createZoneFromVybe(parseObj)
  }

  

  func unlockedZones() -> [Zone]! {
    return _unlockedZones
  }

  func activeZones() -> [Zone]! {
    return _activeZones
  }
  
  func activeUnlockedZones() -> [Zone]! {
    var activeUnlockedZones = [Zone]()
    for aZone in _activeZones {
      if aZone.unlocked {
        activeUnlockedZones.append(aZone)
      }
    }
    return activeUnlockedZones
  }
  
  func refreshFreshVybesInBackground(completionHandler: ((success: Bool) -> Void)) {
    // Fetch Fresh vybes for ACTIVE zones
    PFCloud.callFunctionInBackground("get_fresh_vybes", withParameters: [:]) { (result: AnyObject!, error: NSError!) -> Void in
      if error == nil {
        if let freshVybes = result as? [PFObject] {
          for fVybe in freshVybes {
            if let zone = self.activeZoneForVybe(fVybe) {
              zone.addFreshVybe(fVybe)
            }
          }
        }
        completionHandler(success: true)
      }
      else {
        completionHandler(success: false)
      }
    }
  }
  
  func freshVybesFromZone(zoneID: String) -> [PFObject]? {
    for aZone in _activeZones {
      if aZone.zoneID == zoneID {
        return aZone.freshContents
      }
    }
    return nil
  }

  func removeWatchedFromFreshFeed(aVybe: AnyObject!) {
    if let dVybe = aVybe as? PFObject  {
      var zoneID = "777"
      
      if let zID = aVybe.objectForKey(kVYBVybeZoneIDKey) as String! {
        zoneID = zID
      }
      
      for aZone in _activeZones {
        if aZone.zoneID == zoneID {
          // First update(remove) freshContents for the corresponding Zone
          aZone.removeFromFreshContents(dVybe)
          // Update watchedContents to prevent from receiving stale contents (watched but not removed from cloud) in next refresh
          aZone.addWatchedContent(dVybe)
          break
        }
      }
    }
  }
  
  func addSavedVybesToUnlockedZones() {
    if let savedVybes = VYBMyVybeStore.sharedStore().savedVybes() as? [VYBVybe] {
      for aVybe in savedVybes {
        if let zone = self.unlockedZoneForVybe(aVybe) {
          zone.addSavedVybe(aVybe)
        } else {
          let zone = self.createZoneFromVybe(aVybe)
          zone.addSavedVybe(aVybe)
          self.addUnlockedZone(zone)
        }
      }
      self._unlockedZones.sort({ (zone1: Zone, zone2: Zone) -> Bool in
        let comparisonResult = zone1.myMostRecentVybeTimestamp.compare(zone2.myMostRecentVybeTimestamp)
        return comparisonResult == NSComparisonResult.OrderedDescending
      })
    }
  }
  
  private func displayZoneInfo() {
    println("#ACTIVE# Name:  [numFreshContents] [popScore] [mostRecentTimestamp] ")
    for aZone in _activeZones {
      println("\(aZone.name): [\(aZone.freshContents.count)] [\(aZone.popularityScore)] [\(aZone.mostRecentActiveVybeTimestamp)]")
    }
    println("#UNLOCKED# [mostRecentTimestamp] [numMyVybes]")
    for aZone in _unlockedZones {
      println("\(aZone.name): [\(aZone.myMostRecentVybeTimestamp)] [\(aZone.myVybes.count)]")
    }
  }

}
