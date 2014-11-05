//
//  VYBZone.swift
//  VybeTen
//
//  Created by jinsuk on 10/30/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit
import MapKit

class VYBZone: NSObject, MKAnnotation {
    var zoneID: String!
    var name: String!
    var unlocked: Bool = false
    
    var coordinate: CLLocationCoordinate2D
    var title: String!
    

    init(foursquareVenue: NSDictionary) {
        coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        
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
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        
    }
    
    
}
