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
  var allUsers: [AnyObject] = []
  var members: [AnyObject] = []
  
  @IBOutlet weak var tableView: UITableView!
  
  @IBAction func backButtonPressed(sender: AnyObject) {
    self.navigationController?.popViewControllerAnimated(true)
  }
  
  @IBAction func doneButtonPressed(sender: AnyObject) {
    if let tribe = currTribe as? PFObject,
      let relation = tribe.relationForKey(kVYBTribeMembersKey),
      let array = members as? [PFObject] {
        for member in array {
          // NOTE: - PFObject related to member must be pinned 
          relation.addObject(member)
        }
        
      self.navigationController?.popViewControllerAnimated(true)
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.allowsMultipleSelection = true
    
    if let localQuery = currTribe?.relationForKey(kVYBTribeMembersKey).query() {
      localQuery.fromLocalDatastore()
      localQuery.findObjectsInBackgroundWithBlock({ (objects: [AnyObject]!, error: NSError!) -> Void in
        if let members = objects as? [PFObject] where error == nil {
          var usernames = [String]()
          for member in members {
            if let username = member[kVYBUserUsernameKey] as? String {
              usernames += [username]
            }
          }
          
          let query = PFUser.query()
          query.whereKey(kVYBUserUsernameKey, notContainedIn: usernames)
          query.whereKey(kVYBUserUsernameKey, notEqualTo: PFUser.currentUser()[kVYBUserUsernameKey])
          query.findObjectsInBackgroundWithBlock { (result: [AnyObject]!, error: NSError!) -> Void in
            if result != nil {
              self.allUsers = result
              self.tableView.reloadData()
            }
          }
        }
      })
    }
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return allUsers.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("AddMemberTableCell") as! UITableViewCell
    
    if let member = allUsers[indexPath.row] as? PFObject,
      let username = member[kVYBUserUsernameKey] as? String,
      let usernameLabel = cell.viewWithTag(123) as? UILabel {
        usernameLabel.text = username
    }
    
    return cell
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {   
    if let cell = tableView.cellForRowAtIndexPath(indexPath),
      let checkBox = cell.viewWithTag(235) as? UIButton,
      let user = allUsers[indexPath.row] as? PFObject {
        checkBox.selected = true
        self.addMember(user)
    }
  }
  
  func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
    if let cell = tableView.cellForRowAtIndexPath(indexPath),
      let checkBox = cell.viewWithTag(235) as? UIButton,
      let user = allUsers[indexPath.row] as? PFObject {
        checkBox.selected = false
        self.removeMember(user)
    }
  }
  
  private func addMember(user: AnyObject) {
    if let array = members as? [PFObject],
      let user = user as? PFObject {
        for member in array {
          if member.objectId == user.objectId {
            return
          }
        }
        self.members += [user]
    }
  }
  
  private func removeMember(user: AnyObject) {
    var newMembers = [PFObject]()
    
    if let array = members as? [PFObject],
      let user = user as? PFObject {
        for member in array {
          if member.objectId != user.objectId {
            newMembers += [member]
          }
        }
        self.members = newMembers
    }
  }
  
  
}
