//
//  ActivityTableViewController.swift
//  VybeTen
//
//  Created by Jinsu Kim on 1/14/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class ActivityTableViewController: PFQueryTableViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
        
    let textAttributes = NSMutableDictionary()
    if let font = UIFont(name: "HelveticaNeue-Medium", size: 18.0) {
      let textColor = UIColor(red: 92.0/255.0, green: 140.0/255.0, blue: 242.0/255.0, alpha: 1.0)
      textAttributes.setObject(font, forKey: NSFontAttributeName)
      textAttributes.setObject(textColor, forKey: NSForegroundColorAttributeName)
      self.navigationController?.navigationBar.titleTextAttributes = textAttributes
    }
    
    self.tableView.estimatedRowHeight = 128.0
    self.tableView.rowHeight = UITableViewAutomaticDimension
    self.paginationEnabled = false
  }
  
  
  override func queryForTable() -> PFQuery! {
    var query: PFQuery! = PFQuery(className: kVYBActivityClassKey)
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
  
  // MARK: - PFQueryTableViewController
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    var cell: ActivityTableViewCell
    let activity = objects[indexPath.row] as PFObject
    
    if self.activityHasTag(activity) {
     cell = self.tableView.dequeueReusableCellWithIdentifier("ActivityPostTableCellIdentifier") as ActivityTableViewCell
    } else {
      cell = self.tableView.dequeueReusableCellWithIdentifier("ActivityPostTableCellNoTagIdentifier") as ActivityTableViewCell
    }
    
    if let vybe = activity[kVYBActivityVybeKey] as? PFObject {
      cell.setVybe(vybe)
    }
    
    if let user = activity[kVYBActivityFromUserKey] as? PFObject {
      cell.setUser(user)
    }
    
    return cell
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
