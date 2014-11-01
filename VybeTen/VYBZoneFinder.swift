//
//  VYBZoneFinder.swift
//  VybeTen
//
//  Created by jinsuk on 10/30/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit

class VYBZoneFinder: NSObject  {

    let clientID = "O3P21TKG3FF1U11LDHT52PA50WLFPCBZUNHKBNK0OJRCOF12"
    let clientSecret = "JJ5VR1JFDUSIG0LBDKPFXFHUP3HACC004YDXSOZ4YZFRCMIB"
    
    var numOfResults: Int = 10;
    
    var searchURL = ""
    let session: NSURLSession!
    
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
    
    func findZoneNearLocationInBackground(latitude: Double, longitude: Double, completionHandler: ((results: NSArray?, error: NSError?) -> Void)) {
        searchURL += "&limit=\(numOfResults)"
        searchURL += "&ll=\(latitude),\(longitude)"
        
        var dataTask = self.session.dataTaskWithURL(NSURL(string: self.searchURL)!, completionHandler: { (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void in
                if error == nil {
                    let statusCode = (response as NSHTTPURLResponse).statusCode
                
                    if statusCode == 200 {
                        let zones = self.generateZonesFromData(data)
                        if zones != nil {
                            completionHandler(results: zones, error: nil)
                        }
                    
                    }
                }
                else {
                    completionHandler(results: nil, error: error)
                }
            })
        
        dataTask.resume()
    }
    
    private func generateZonesFromData(data: NSData) -> NSArray? {
        var zones = [VYBZone]()
        var jsonError: NSError?
        var jsonObj = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &jsonError) as [String: AnyObject]
        if jsonError != nil {
            let response = jsonObj["response"] as [String: AnyObject]
            let venues = response["venues"] as [NSDictionary]
            for aVenue in venues {
                let aZone = VYBZone(foursquareVenue: aVenue)
                zones.append(aZone)
            }
            
        }
        return nil
    }
}
