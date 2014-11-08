//
//  ZoneFinder.swift
//  VybeTen
//
//  Created by jinsuk on 10/30/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit

private let _sharedInstance = ZoneFinder()

@objc class ZoneFinder: NSObject  {
    
    let clientID = "O3P21TKG3FF1U11LDHT52PA50WLFPCBZUNHKBNK0OJRCOF12"
    let clientSecret = "JJ5VR1JFDUSIG0LBDKPFXFHUP3HACC004YDXSOZ4YZFRCMIB"
    
    var numOfResults: Int = 10;
    
    var searchURL = ""
    let session: NSURLSession!
    
    var suggestions: [Zone]!
    
    class var sharedInstance: ZoneFinder {
        return _sharedInstance;
    }
    
    override init() {
        super.init()
        searchURL = "https://api.foursquare.com/v2/venues/search?"
        searchURL += "client_id=\(clientID)"
        searchURL += "&client_secret=\(clientSecret)"
        searchURL += "&intent=checkin"
        searchURL += "&v=20130815" // this is a required field
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        session = NSURLSession(configuration: configuration)
    }
    
    func findZoneNearLocationInBackground(completionHandler: ((success: Bool) -> Void)) {
        PFGeoPoint.geoPointForCurrentLocationInBackground { (geoPoint: PFGeoPoint!, error: NSError!) -> Void in
            if error == nil {
                let location = CLLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
                if let currVybe = VYBMyVybeStore.sharedStore().currVybe() {
                    currVybe.locationCL = location
                }
                
                self.searchURL += "&limit=\(self.numOfResults)"
                self.searchURL += "&ll=\(geoPoint.latitude),\(geoPoint.longitude)"
                
                var dataTask = self.session.dataTaskWithURL(NSURL(string: self.searchURL)!, completionHandler: { (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void in
                    if error == nil {
                        let statusCode = (response as NSHTTPURLResponse).statusCode
                        
                        if statusCode == 200 {
                            if let zones = self.generateZonesFromData(data) {
                                self.suggestions = zones
                                completionHandler(success: true)
                            }
                        }
                    }
                    else {
                        completionHandler(success: false)
                    }
                })
                
                dataTask.resume()
            }
            else {
                completionHandler(success: false)
            }
            
        }

    }
    
    func findZoneFromCurrentLocationInBackground() {
        self.findZoneNearLocationInBackground({ _ in })
    }
    
    private func generateZonesFromData(data: NSData!) -> [Zone]? {
        var zones = [Zone]()
        var jsonError: NSError?
        var jsonObj = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &jsonError) as [String: AnyObject]
        if jsonError != nil {
            let response = jsonObj["response"] as [String: AnyObject]
            let venues = response["venues"] as [NSDictionary]
            for aVenue in venues {
                let aZone = Zone(foursquareVenue: aVenue)
                zones.append(aZone)
            }
            
        }
        return nil
    }
}
