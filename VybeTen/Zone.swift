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
    var unlocked: Bool = false
    
    var uniqueUsers = [String: Int]()
    var numOfVybes = 0
    var popularityScore = 0

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
    
    func increasePopularityWithVybe(aVybe: PFObject!) {
        if let aZoneID = aVybe[kVYBVybeZoneIDKey] as? String {
            if aZoneID != zoneID {
                println("Something is wrong zoneID mispatch")
            }
        }
        
        if let user = aVybe[kVYBVybeUserKey] as PFObject! {
            let username = user[kVYBUserUsernameKey] as String
            uniqueUsers[username] = 1
        }
        
        numOfVybes++
        
        self.updatePopularityScore()
    }
    
    private func updatePopularityScore() {
        popularityScore = uniqueUsers.keys.array.count
    }
    
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        
    }
    
    
}
