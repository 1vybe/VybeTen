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
  
  private var blockedUsers: [PFUser]?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = false
    
    // Change navigation bar title font style
    let navBarTitleTextAttributes = [ NSForegroundColorAttributeName: UIColor(red: 96/255.0, green: 96/255.0, blue: 96/255.0, alpha: 1.0) ]
    if let navigationBar = self.navigationController?.navigationBar {
      navigationBar.titleTextAttributes = navBarTitleTextAttributes
    }
    
    blockedUsers = VYBCache.sharedCache().usersBlockedByMe() as? [PFUser]
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
    if let array = blockedUsers {
      return array.count
    }
    return 0
  }
  
  override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return 85.0
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("BlockedUserTableCell", forIndexPath: indexPath) as UITableViewCell
    
    if let aUser = blockedUsers?[indexPath.row] {
      if let username = aUser[kVYBUserUsernameKey] as? String {
        let usernameLabel = cell.viewWithTag(33) as? UILabel
        usernameLabel?.text = username
      }
    }
    
    if let switchButton = cell.viewWithTag(77) as? UIButton {
      switchButton.tag = indexPath.row
      switchButton.addTarget(self, action: "toggleSwitch:", forControlEvents: UIControlEvents.TouchUpInside)
    }
    return cell
  }
  
  func toggleSwitch(sender: AnyObject) {
    let buttonP = sender as UIButton
    let indexPath = NSIndexPath(forRow: buttonP.tag, inSection: 0)
    if let cell = self.tableView.cellForRowAtIndexPath(indexPath) {
      // switch button
      if let switchButton = cell.viewWithTag(12) as? UIButton {
        if !switchButton.selected {
          if let aUser = self.blockedUsers?[buttonP.tag] {
            let currUser = PFUser.currentUser()
            let blacklist = currUser.relationForKey(kVYBUserBlockedUsersKey)
            blacklist.removeObject(aUser)
            currUser.saveEventually()
            VYBCache.sharedCache().removeBlockedUser(aUser, forUser: currUser)
            self.blockedUsers = VYBCache.sharedCache().usersBlockedByMe() as? [PFUser]
            UIView.animateWithDuration(0.6, delay: 0.0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: { () -> Void in
              switchButton.selected = true
              // switch label
              let switchLabel = cell.viewWithTag(28) as? UILabel
              switchLabel?.text = "UNBLOCKED"
              switchLabel?.textColor = UIColor(red: 92/255.0, green: 140/255.0, blue: 242/255.0, alpha: 1.0)
              }, completion: { (completed: Bool) -> Void in
                self.delay(0.4) {
                  self.tableView.beginUpdates()
                  self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Middle)
                  self.tableView.endUpdates()
                }
            })
          }
        }
      }
    }
    
    // need to reset it back to 77
    buttonP.tag = 77
  }
  
  func delay(delay:Double, closure:()->()) {
    dispatch_after(
      dispatch_time(
        DISPATCH_TIME_NOW,
        Int64(delay * Double(NSEC_PER_SEC))
      ),
      dispatch_get_main_queue(), closure)
  }
  
  /*
  // Override to support conditional editing of the table view.
  override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
  // Return NO if you do not want the specified item to be editable.
  return true
  }
  */
  
  /*
  // Override to support editing the table view.
  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
  if editingStyle == .Delete {
  // Delete the row from the data source
  tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
  } else if editingStyle == .Insert {
  // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
  }
  }
  */
  
  /*
  // Override to support rearranging the table view.
  override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
  
  }
  */
  
  /*
  // Override to support conditional rearranging of the table view.
  override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
  // Return NO if you do not want the item to be re-orderable.
  return true
  }
  */
  
  /*
  // MARK: - Navigation
  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
  // Get the new view controller using [segue destinationViewController].
  // Pass the selected object to the new view controller.
  }
  */
  
}