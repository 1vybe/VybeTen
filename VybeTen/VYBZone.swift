//
//  VYBZone.swift
//  VybeTen
//
//  Created by jinsuk on 10/30/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit

class VYBZone: NSObject {
    var zoneID: String!
    var name: String!
    
    init(foursquareVenue: NSDictionary) {
        zoneID = foursquareVenue["id"] as? String
        if zoneID == nil {
            zoneID = "777"
        }
        name = foursquareVenue["name"] as? String
        if name == nil {
            name = "Earth"
        }
        
    }
    
}
