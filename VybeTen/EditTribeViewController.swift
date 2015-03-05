	//
//  EditTribeViewController.swift
//  Vybe
//
//  Created by Jinsu Kim on 2/22/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class EditTribeViewController: TribeDetailsViewController, UITableViewDelegate, UITableViewDataSource  {
  @IBOutlet weak var coordinatorName: UILabel!
  @IBOutlet weak var leaveButton: UIButton!
  
  var editable: Bool = false
  
  var members: [AnyObject] = []
  
  @IBAction func backButtonPressed(sender: AnyObject) {
    self.navigationController?.popViewControllerAnimated(true)
  }
  
  @IBAction func leaveButtonPressed(sender: AnyObject) {
    if let trb = tribeObj as? PFObject {
      // In case you are an admin, assign a coordinator title and role to a random person
      if editable {
        if let first = members.first as? PFObject {
          trb[kVYBTribeCoordinatorKey] = first
          
          PFCloud.callFunctionInBackground("grantRole", withParameters: ["userId" : first.objectId, "tribeId" : trb.objectId])
        }
      }
      
      // First remove from members
      let relation = trb.relationForKey(kVYBTribeMembersKey)
      relation.removeObject(PFUser.currentUser())
      
      MBProgressHUD.showHUDAddedTo(self.view, animated: true)
      trb.saveInBackgroundWithBlock({ (success: Bool, error: NSError!) -> Void in
        // Remove the current user from the role
        let params = ["userId" : PFUser.currentUser().objectId, "tribeId" : trb.objectId]
        PFCloud.callFunctionInBackground("removeFromRole", withParameters: params)
        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
        self.navigationController?.popViewControllerAnimated(true)
      })
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let tribeName = tribeObj?[kVYBTribeNameKey] as? String {
      self.navigationItem.title = tribeName
    }
    
    if let coordinator = tribeObj?[kVYBTribeCoordinatorKey] as? PFObject {
      if let name = coordinator[kVYBUserUsernameKey] as? String {
        var nameText: String = "You"
        if coordinator.objectId == PFUser.currentUser().objectId {
          editable = true
        } else {
          nameText = name
          // Add bar button on a navigation bar only appears if you were an admin
          self.navigationItem.rightBarButtonItems?.removeAtIndex(0)
        }
        
        coordinatorName.text = nameText
      }
    }
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    if let trb = tribeObj as? PFObject {
      let relation = trb.relationForKey(kVYBTribeMembersKey)
      let query = relation.query()
      var list = [String]()
      if let currUsername = PFUser.currentUser().objectForKey(kVYBUserUsernameKey) as? String {
        list += [currUsername]
      }
      if let coordUsername = trb[kVYBTribeCoordinatorKey].objectForKey(kVYBUserUsernameKey) as? String {
        list += [coordUsername]
      }
      // Show users except for the coordinator and current user
      query.whereKey(kVYBUserUsernameKey, notContainedIn:list)
      
      MBProgressHUD.showHUDAddedTo(self.view, animated: true)
      query.findObjectsInBackgroundWithBlock({ (result: [AnyObject]!, error: NSError!) -> Void in
        if error == nil {
          self.members = result
          self.tableView.reloadData()
        }
        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
      })
    }
  }
  
  // MARK: - UITableViewDelegate & UITableViewDateSource
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return members.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("TribeMemberCellIdentifier") as UITableViewCell
    
    let member = members[indexPath.row] as PFObject
    if let memberName = member[kVYBUserUsernameKey] as? String {
      if let usernameLabel = cell.viewWithTag(123) as? UILabel {
        usernameLabel.text = memberName
      }
    }
    
    return cell
  }
  
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "ShowAddMemberSegue" {
      if let addMemberVC = segue.destinationViewController as? AddMemberViewController {
        addMemberVC.currTribe = tribeObj
      }
    }
  }
  
  func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return editable
  }
  
  func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == UITableViewCellEditingStyle.Delete {
      if let tribe = tribeObj as? PFObject {
        let relation = tribe.relationForKey(kVYBTribeMembersKey)
        if let usr = members[indexPath.row] as? PFObject {
          relation.removeObject(usr)
          
          MBProgressHUD.showHUDAddedTo(self.view, animated: true)
          tribe.saveInBackgroundWithBlock({ (success: Bool, error: NSError!) -> Void in
            if error == nil {
              // Update the role
              let params = ["userId": usr.objectId, "tribeId" : tribe.objectId]
              PFCloud.callFunctionInBackground("removeFromRole", withParameters: params)
              
              self.removeMember(usr)
              // Animate a cell deletion
              self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            }
            MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
          })
        }
      }
    }
  }
  
  private func removeMember(usr: AnyObject) {
    var newArr: [AnyObject] = []
    for m in members {
      if m !== usr {
        newArr += [m]
      }
    }
    
    members = newArr
  }
  
  func scrollViewDidScroll(scrollView: UIScrollView) {
    let velocity = scrollView.panGestureRecognizer.velocityInView(scrollView).y
    if velocity > 0 {
      leaveButton.hidden = false
    } else if velocity < 0 {
      leaveButton.hidden = true
    }
  }
  
}
