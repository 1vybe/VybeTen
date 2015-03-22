//
//  CloudUtility.swift
//  VybeTen
//
//  Created by Jinsu Kim on 1/23/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class CloudUtility: NSObject {
  class func voteUp(vybe vy: PFObject) {
    let type = VYBCache.sharedCache().pointTypeFromCurrentUserForVybe(vy)
    
    let query = PFQuery(className: kVYBPointClassKey)
    query.whereKey(kVYBPointVybeKey, equalTo: vy)
    query.whereKey(kVYBPointUserKey, equalTo: PFUser.currentUser())
    query.findObjectsInBackgroundWithBlock({ (result: [AnyObject]!, error: NSError!) -> Void in
      if result != nil {
        for obj in result as [PFObject] {
          obj.deleteInBackground()
        }
      }
    })

    if type == kVYBVybeAttributesPointTypeUpKey {
      VYBCache.sharedCache().decrementPointScoreForVybe(vy)
      VYBCache.sharedCache().setPointTypeFromCurrentUserForVybe(vy, type: kVYBVybeAttributesPointTypeNoneKey)
    } else {
      VYBCache.sharedCache().incrementPointScoreForVybe(vy)
      VYBCache.sharedCache().setPointTypeFromCurrentUserForVybe(vy, type: kVYBVybeAttributesPointTypeUpKey)
      // If you have voted DOWN before, we need to increment twice
      if type == kVYBVybeAttributesPointTypeDownKey {
        VYBCache.sharedCache().incrementPointScoreForVybe(vy)
      }
      
      let upPoint = PFObject(className: kVYBPointClassKey)
      upPoint[kVYBPointTypeKey] = kVYBPointTypeUpKey
      upPoint[kVYBPointUserKey] = PFUser.currentUser()
      upPoint[kVYBPointVybeKey] = vy
      upPoint.saveEventually()
    }
    
    NSNotificationCenter.defaultCenter().postNotificationName(CloudUtilityPointUpdatedByCurrentUserNotification, object: nil)
  }
  
  class func voteDown(vybe vy: PFObject) {
    let type = VYBCache.sharedCache().pointTypeFromCurrentUserForVybe(vy)
    if type == kVYBVybeAttributesPointTypeDownKey {
      VYBCache.sharedCache().incrementPointScoreForVybe(vy)
      VYBCache.sharedCache().setPointTypeFromCurrentUserForVybe(vy, type: kVYBVybeAttributesPointTypeNoneKey)
    } else {
      VYBCache.sharedCache().decrementPointScoreForVybe(vy)
      VYBCache.sharedCache().setPointTypeFromCurrentUserForVybe(vy, type: kVYBVybeAttributesPointTypeDownKey)
      // If you have voted UP before, we need to decrement twice
      if type == kVYBVybeAttributesPointTypeUpKey {
        VYBCache.sharedCache().decrementPointScoreForVybe(vy)
      }
      
      let downPoint = PFObject(className: kVYBPointClassKey)
      downPoint[kVYBPointTypeKey] = kVYBPointTypeDownKey
      downPoint[kVYBPointUserKey] = PFUser.currentUser()
      downPoint[kVYBPointVybeKey] = vy
      downPoint.saveEventually()
    }

    let query = PFQuery(className: kVYBPointClassKey)
    query.whereKey(kVYBPointVybeKey, equalTo: vy)
    query.whereKey(kVYBPointUserKey, equalTo: PFUser.currentUser())
    query.findObjectsInBackgroundWithBlock({ (result: [AnyObject]!, error: NSError!) -> Void in
      if result != nil {
        for obj in result as [PFObject] {
          obj.deleteInBackground()
        }
      }
    })
    
    NSNotificationCenter.defaultCenter().postNotificationName(CloudUtilityPointUpdatedByCurrentUserNotification, object: nil)
  }
  
  class private func updatePointsForVybe(vy: PFObject) {
    
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
