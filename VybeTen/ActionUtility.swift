//
//  ActionUtility.swift
//  VybeTen
//
//  Created by Jinsu Kim on 1/23/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit


class ActionUtility: NSObject {
  
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
        for activity in result {
          activity.deleteEventually!()
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
    
    followActivity.saveEventually()
    
    VYBCache.sharedCache().setFollowStatus(true, user: user)
  }
  
  class func unfollowUser(user: AnyObject) {
    // First delete old same follow requests
    var query = PFQuery(className: kVYBActivityClassKey)
    query.whereKey(kVYBActivityTypeKey, equalTo: kVYBActivityTypeFollow)
    query.whereKey(kVYBActivityFromUserKey, equalTo: PFUser.currentUser())
    query.whereKey(kVYBActivityToUserKey, equalTo:user)
    query.findObjectsInBackgroundWithBlock { (result: [AnyObject]!, error: NSError!) -> Void in
      if error == nil {
        for activity in result {
          activity.deleteEventually!()
        }
      }
    }
    
    VYBCache.sharedCache().setFollowStatus(false, user: user as PFUser)
  }
}
