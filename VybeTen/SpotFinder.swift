//
//  SpotFinder.swift
//  VybeTen
//
//  Created by jinsuk on 10/30/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit

private let _sharedInstance = SpotFinder()

@objc class SpotFinder: NSObject, CLLocationManagerDelegate  {
  var locationManager: CLLocationManager!
  var locFetchCompletionClosure = { (success: Bool) -> () in }
  
  let clientID = "O3P21TKG3FF1U11LDHT52PA50WLFPCBZUNHKBNK0OJRCOF12"
  let clientSecret = "JJ5VR1JFDUSIG0LBDKPFXFHUP3HACC004YDXSOZ4YZFRCMIB"
  
  var numOfResults: Int = 20;
  
  var searchURL = ""
  var session: NSURLSession!
  
  var suggestions: [Zone]?
  
  class var sharedInstance: SpotFinder {
    return _sharedInstance;
  }
  
  func setUpSessionWithFourSquare() {
    searchURL = "https://api.foursquare.com/v2/venues/search?"
    searchURL += "client_id=\(clientID)"
    searchURL += "&client_secret=\(clientSecret)"
    searchURL += "&intent=checkin"
    searchURL += "&v=20130815" // this is a required field
    
    let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
    
    session = NSURLSession(configuration: configuration)
  }
  
  func findNearbySpotsInBackground(completionHandler: ((success: Bool) -> Void)) {
    self.setUpSessionWithFourSquare()
    
    locFetchCompletionClosure = completionHandler
    
    if CLLocationManager.locationServicesEnabled() {
      locationManager = CLLocationManager()
      locationManager.delegate = self
      locationManager.startUpdatingLocation()
    }
    else {
      locFetchCompletionClosure(false)
    }
  }
  
  func findSpotFromCurrentLocationInBackground() {
    locFetchCompletionClosure = { _ in }
    
    self.findNearbySpotsInBackground(locFetchCompletionClosure)
  }
  
  func suggestionsContainSpot(zone: Zone) -> Bool {
    if suggestions != nil {
      for aZone in suggestions! {
        if aZone.zoneID == zone.zoneID {
          return true
        }
      }
    }

    return false
  }
  
  private func generateSpotsFromData(data: NSData!) -> [Zone]? {
    var zones = [Zone]()
    var jsonError: NSError?
    var jsonObj = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &jsonError) as [String: AnyObject]
    if jsonError == nil {
      let response = jsonObj["response"] as [String: AnyObject]
      let venues = response["venues"] as [NSDictionary]
      for aVenue in venues {
        let aZone = Zone(foursquareVenue: aVenue)
        zones.append(aZone)
      }
      return zones
    }
    return nil
  }
  
  func suggestedSpots() -> [Zone]? {
    if let customZones = ConfigManager.sharedInstance.customZones() {
      if suggestions == nil {
        suggestions = customZones
      } else {
        suggestions = customZones + suggestions!
      }
    }
    
    return suggestions
  }
  
  
  func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
    locationManager.stopUpdatingLocation()
    
    let currLocation = locations.last as CLLocation
    
    if let currVybe = MyVybeStore.sharedInstance.currVybe {
      currVybe.locationCL = currLocation
    }
    
    self.searchURL += "&limit=\(self.numOfResults)"
    self.searchURL += "&ll=\(currLocation.coordinate.latitude),\(currLocation.coordinate.longitude)"
    
    var dataTask = self.session.dataTaskWithURL(NSURL(string: self.searchURL)!, completionHandler: { (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void in
      if error == nil {
        let statusCode = (response as NSHTTPURLResponse).statusCode
        
        if statusCode == 200 {
          if let zones = self.generateSpotsFromData(data) {
            self.suggestions = zones
            self.locFetchCompletionClosure(true)
          }
          else {
          }
        } else {
          self.locFetchCompletionClosure(false)
        }
      }
      else {
        self.locFetchCompletionClosure(false)
      }
    })
    
    dataTask.resume()
  }
  
  func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
    println(error)
  }
  
}
