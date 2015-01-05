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
  private var _featuredZones = [Zone]()
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
        if let vybeObjects = result as? [PFObject] {
          // Group ACTIVE vybes into zones
          self.createActiveZonesFromVybes(vybeObjects)
          
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
                  if (zone1.isTrending && !zone2.isTrending) {
                    return true
                  }
                  if (!zone1.isTrending && zone2.isTrending) {
                    return false
                  }
                  if (zone1.freshContents.count > 0 && zone2.freshContents.count == 0) {
                    return true
                  }
                  else if (zone1.freshContents.count == 0 && zone2.freshContents.count > 0) {
                    return false
                  }
                  else {
                    let comparisonResult = zone1.mostRecentActiveVybeTimestamp?.compare(zone2.mostRecentActiveVybeTimestamp!)
                    return comparisonResult == NSComparisonResult.OrderedDescending
                  }
                })
  //              self.displayZoneInfo()
              }
            }
            completionHandler(success: true)
          }
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
    _featuredZones = [Zone]()
    
    if let vybes = result as? [PFObject] {
      // First Group UNLOCKED zones
      self.createUnlockedZonesFromVybes(vybes)
      
      // Let's get FEATURED zones
      self.fetchFeaturedZones()
      
      self.fetchActiveVybes(completionHandler)
    }
    else {
      completionHandler(success: false)
    }
  }
  
  // MARK: - Featured zones

  private func fetchFeaturedZones() {
//    let featuredChannels = ConfigManager.sharedInstance.featuredChannels()
    let params = [:]
    PFCloud.callFunctionInBackground("getFeaturedChannels", withParameters: params) { (result: AnyObject!, error: NSError!) -> Void in
      if error == nil {
        if let channels = result as? [AnyObject] {
          for channel in channels {
            if let chnl = channel as? [AnyObject] {
              self.createFeaturedZone(chnl)
            }
          }
        }
      }
    }
  }
  
  private func createFeaturedZone(channel: [AnyObject]) {
    if channel.count != 4 {
      println("invalid channel object")
      return
    }
    
    if let name = channel[0] as? String {
      if let zoneID = channel[1] as? String {
        var zone = Zone(name: name, zoneID: zoneID)
        zone.isFeatured = true
        if let timestamp = channel[2] as? NSDate {
          zone.fromDate = timestamp
        }
        if let thumbnail = channel[3] as? PFFile {
          zone.featuredThumbnail = thumbnail
        }
        self.addFeaturedZone(zone)
      }
    }
  }
  
  private func addFeaturedZone(zone: Zone) {
    for zn in _featuredZones {
      if zone.zoneID == zn.zoneID {
        return
      }
    }
    
    _featuredZones += [zone]
  }
  
  // MARK: - Unlocked zones

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
    // First clear all vybes from active zones
    for aZone in _activeZones {
      if !aZone.isFeatured {
        aZone.clearActiveVybes()
      }
    }
    
    for aVybe in vybes {
      self.putActiveVybeIntoZone(aVybe)
    }
    
    // Remove previously active zones that have no active vybe as of now (b/c time passed or vybes deleted)
    var newActiveZones = [Zone]()
    for aZone in _activeZones {
      if aZone.mostRecentVybe != nil {
        newActiveZones += [aZone]
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
  
  func activeAndFeaturedZones() -> [Zone]! {
    return _featuredZones + _activeZones
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
  
  func allFreshVybes() -> [PFObject] {
    var allContents: [PFObject] = []
    for zone in _activeZones {
      if let contents = self.mergeFreshContentsAndMyContentsInZone(zone.zoneID) {
        allContents += contents
      }
    }
    
    allContents.sort { (vybe1: PFObject, vybe2: PFObject) -> Bool in
      let firstTime = vybe1[kVYBVybeTimestampKey] as NSDate
      let secondTime = vybe2[kVYBVybeTimestampKey] as NSDate
      let comparisonResult = firstTime.compare(secondTime)
      return comparisonResult == NSComparisonResult.OrderedAscending
    }
    
    return allContents
  }
  
  func freshVybesFromZone(zoneID: String) -> [PFObject]? {
    var contents: [PFObject]? = self.mergeFreshContentsAndMyContentsInZone(zoneID)

    return contents
  }
  
  private func mergeFreshContentsAndMyContentsInZone(zoneID: String) -> [PFObject]? {
    var freshContents = [PFObject]()
    for aZone in _activeZones {
      if aZone.zoneID == zoneID {
        freshContents = aZone.freshContents
        break
      }
    }

    var merged = freshContents
    var myVybes = [PFObject]()
    for aZone in _unlockedZones {
      if aZone.zoneID == zoneID {
        myVybes = aZone.myVybes
        break
      }
    }
    
    for myObj in myVybes {
      var idx = 0
      innerLoop: for ; idx < merged.count; {
        let myTime = myObj[kVYBVybeTimestampKey] as NSDate
        let freshTime = merged[idx].objectForKey(kVYBVybeTimestampKey) as NSDate
        
        let comparison = myTime.compare(freshTime)
        if comparison == NSComparisonResult.OrderedAscending {
          break innerLoop
        }
        else {
          idx++;
        }
      }
      
      if idx > 0 {
        merged.insert(myObj, atIndex: idx)
      }
    }
    
    return merged
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
  
  func deleteMyVybeInBackground(obj: AnyObject!, completionHandler: ((success: Bool) -> Void)) {
    let vybe = obj as PFObject
    vybe.deleteInBackgroundWithBlock { (success: Bool, error: NSError!) -> Void in
      if error == nil {
        if success {
          self.deleteSavedVybeLocally(vybe)
        }
        completionHandler(success: success)
      }
      else {
        completionHandler(success: false)
      }
    }
  }
  
  func deleteSavedVybeLocally(vybe: PFObject) {
    if let zone = self.unlockedZoneForVybe(vybe) {
      
      if zone.myVybes.count > 0 {
        var indexOne: Int = 0
        for index in 0...zone.myVybes.count - 1 {
          let obj = zone.myVybes[index]
          if let localId = obj["uniqueId"] as? String {
            if let anotherLocalId = vybe["uniqueId"] as? String {
              if localId == anotherLocalId {
                indexOne = index
                break
              }
            }
          } else {
            if obj.objectId == vybe.objectId {
              indexOne = index
              break
            }
          }
        }
        zone.myVybes.removeAtIndex(indexOne)
      }
      
      if zone.savedVybes.count > 0 {
        var indexTwo: Int = 0
        for index in 0...zone.savedVybes.count - 1 {
          if let localUniqueId = vybe["uniqueId"] as? String {
            if zone.savedVybes[index].uniqueFileName == localUniqueId {
              indexTwo = index
              break
            }
          }
        }
        zone.savedVybes.removeAtIndex(indexTwo)
      }
      
      // Remove this unlocked zone from Activity screen because it has no vybe
      if zone.myVybes.count == 0 {
        var newUnlocked = [Zone]()
        for zoneObj in self._unlockedZones {
          if zoneObj.zoneID != zone.zoneID {
            newUnlocked += [zoneObj]
          }
        }
        self._unlockedZones = newUnlocked
      }
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
