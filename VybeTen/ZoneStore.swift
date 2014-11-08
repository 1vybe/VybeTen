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
    private var _activeZones: [Zone]!
    private var _activeUnlockedZones: [Zone]!
    private var _unlockedZones: [Zone]! // unlocked zones group my vybes
    
    class var sharedInstance: ZoneStore {
        return _zoneStoreSharedInstance
    }
    
    func didFetchUnlockedVybes(result: [PFObject]!, completionHandler: ((success: Bool) -> Void)) {
        self.createUnlockedZonesFromVybes(result)
        
        // Fetch active vybes
        let functionName = "get_active_vybes"
        let params = [NSObject: AnyObject]()
        PFCloud.callFunctionInBackground(functionName, withParameters:params) { (result: AnyObject!, error: NSError!) -> Void in
            if error == nil {
                if result.count > 0 {
                    let vybeObjects = result as [PFObject]!
                    // Group vybes into zones
                    self.createActiveZonesFromVybes(vybeObjects)
                    
                    // Mark active zones as UNLOCKED
                    self.updateUnlockedActiveZones()
                    
                    // Rearrange unlocked zones by popularity score
                    self.updatePopularityScoreForUnlockedZones()
                    self._unlockedZones.sort({ (zone1: Zone, zone2: Zone) -> Bool in
                        return zone1.popularityScore > zone2.popularityScore
                    })
                    
                    completionHandler(success: true)
                }
                else {
                    completionHandler(success: false)
                }
            }
            else {
                completionHandler(success: false)
            }
        }
    }
    
    private func createUnlockedZonesFromVybes(result: [PFObject]!) {
        for aVybe in result {
            self.putUnlockedVybeIntoZone(aVybe)
        }
        
        println("there are \(self._unlockedZones.count) unlocked zones")
        
    }
    
    private func putUnlockedVybeIntoZone(aVybe: PFObject!) {
        if let zone = self.unlockedZoneForVybe(aVybe) {
            zone.addMyVybe(aVybe)
        }
        else {
            let zone = self.createZoneFromVybe(aVybe)
            zone.addMyVybe(aVybe)
            self.addUnlockedZone(zone)
        }
    }
    
    private func unlockedZoneForVybe(aVybe: PFObject!) -> Zone! {
        if _unlockedZones == nil {
            return nil
        }
        
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
    
    private func addUnlockedZone(zone: Zone!) {
        if _unlockedZones == nil {
            _unlockedZones = [zone]
        }
        else {
            _unlockedZones.append(zone)
        }
    }
    
    
    private func updateUnlockedActiveZones() {
        for aZone in _activeZones {
            for uZone in _unlockedZones {
                if (uZone.zoneID == aZone.zoneID) {
                    aZone.unlocked = true
                }
            }
        }
    }
    

    private func createActiveZonesFromVybes(vybes: [PFObject]!) {
        for aVybe in vybes {
            self.putActiveVybeIntoZone(aVybe)
        }
        
        println("there are \(self._activeZones.count) active zones")
    }
    
    
    private func putActiveVybeIntoZone(aVybe: PFObject!) {
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
    
    private func activeZoneForVybe(aVybe: PFObject!) -> Zone! {
        if _activeZones == nil {
            return nil
        }
        
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
    
    
    private func createZoneFromVybe(aVybe: PFObject!) -> Zone! {
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
    
    
    private func addActiveZone(zone: Zone) {
        if _activeZones == nil {
            _activeZones = [zone]
        }
        else {
            _activeZones.append(zone)
        }
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
    
    func unlockedZones() -> [Zone]! {
        return _unlockedZones
    }
    
    func activeZones() -> [Zone]! {
        return _activeZones
    }
}
