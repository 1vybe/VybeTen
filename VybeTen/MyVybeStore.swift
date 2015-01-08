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
  
  var currHashTags: [String]?
  var availableHashTags: [PFObject]?
  
  var savedVybes: [VYBVybe]?
  var _isUploadingSavedVybes: Bool
  
  class var sharedInstance: MyVybeStore {
    return _sharedInstance
  }
  
  override init() {
    _isUploadingSavedVybes = false
    
    super.init()

    var localQuery = PFQuery(className: kVYBHashTagClassKey)
    localQuery.fromLocalDatastore()
    localQuery.findObjectsInBackgroundWithBlock { (result: [AnyObject]!, error: NSError!) -> Void in
      if error == nil {
        self.availableHashTags = result as? [PFObject]
      }
    }
  }
  
  func prepareNewVybe() {
    var nVybe = PFObject(className: kVYBVybeClassKey)
    nVybe.setObject(NSDate(), forKey: kVYBVybeTimestampKey)
    nVybe.setObject(NSNumber(bool: true), forKey: kVYBVybeTypePublicKey)
    
    currVybe = VYBVybe(parseObject:nVybe)
    
    currHashTags = nil
    
    currZone = nil
  }
  
  func addHashTagForCurrentVybe(tagText: String) {
    let array = tagText.componentsSeparatedByString(" ")
    for aTag in array {
      if let tagName = aTag.componentsSeparatedByString("#").last {
        if countElements(tagName) > 0 {
          self.addToCurrHashTags(tagName)
        }
      }
    }
  }
  
  func clearCurrHashTags() {
    currHashTags = nil
  }
  
  private func addToCurrHashTags(tagName: String) {
    if currHashTags == nil {
      currHashTags = [tagName]
    } else {
      for aTag in currHashTags! {
        if aTag.lowercaseString == tagName.lowercaseString {
          return
        }
      }
      currHashTags! += [tagName]
    }
  }
  
  func uploadCurrentVybe() {
    if let nVybe = currVybe {
      if currZone != nil {
        nVybe.setVybeZone(currZone!)
      }
      
      let vybe = VYBVybe(vybeObject: nVybe)
      var vybeParseObj = vybe.parseObject()
      
      if let video = NSData(contentsOfFile:vybe.videoFilePath()) {
        let videoFile = PFFile(data: video)
        vybeParseObj.setObject(videoFile, forKey: kVYBVybeVideoKey)
      }
      
      if let image = NSData(contentsOfFile: vybe.thumbnailFilePath()) {
        let thumbnailFile = PFFile(data: image)
        vybeParseObj.setObject(thumbnailFile, forKey: kVYBVybeThumbnailKey)
      }
     
      if currHashTags != nil {
        vybeParseObj.setObject(currHashTags, forKey: kVYBVybeHashTagsKey)
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
