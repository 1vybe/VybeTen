//
//  Zone.swift
//  VybeTen
//
//  Created by jinsuk on 10/30/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit
import MapKit

@objc class Zone: NSObject {
  var zoneID: String!
  var name: String!
  
  // FEATURED
  var isFeatured: Bool = false
  var eventName: String?
  var fromDate: NSDate?
  var featuredThumbnail: PFFile?
  
  // TRENDING
  var isTrending: Bool = false
  
  // ACTIVE
  var isActive: Bool = false
  var activeUsers = [String: Int]()
  var mostRecentVybe: PFObject?
  var mostRecentActiveVybeTimestamp: NSDate? {
    get {
      return mostRecentVybe?[kVYBVybeTimestampKey] as? NSDate
    }
  }
  //  var numOfActiveVybes = 0
  var popularityScore = 0
  
  var freshContents = [PFObject]()
  var watchedContents = [PFObject]()
  
  // UNLOCKED zone
  var myVybes = [PFObject]()
  var savedVybes = [VYBVybe]()
  var unlocked = false
  var numOfMyVybes: Int {
    get {
      return myVybes.count
    }
  }
  
  var myMostRecentVybeTimestamp: NSDate {
    get {
      return myVybes.first?.objectForKey(kVYBVybeTimestampKey) as! NSDate
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
  
  deinit {
    
  }
  
  init(foursquareVenue: NSDictionary!) {
    let location = foursquareVenue["location"] as! NSDictionary?
    let latitude = location?["lat"] as! Double
    let longitude = location?["lng"] as! Double
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
  
  func clearActiveVybes() {
    mostRecentVybe = nil
    activeUsers = [:]
    popularityScore = 0
    
  }
  
  func addActiveVybe(aVybe: PFObject) {
    if let vybeTime = aVybe[kVYBVybeTimestampKey] as? NSDate {
      if mostRecentVybe != nil {
        let result = vybeTime.compare(mostRecentVybe?[kVYBVybeTimestampKey] as! NSDate)
        if result == NSComparisonResult.OrderedAscending {
          return
        }
      }
    }
    
    if let user = aVybe[kVYBVybeUserKey] as! PFObject! {
      // freshFeed is only array of vybes. User field is not included when a vybe is inserted into freshFeed in afterSave. So we compare User objectID
      let userObjID = user.objectId
      activeUsers[userObjID] = 1
    }
    
    //      numOfActiveVybes++
    
    if mostRecentVybe == nil {
      mostRecentVybe = aVybe
    }
    else {
      let aDate = mostRecentVybe?[kVYBVybeTimestampKey] as! NSDate
      let cDate = aVybe[kVYBVybeTimestampKey] as! NSDate
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
  
  func addSavedVybe(sVybe: VYBVybe) {
    let parseVybe = sVybe.parseObject()
    parseVybe["uniqueId"] = sVybe.uniqueFileName
    for aVybe in savedVybes {
      if aVybe.uniqueFileName == sVybe.uniqueFileName {
        return
      }
    }
    
    myVybes = [parseVybe] + myVybes
    savedVybes += [sVybe]
  }
  
  func savedObject(aVybe: PFObject) -> VYBVybe? {
    for sVybe in savedVybes {
      if let uniqueID = aVybe["uniqueId"] as? String {
        if uniqueID == sVybe.uniqueFileName {
          return sVybe
        }
      }
    }
    return nil
  }
  
  func addFreshVybe(nVybe: PFObject) {
    for aVybe in freshContents {
      if aVybe.objectId == nVybe.objectId {
        return
      }
    }
    
    for aVybe in watchedContents {
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
  
  func addWatchedContent(vybe: PFObject) {
    for aVybe in watchedContents {
      if aVybe.objectId == vybe.objectId {
        return
      }
    }
    watchedContents.append(vybe)
    //Update to cloud
    PFCloud.callFunctionInBackground("remove_from_feed", withParameters: ["vybeID" : vybe.objectId]) { (result: AnyObject!, error: NSError!) -> Void in
      if error != nil {
        println("could not remove the vybe")
      } else {
        println("did remove the vybe")
      }
    }
  }
  
  func featuredThumbnailFile() -> PFFile? {
    return featuredThumbnail
  }
  
  
  override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
    
  }
  
  
}
