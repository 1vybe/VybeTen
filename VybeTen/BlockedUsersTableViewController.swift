//
//  BlockedUsersTableViewController.swift
//  VybeTen
//
//  Created by Jinsu Kim on 12/8/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit

class BlockedUsersTableViewController: UITableViewController {
  @IBAction func cancelButtonPressed(sender: AnyObject) {
    self.navigationController?.popViewControllerAnimated(false)
  }
  
  private var blockedUsers: [AnyObject]!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.tableView.allowsSelection = false
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = false
    
    var textAttributes = [NSObject : AnyObject]()
    if let font = UIFont(name: "Avenir Next", size: 14.0) {
      let textColor = UIColor(red: 247.0/255.0, green: 76.0/255.0, blue: 70.0/255.0, alpha: 1.0)
      textAttributes[NSFontAttributeName] = font
      textAttributes[NSForegroundColorAttributeName] = textColor
      self.navigationController?.navigationBar.titleTextAttributes = textAttributes
    }
    
    blockedUsers = []
    
    let relation = PFUser.currentUser().relationForKey(kVYBUserBlockedUsersKey)
    let userQuery = relation.query()
    userQuery.findObjectsInBackgroundWithBlock { (result: [AnyObject]!, error: NSError!) -> Void in
      if error == nil {
//        VYBCache.sharedCache().setBlockedUsers(result, forUser: PFUser.currentUser())
        if result.count > 0 {
          self.blockedUsers = result as [PFUser]
          self.tableView.reloadData()
        }
      }
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
    blockedUsers = nil
  }
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    // #warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return blockedUsers.count
  }
  
  override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return 85.0
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("BlockedUserTableCell", forIndexPath: indexPath) as UITableViewCell
    
    if let aUser = blockedUsers[indexPath.row] as? PFUser {
      if let username = aUser[kVYBUserUsernameKey] as? String {
        let usernameLabel = cell.viewWithTag(33) as? UILabel
        usernameLabel?.text = username
      }
    }
    
    if let switchButton = cell.viewWithTag(77) as? UIButton {
      switchButton.superview?.tag = indexPath.row
      switchButton.addTarget(self, action: "toggleSwitch:", forControlEvents: UIControlEvents.TouchUpInside)
    }
    return cell
  }

  func toggleSwitch(sender: AnyObject!) {
    if let parentView = sender.superview! {
      let row = parentView.tag
      let indexPath = NSIndexPath(forRow: row, inSection: 0)
      if let cell = self.tableView.cellForRowAtIndexPath(indexPath) {
        // switch button
        if let switchButton = cell.viewWithTag(12) as? UIButton {
          if !switchButton.selected {
            if let aUser = blockedUsers[row] as? PFUser {
              let currUser = PFUser.currentUser()
              let blacklist = currUser.relationForKey(kVYBUserBlockedUsersKey)
              blacklist.removeObject(aUser)
              currUser.saveInBackgroundWithBlock(nil)
              
              UIView.animateWithDuration(0.6, delay: 0.0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: { () -> Void in
                switchButton.selected = true
                // switch label
                let switchLabel = cell.viewWithTag(28) as? UILabel
                switchLabel?.text = "UNBLOCKED"
                switchLabel?.textColor = UIColor(red: 92/255.0, green: 140/255.0, blue: 242/255.0, alpha: 1.0)
                }, completion: { (completed: Bool) -> Void in
                  self.delay(0.4) {
//                    VYBCache.sharedCache().removeBlockedUser(aUser, forUser: currUser)
                    self.removeUserFromBlockedUsers(aUser)
                    println("\(aUser[kVYBUserUsernameKey]) unblocked!")
                    //                  self.blockedUsers?.
                    self.tableView.beginUpdates()
                    self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Middle)
                    self.tableView.endUpdates()
                    
                    self.tableView.reloadData()
                  }
              })
            }
          }
        }
      }
    }
  }
  
  private func removeUserFromBlockedUsers(user: PFUser) {
    let count = blockedUsers.count
    if count > 0 {
      var index = 0
      for idx in 0...count - 1 {
        if blockedUsers[idx].objectId == user.objectId {
          index = idx
          break
        }
      }
      blockedUsers.removeAtIndex(index)
    }
  }
  
  func delay(delay:Double, closure:()->()) {
    dispatch_after(
      dispatch_time(
        DISPATCH_TIME_NOW,
        Int64(delay * Double(NSEC_PER_SEC))
      ),
      dispatch_get_main_queue(), closure)
  }

  override func supportedInterfaceOrientations() -> Int {
    return Int(UIInterfaceOrientationMask.Portrait.rawValue)
  }
  
}
