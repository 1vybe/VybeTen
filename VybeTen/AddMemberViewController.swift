//
//  AddMemberViewController.swift
//  Vybe
//
//  Created by Jinsu Kim on 2/22/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class AddMemberViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {  
  var currTribe: AnyObject?
  var userObjs: [AnyObject] = []
  var newMemberObjs: [AnyObject] = []
  
  @IBOutlet weak var tableView: UITableView!
  
  @IBAction func backButtonPressed(sender: AnyObject) {
    self.navigationController?.popViewControllerAnimated(true)
  }
  
  @IBAction func doneButtonPressed(sender: AnyObject) {
//    delegate?.didAddMembers(newMemberObjs)

    if let tribe = currTribe as? PFObject, relation = tribe.relationForKey(kVYBTribeMembersKey),
          let array = newMemberObjs as? [PFObject] {
        for member in array {
          relation.addObject(member)
        }
        tribe.saveEventually()
        
        // Update the role for ACL fo this tribe
        let roleName = "membersOf_" + tribe.objectId
        let query = PFRole.query()
        query.whereKey("name", equalTo: roleName)
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        query.getFirstObjectInBackgroundWithBlock({ (first: PFObject!, error: NSError!) -> Void in
          if error == nil {
            let role = first as! PFRole
            let users = role.users
            
            for usr in array {
              users.addObject(usr)
            }
            
            role.saveInBackgroundWithBlock({ (success: Bool, error: NSError!) -> Void in
              MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
              self.navigationController?.popViewControllerAnimated(true)
            })
          } else {
            MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
            self.navigationController?.popViewControllerAnimated(true)
          }
        })
    }
    
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.allowsMultipleSelection = true

    self.tableView.tableFooterView = UIView()
    
    if let relationQuery = currTribe?.relationForKey(kVYBTribeMembersKey).query() {
      let query = PFUser.query()
      query.whereKey(kVYBUserUsernameKey, doesNotMatchKey: kVYBUserUsernameKey, inQuery: relationQuery)
      query.findObjectsInBackgroundWithBlock({ (result: [AnyObject]!, error: NSError!) -> Void in
        if error == nil {
          self.userObjs = result
          self.tableView.reloadData()
        }
      })
    }
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return userObjs.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("AddMemberTableCellIdentifier") as! UITableViewCell
    
    if let user = userObjs[indexPath.row] as? PFObject,
      username = user[kVYBUserUsernameKey] as? String,
      usernameLabel = cell.viewWithTag(123) as? UILabel,
      checkBox = cell.viewWithTag(235) as? UIImageView {
        usernameLabel.text = username
        
        checkBox.hidden = !self.membersInclude(user)
    }
    
    return cell
  }
  
  private func membersInclude(user: AnyObject) -> Bool {
    if let members = newMemberObjs as? [PFObject] {
      for member in members {
        if member.objectId == user.objectId {
          return true
        }
      }
    }
    
    return false
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {   
    if let cell = tableView.cellForRowAtIndexPath(indexPath),
      let checkBox = cell.viewWithTag(235) as? UIImageView,
      let user = userObjs[indexPath.row] as? PFObject {
        checkBox.hidden = false
        self.addMember(user)
    }
  }
  
  func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
    if let cell = tableView.cellForRowAtIndexPath(indexPath),
      let checkBox = cell.viewWithTag(235) as? UIImageView,
      let user = userObjs[indexPath.row] as? PFObject {
        checkBox.hidden = true
        self.removeMember(user)
    }
  }
  
  private func addMember(user: AnyObject) {
    if let array = newMemberObjs as? [PFObject],
      let user = user as? PFObject {
        for member in array {
          if member.objectId == user.objectId {
            return
          }
        }
        self.newMemberObjs += [user]
    }
  }
  
  private func removeMember(user: AnyObject) {
    var newArray = [PFObject]()
    
    if let array = newMemberObjs as? [PFObject],
      let user = user as? PFObject {
        for member in array {
          if member.objectId != user.objectId {
            newArray += [member]
          }
        }
        self.newMemberObjs = newArray
    }
  }
  
  
}
