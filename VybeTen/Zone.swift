//
//  Zone.swift
//  VybeTen
//
//  Created by jinsuk on 10/30/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit
import MapKit

@objc class Zone: NSObject, MKAnnotation {
    var zoneID: String!
    var name: String!
    
    var activeUsers = [String: Int]()
    var mostRecentVybe: PFObject!
    var mostRecentActiveVybeTimestamp: NSDate {
        get {
            return mostRecentVybe[kVYBVybeTimestampKey]? as NSDate
        }
    }
    var numOfActiveVybes = 0
    var popularityScore = 0
    
    var freshContents = [PFObject]()
    var watchedContents = [PFObject]()
    
    var myVybes = [PFObject]()
    var unlocked = false
    var numOfMyVybes: Int {
        get {
            return myVybes.count
        }
    }
    
    var myMostRecentVybeTimestamp: NSDate {
        get {
            return myVybes.first?.objectForKey(kVYBVybeTimestampKey) as NSDate
        }
    }

    var coordinate: CLLocationCoordinate2D
    var title: String!
    
    var latitude: Double {
        get {
            return coordinate.latitude
        }
    }
    var longitude: Double {
        get {
            return coordinate.longitude
        }
    }
    
    init(foursquareVenue: NSDictionary!) {
        let location = foursquareVenue["location"] as NSDictionary?
        let latitude = location?["lat"] as Double
        let longitude = location?["lng"] as Double
        let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        coordinate = coord
 
        zoneID = foursquareVenue["id"] as? String
        if zoneID == nil {
            zoneID = "777"
        }
        name = foursquareVenue["name"] as? String
        if name == nil {
            name = "Earth"
        }
    }
    
    init(name aName: String, zoneID zID: String) {
        coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)

        name = aName
        zoneID = zID
    }

    
    func addActiveVybe(aVybe: PFObject) {
        if let vybeTime = aVybe[kVYBVybeTimestampKey] as? NSDate {
            if mostRecentVybe != nil {
                let result = vybeTime.compare(mostRecentVybe[kVYBVybeTimestampKey] as NSDate)
                if result == NSComparisonResult.OrderedAscending {
                    return
                }
            }
        }
        
        if let user = aVybe[kVYBVybeUserKey] as PFObject! {
            // freshFeed is only array of vybes. User field is not included when a vybe is inserted into freshFeed in afterSave. So we compare User objectID
            let userObjID = user.objectId
            activeUsers[userObjID] = 1
        }
        
        numOfActiveVybes++
        
        if mostRecentVybe == nil {
            mostRecentVybe = aVybe
        }
        else {
            let aDate = mostRecentVybe[kVYBVybeTimestampKey] as NSDate
            let cDate = aVybe[kVYBVybeTimestampKey] as NSDate
            let comparison = aDate.compare(cDate)
            if comparison == NSComparisonResult.OrderedAscending {
                mostRecentVybe = aVybe
            }
        }
        
        self.updatePopularityScore()
    }

    
    private func updatePopularityScore() {
        popularityScore = activeUsers.keys.array.count
    }
    
    func addMyVybe(aVybe: PFObject) {
        myVybes += [aVybe]
    }
    
    func addFreshVybe(nVybe: PFObject) {
        for aVybe in freshContents {
            if aVybe.objectId == nVybe.objectId {
                return
            }
        }
        freshContents.append(nVybe)
    }
    
    func removeFromFreshContents(dVybe: PFObject) {
        // We want to keep the last fresh vybe 
        if freshContents.count == 1 {
            mostRecentVybe = dVybe
        }
        var newFreshContents = [PFObject]()
        for aVybe in freshContents {
            if aVybe.objectId != dVybe.objectId {
                newFreshContents.append(aVybe)
            }
        }
        freshContents = newFreshContents
    }
    
    //NOTE: Not being used right now
    func addWatchedContent(nVybe: PFObject) {
        for aVybe in watchedContents {
            if aVybe.objectId == nVybe.objectId {
                return
            }
        }
        watchedContents.append(nVybe)
    }
    
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        
    }
    
    
}
