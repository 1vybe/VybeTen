//
//  ActivityTableViewController.swift
//  VybeTen
//
//  Created by Jinsu Kim on 1/14/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class ActivityTableViewController: PFQueryTableViewController {
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    parseClassName = kVYBActivityClassKey
    pullToRefreshEnabled = true
    paginationEnabled = true
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let textAttributes = NSMutableDictionary()
    if let font = UIFont(name: "HelveticaNeue-Medium", size: 18.0) {
      let textColor = UIColor(red: 92.0/255.0, green: 140.0/255.0, blue: 242.0/255.0, alpha: 1.0)
      textAttributes.setObject(font, forKey: NSFontAttributeName)
      textAttributes.setObject(textColor, forKey: NSForegroundColorAttributeName)
      self.navigationController?.navigationBar.titleTextAttributes = textAttributes
    }
  }
  
  override func queryForTable() -> PFQuery! {
    var query = PFQuery(className: kVYBActivityClassKey)
    query.orderByDescending("createdAt")
    query.includeKey(kVYBActivityVybeKey)
    query.includeKey(kVYBActivityFromUserKey)
    query.whereKey(kVYBActivityTypeKey, equalTo: kVYBActivityTypeLike)
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
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    var cell =  self.tableView.dequeueReusableCellWithIdentifier("ActivityPostTableCellIdentifier", forIndexPath: indexPath) as ActivityTableViewCell
    
    let activity = self.objects[indexPath.row] as PFObject
    cell.hashtagLabel.hidden = !self.activityHasTag(activity)
    
    if let vybe = activity[kVYBActivityVybeKey] as? PFObject {
      cell.setVybe(vybe)
    }
    
    if let user = activity[kVYBActivityFromUserKey] as? PFObject {
      cell.setUser(user)
    }
    
    return cell
  }

  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    let activity = objects[indexPath.row] as PFObject
    if self.activityHasTag(activity) {
      return 128.0
    } else {
      return 83.0
    }
  }
  
  private func activityHasTag(activity: PFObject) -> Bool {
    if let vybe = activity[kVYBActivityVybeKey] as? PFObject {
      if let tags = vybe[kVYBVybeHashtagsKey] as? [AnyObject] {
        if tags.count > 0 {
          // NOTE: - breakpoint here causes a crash in debugger
          return true
        }
      }
    }
    return false
  }
  
}
