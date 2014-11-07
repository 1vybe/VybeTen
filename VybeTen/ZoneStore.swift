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
    var _activeZones: [VYBZone]!
    private var _unlockedZones: [VYBZone]!
    private var _activeUnlockedZones: [VYBZone]!
    
    class var sharedInstance: ZoneStore {
        return _zoneStoreSharedInstance
    }
    
    private func fetchActiveVybes() {
        let functionName = "get_active_vybes"
        let params = [NSObject: AnyObject]()
        PFCloud.callFunctionInBackground(functionName, withParameters:params) { (result: AnyObject!, error: NSError!) -> Void in
            if error == nil {
                if result.count > 0 {
                    let vybeObjects = result as? [PFObject]
                    self.createActiveZonesFromVybes(vybeObjects)
                    
                    // Mark active zones as UNLOCKED
                    self.updateUnlockedActiveZones()
                    
                    // Rearrange unlocked zones by popularity score
                    self.updatePopularityScoreForUnlockedZones()
                    self._unlockedZones .sort({ (zone1: VYBZone, zone2: VYBZone) -> Bool in
                        return zone1.activityLevel > zone2.activityLevel
                    })
                    
                }
            }
        }
    }
    
    private func createActiveZonesFromVybes(vybes: [PFObject]!) {
        let zoneDict = [VYBZone: PFObject]()
        var coordinate = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)

        for aVybe in vybes {
            let zone = self.extractZoneFromVybe(aVybe)
            
            self.addActiveZone(zone)
        }
        
        println("there are \(self._activeZones.count) active zones")
    }
    
    private func addActiveZone(zone: VYBZone) {
        if _activeZones == nil {
            _activeZones = [zone]
        }
        else {
            var newZone = true
            for aZone in _activeZones {
                if aZone.zoneID == zone.zoneID {
                    newZone = false
                    aZone.activityLevel++
                    break
                }
            }
            if newZone {
                _activeZones.append(zone)
            }
        }
    }
    
    
    func didFetchUnlockedVybes(result: [PFObject]!) {
        self.createUnlockedZonesFromVybes(result)
        
        self.fetchActiveVybes()
        
    }
    
    private func createUnlockedZonesFromVybes(result: [PFObject]!) {
        for aVybe in result {
            let zone = self.extractZoneFromVybe(aVybe)
            
            self.addUnlockedZone(zone)
        }
        
        println("there are \(self._unlockedZones.count) unlocked zones")


    }
    
    private func addUnlockedZone(zone: VYBZone!) {
        if _unlockedZones == nil {
            _unlockedZones = [zone]
        }
        else {
            var newZone = true
            for uZone in _unlockedZones {
                if (uZone.zoneID == zone.zoneID) {
                    newZone = false
                    break
                }
            }
            if newZone {
                _unlockedZones.append(zone)
            }
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
    
    private func updatePopularityScoreForUnlockedZones() {
        for aZone in _activeZones {
            for uZone in _unlockedZones {
                if aZone.zoneID == uZone.zoneID {
                    uZone.activityLevel = aZone.activityLevel
                }
            }
        }
    }

    
    private func extractZoneFromVybe(aVybe: PFObject!) -> VYBZone! {
        var zone: VYBZone!
        
        if let zoneID = aVybe[kVYBVybeZoneIDKey] as? String {
            let zoneName = aVybe[kVYBVybeZoneNameKey] as String
            zone = VYBZone(name: zoneName, zoneID: zoneID)
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
            zone = VYBZone(name: "Earth", zoneID: "777")
        }
        
        zone.unlocked = false
        
        return zone
    }
    
    func unlockedZones() -> [VYBZone]! {
        return _unlockedZones
    }
    
    func activeZones() -> [VYBZone]! {
        return _activeZones
    }
}
