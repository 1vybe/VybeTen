//
//  CloudUtility.swift
//  VybeTen
//
//  Created by Jinsu Kim on 1/23/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit


class CloudUtility: NSObject {
  
  class func removeFromMyFeed(watched: AnyObject) {
    let watchedObj = watched as PFObject
    
    let myFeed = PFUser.currentUser().relationForKey(kVYBUserFreshFeedKey)
    myFeed.removeObject(watchedObj)
    
    watchedObj.unpinInBackgroundWithName("MyFreshFeed", block: { (success: Bool, error: NSError!) -> Void in
      if success {
        println("removed from feed")
      }
    })
  }
  
  class func updateLastVybe(last: AnyObject) {
    let lastObj = last as PFObject
    
    if let tribe = lastObj[kVYBVybeTribeKey] as? PFObject {
      let query = PFQuery(className: kVYBVybeClassKey)
      query.fromPinWithName("LastVybes")
      query.whereKey(kVYBVybeTribeKey, equalTo: tribe)
      query.findObjectsInBackgroundWithBlock { (result: [AnyObject]!, error: NSError!) -> Void in
        if result != nil {
          PFObject.unpinAllObjectsInBackgroundWithName("LastVybes")
          lastObj.pinInBackgroundWithName("LastVybes")
        }
      }
    }
  }
  
  class func followUser(userObj: AnyObject) {
    let user = userObj as PFUser
    if user.objectId == PFUser.currentUser().objectId {
      println("ERRORROR")
      return
    }
    
    // First delete old same follow requests
    var query = PFQuery(className: kVYBActivityClassKey)
    query.whereKey(kVYBActivityTypeKey, equalTo: kVYBActivityTypeFollow)
    query.whereKey(kVYBActivityFromUserKey, equalTo: PFUser.currentUser())
    query.whereKey(kVYBActivityToUserKey, equalTo:user)
    query.findObjectsInBackgroundWithBlock { (result: [AnyObject]!, error: NSError!) -> Void in
      if error == nil {
        for activity in result as [PFObject] {
          activity.deleteInBackgroundWithBlock(nil)
        }
      }
    }
    
    var followActivity = PFObject(className: kVYBActivityClassKey)
    followActivity.setObject(kVYBActivityTypeFollow, forKey: kVYBActivityTypeKey)
    followActivity.setObject(PFUser.currentUser(), forKey:kVYBActivityFromUserKey)
    followActivity.setObject(user, forKey: kVYBActivityToUserKey)
    
    var followACL = PFACL(user: PFUser.currentUser())
    followACL.setPublicReadAccess(true)
    followACL.setWriteAccess(true, forUser: user)
    
    followActivity.saveEventually(nil)
    
//    VYBCache.sharedCache().setFollowStatus(true, user: user)
  }
  
  class func unfollowUser(user: AnyObject) {
    // First delete old same follow requests
    var query = PFQuery(className: kVYBActivityClassKey)
    query.whereKey(kVYBActivityTypeKey, equalTo: kVYBActivityTypeFollow)
    query.whereKey(kVYBActivityFromUserKey, equalTo: PFUser.currentUser())
    query.whereKey(kVYBActivityToUserKey, equalTo:user)
    query.findObjectsInBackgroundWithBlock { (result: [AnyObject]!, error: NSError!) -> Void in
      if error == nil {
        for activity in result as [PFObject] {
          activity.deleteInBackgroundWithBlock(nil)
        }
      }
    }
    
//    VYBCache.sharedCache().setFollowStatus(false, user: user as PFUser)
  }
}
