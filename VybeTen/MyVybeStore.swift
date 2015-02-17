//
//  MyVybeStore.swift
//  VybeTen
//
//  Created by Jinsu Kim on 12/22/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit

private let _sharedInstance = MyVybeStore()

class MyVybeStore: NSObject {
  var currZone: Zone?
  var currVybe: VYBVybe?
  var currentVybeUploadTask: UIBackgroundTaskIdentifier?
  
  var currTribe: PFObject?
  
  var savedVybes: [VYBVybe]?
  var _isUploadingSavedVybes: Bool
  
  class var sharedInstance: MyVybeStore {
    return _sharedInstance
  }
  
  override init() {
    _isUploadingSavedVybes = false
    
    super.init()
  }
  
  func prepareNewVybe() {
    var nVybe = PFObject(className: kVYBVybeClassKey)
    nVybe.setObject(NSDate(), forKey: kVYBVybeTimestampKey)
    nVybe.setObject(NSNumber(bool: true), forKey: kVYBVybeTypePublicKey)
    
    currVybe = VYBVybe(parseObject:nVybe)
    
  }
  
  func uploadCurrentVybe() {
    if let nVybe = currVybe {
      if currZone != nil {
        nVybe.setVybeZone(currZone!)
      }
      
      let vybe = VYBVybe(vybeObject: nVybe)
      var vybeParseObj = vybe.parseObject()
      
      if let video = NSData(contentsOfFile:vybe.videoFilePath()) {
        let videoFile = PFFile(data: video, contentType:"video/mp4")
        vybeParseObj.setObject(videoFile, forKey: kVYBVybeVideoKey)
      }
      
      if let image = NSData(contentsOfFile: vybe.thumbnailFilePath()) {
        let thumbnailFile = PFFile(data: image)
        vybeParseObj.setObject(thumbnailFile, forKey: kVYBVybeThumbnailKey)
      }
      
      currentVybeUploadTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({ () -> Void in
        UIApplication.sharedApplication().endBackgroundTask(self.currentVybeUploadTask!)
      })
      
      vybeParseObj.saveInBackgroundWithBlock({ (success: Bool, error: NSError!) -> Void in
        if success {
          
        } else {
          
        }
        UIApplication.sharedApplication().endBackgroundTask(self.currentVybeUploadTask!)
      })
      
      
    }
  }
  
  func startUploadingSavedVybes() {
    
  }
  
  func isUploadingSavedVybes() -> Bool {
    return _isUploadingSavedVybes
  }
  
  func deleteSavedVybe(obj: PFObject) {
    
  }
  
  func myVybesArchivePath() -> String? {
    let array = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
    if let documentPath = array.first as? NSString {
      return documentPath.stringByAppendingPathComponent("myVybes.archive")
    }
    return nil

  }
  
}
