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
    private var _activeUnlockedZones = [Zone]()
    private var _unlockedZones = [Zone]() // unlocked zones group my vybes
    
    class var sharedInstance: ZoneStore {
        return _zoneStoreSharedInstance
    }
    
    func didFetchUnlockedVybes(result: [AnyObject]!, completionHandler: ((success: Bool) -> Void)!) {
        completionHandler(success: false)
        // First clear caches
        _activeZones = [Zone]()
        _activeUnlockedZones = [Zone]()
        _unlockedZones = [Zone]()
        
        if let vybes = result as? [PFObject] {
            // First Group UNLOCKED zones
            self.createUnlockedZonesFromVybes(vybes)
            
            // Fetch ACTIVE zones
            let params = [:]
            PFCloud.callFunctionInBackground("get_active_vybes", withParameters:params) { (result: AnyObject!, error: NSError!) -> Void in
                if error == nil {
                    let vybeObjects = result as [PFObject]
                    // Group ACTIVE vybes into zones
                    self.createActiveZonesFromVybes(vybeObjects)
                    
                    // Mark active zones as UNLOCKED
                    self.unlockActiveZones()
                    
                    // Rearrange unlocked zones by popularity score
                    self.updatePopularityScoreForUnlockedZones()
                    self._unlockedZones.sort({ (zone1: Zone, zone2: Zone) -> Bool in
                        if (zone1.popularityScore == zone2.popularityScore) {
                            let comparisonResult = zone1.myMostRecentVybeTimestamp.compare(zone2.myMostRecentVybeTimestamp)
                            return comparisonResult == NSComparisonResult.OrderedDescending
                        }
                        return zone1.popularityScore > zone2.popularityScore
                    })


                    // Fetch Fresh vybes for ACTIVE zones
                    PFCloud.callFunctionInBackground("get_fresh_vybes", withParameters: params) { (result: AnyObject!, error: NSError!) -> Void in
                        if error == nil {
                            if let freshVybes = result as? [PFObject] {
                                for fVybe in freshVybes {
                                    if let zone = self.activeZoneForVybe(fVybe) {
                                        zone.addFreshContent(fVybe)
                                    }
                                }
                                self.displayZoneInfo()
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

    private func addUnlockedZone(zone: Zone) {

        _unlockedZones += [zone]
    }
    
    private func createActiveZonesFromVybes(vybes: [PFObject]) {
        for aVybe in vybes {
            self.putActiveVybeIntoZone(aVybe)
        }
        
        println("there are \(self._activeZones.count) active zones")
    }
    
    private func putActiveVybeIntoZone(aVybe: PFObject) {
        // Zone exists. Only update popularity
        if let zone = self.activeZoneForVybe(aVybe) {
            zone.increasePopularityWithVybe(aVybe)
        }
            // Vybe comes from a new zone. Create a new zone
        else {
            let zone = self.createZoneFromVybe(aVybe)
            zone.increasePopularityWithVybe(aVybe)
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
    
    

    private func updatePopularityScoreForUnlockedZones() {
        for aZone in _activeZones {
            for uZone in _unlockedZones {
                if aZone.zoneID == uZone.zoneID {
                    uZone.popularityScore = aZone.popularityScore
                }
            }
        }
    }
    
    private func unlockedZones() -> [Zone]! {
        return _unlockedZones
    }

    private func activeZones() -> [Zone]! {
        return _activeZones
    }
    
    func allZones() -> [Zone]! {
        return _activeZones + _unlockedZones
    }
    
//    func freshVybesFromZone(zoneID: String) -> [PFObject] {
//        for aZone in _activeZones {
//            if aZone.zoneID == zoneID {
//                return aZone.freshContents
//            }
//        }
//        return []
//    }
//
//    func removeWatchedFromFreshFeed(aVybe: PFObject!) {
//        // Update to cloud
//        let functionName = "remove_from_feed"
//        PFCloud.callFunctionInBackground(functionName, withParameters: ["vybeID": aVybe.objectId]) { (vybeObj: AnyObject!, error: NSError!) -> Void in
//            if error == nil {
//                
//            }
//        }
//        
//        var zoneID = "777"
//        
//        if let zID = aVybe[kVYBVybeZoneIDKey] as? String {
//            zoneID = zID
//        }
//        
//        for aZone in _activeZones {
//            if aZone.zoneID == zoneID {
//                // First update(remove) freshContents for the corresponding Zone
//                aZone.removeFromFreshContents(aVybe)
//                // Update watchedContents to prevent from receiving stale contents (watched but not removed from cloud) in next refresh
//                aZone.addWatchedContent(aVybe)
//            }
//        }
//    }
    
    private func displayZoneInfo() {
        println("#ACTIVE# [popScore] [numFreshContents] [numActiveVybes] ")
        for aZone in _activeZones {
            println("\(aZone.name): [\(aZone.popularityScore)] [\(aZone.freshContents.count)] [\(aZone.numOfActiveVybes)]")
        }
        println("#UNLOCKED# [mostRecentTimestamp] [numMyVybes]")
        for aZone in _activeZones {
            println("\(aZone.name): [\(aZone.myMostRecentVybeTimestamp)] [\(aZone.myVybes.count)]")
        }
    }

}
