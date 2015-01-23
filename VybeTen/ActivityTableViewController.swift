//
//  ActivityTableViewController.swift
//  VybeTen
//
//  Created by Jinsu Kim on 1/14/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class ActivityTableViewController: PFQueryTableViewController, VYBPlayerViewControllerDelegate {
  @IBAction func followButtonPressed(sender: AnyObject) {
    if let followButton = sender as? UIButton {
      if let user = objects[followButton.tag].objectForKey?(kVYBActivityFromUserKey) as? PFUser {
        if followButton.selected {
          ActionUtility.unfollowUser(user)
        } else {
          ActionUtility.followUser(user)
        }
      }
      followButton.selected = !followButton.selected
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
        
    let textAttributes = NSMutableDictionary()
    if let font = UIFont(name: "Helvetica Neue", size: 15.0) {
      let textColor = UIColor(red: 255.0/255.0, green: 102.0/255.0, blue: 53.0/255.0, alpha: 1.0)
      textAttributes.setObject(font, forKey: NSFontAttributeName)
      textAttributes.setObject(textColor, forKey: NSForegroundColorAttributeName)
      self.navigationController?.navigationBar.titleTextAttributes = textAttributes
    }
    
    self.tableView.estimatedRowHeight = 128.0
    self.tableView.rowHeight = UITableViewAutomaticDimension
    self.paginationEnabled = false
  }
  
  override func queryForTable() -> PFQuery! {
    var query = PFQuery(className: kVYBActivityClassKey)
    query.orderByDescending("createdAt")
    query.includeKey(kVYBActivityVybeKey)
    query.includeKey(kVYBActivityFromUserKey)
    query.whereKey(kVYBActivityToUserKey, equalTo: PFUser.currentUser())
    query.whereKey(kVYBActivityFromUserKey, notEqualTo: PFUser.currentUser())
    let notificationTTL = ConfigManager.sharedInstance.notificationTTL()
    if notificationTTL < 0 {
      let sometimeBefore = NSDate(timeIntervalSinceNow: notificationTTL)
      query.whereKey("createdAt", greaterThanOrEqualTo: sometimeBefore)
    }
    return query
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  // MARK: - TableView data source
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }

  // MARK: - PFQueryTableViewController
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    var cell: ActivityTableViewCell
    let activity = objects[indexPath.row] as PFObject
    let type = activity[kVYBActivityTypeKey] as String
    
    if type == kVYBActivityTypeLike {
      if self.activityHasTag(activity) {
        cell = self.tableView.dequeueReusableCellWithIdentifier("FavoriteActivityCellIdentifier") as ActivityTableViewCell
      } else {
        cell = self.tableView.dequeueReusableCellWithIdentifier("FavoriteActivityCellNoTagIdentifier") as ActivityTableViewCell
      }
    } else {
      cell = self.tableView.dequeueReusableCellWithIdentifier("FollowActivityCellIdentifier") as ActivityTableViewCell
    }
    
    cell.tag = indexPath.row
    cell.setActivity(activity)
    
    return cell
  }
  
  // NOTE: - if an argument is PFObject, breakpoint anywhere in this file causes a crash
  private func activityHasTag(activity: AnyObject) -> Bool {
    if let tags = activity.objectForKey!(kVYBActivityVybeKey)?.objectForKey!(kVYBVybeHashtagsKey) as? [AnyObject] {
      if tags.count > 0 {
        return true
      }
    }

    return false
  }

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
 
    let activityObj = objects[indexPath.row] as PFObject
    if let vybeObj = activityObj[kVYBActivityVybeKey] as? PFObject {
      if let userObj = vybeObj[kVYBVybeUserKey] as? PFObject {
        vybeObj[kVYBVybeUserKey] = userObj
        let playerVC = VYBPlayerViewController(nibName: "VYBPlayerViewController", bundle: nil)
        playerVC.delegate = self
        playerVC.playOnce(vybeObj)
      }
    }
  }
  
  func playerViewController(playerVC: VYBPlayerViewController!, didFinishSetup ready: Bool) {
    if ready {
      self.presentViewController(playerVC, animated: true) {
        playerVC.playCurrentItem()
      }
    }
  }
}
