//
//  ActivityTableViewController.swift
//  VybeTen
//
//  Created by Jinsu Kim on 1/14/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class ActivityTableViewController: UITableViewController {
  var activities = [PFObject]()
  
  @IBAction func closeButtonPressed() {
    self.navigationController?.popViewControllerAnimated(true)
  }
    
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let textAttributes = NSMutableDictionary()
    if let font = UIFont(name: "HelveticaNeueu Medium", size: 18.0) {
      let textColor = UIColor(red: 92.0/255.0, green: 140.0/255.0, blue: 40.0/255.0, alpha: 1.0)
      textAttributes.setObject(font, forKey: NSFontAttributeName)
      textAttributes.setObject(textColor, forKey: NSForegroundColorAttributeName)
      self.navigationController?.navigationBar.titleTextAttributes = textAttributes
    }
    
    VYBCache.sharedCache().refreshBumpsForMeInBackground { (success: Bool) -> Void in
      if success {
        self.reloadActivitiesForMe()
      }
    }
    
    self.tableView.estimatedRowHeight = 127.0
//    self.tableView.rowHeight = UITableViewAutomaticDimension
  }
  
  private func reloadActivitiesForMe() {
    activities = []
    if let newObjs = VYBCache.sharedCache().bumpActivitiesForUser(PFUser.currentUser()) as? [PFObject] {
      // we do NOT want to include vybes from ourself
      for activity in newObjs {
        if let fromUser = activity[kVYBActivityFromUserKey] as? PFObject {
          if fromUser.objectId != PFUser.currentUser() .objectId {
            activities += [activity]
          }
        }
      }
    }
    
    activities.sort { (activity1: PFObject, activity2: PFObject) -> Bool in
      let comparisonResult = activity1.createdAt.compare(activity2.createdAt)
      return comparisonResult == NSComparisonResult.OrderedDescending
    }
    
    println("reloading \(activities.count) objects")
    self.tableView.reloadData()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  // MARK: - Table view data source
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return activities.count
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("ActivityPostTableCellIdentifier", forIndexPath: indexPath) as PostTableViewCell
    
    let activity = activities[indexPath.row]
    if let vybe = activity[kVYBActivityVybeKey] as? PFObject {
      cell.setVybe(vybe)
    }
    if let user = activity[kVYBActivityFromUserKey] as? PFObject {
      cell.setFromUser(user)
    }
    cell.setNeedsDisplay()
    
    return cell
  }
}
