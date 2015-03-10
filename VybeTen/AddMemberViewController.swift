//
//  AddMemberViewController.swift
//  Vybe
//
//  Created by Jinsu Kim on 2/22/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class AddMemberViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating {
  var currTribe: AnyObject?
  
  var userObjs = [AnyObject]()
  var filteredObjs = [AnyObject]()
  var newMemberObjs = [AnyObject]()
  
  var searchController: UISearchController?
  
  @IBOutlet weak var tableView: UITableView!
  
  @IBAction func backButtonPressed(sender: AnyObject) {
    self.navigationController?.popViewControllerAnimated(true)
  }
  
  @IBAction func doneButtonPressed(sender: AnyObject) {
    if let tribe = currTribe as? PFObject {
      let relation = tribe.relationForKey(kVYBTribeMembersKey)
      if let array = newMemberObjs as? [PFObject] {
        for member in array {
          relation.addObject(member)
        }
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        tribe.saveInBackgroundWithBlock({ (success: Bool, error: NSError!) -> Void in
          MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
          self.navigationController?.popViewControllerAnimated(true)
        })
        
        // Update the role for ACL fo this tribe
        let roleName = "membersOf_" + tribe.objectId
        let query = PFRole.query()
        query.whereKey("name", equalTo: roleName)
        query.getFirstObjectInBackgroundWithBlock({ (first: PFObject!, error: NSError!) -> Void in
          if error == nil {
            let role = first as PFRole
            let users = role.users
            
            for usr in array {
              users.addObject(usr)
            }
            
            role.saveEventually()
          }
        })
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.allowsMultipleSelection = true

    self.tableView.tableFooterView = UIView()
    
    // SearchController
    let searchController = UISearchController(searchResultsController: nil)
    searchController.searchResultsUpdater = self
    searchController.searchBar.sizeToFit()
    
    // b/c we are using the same view for a search result
    searchController.dimsBackgroundDuringPresentation = false
    searchController.hidesNavigationBarDuringPresentation = false
    self.tableView.tableHeaderView = searchController.searchBar
    self.searchController = searchController
    
    self.definesPresentationContext = true
    
    if let relationQuery = currTribe?.relationForKey(kVYBTribeMembersKey).query() {
      let query = PFUser.query()
      query.whereKey(kVYBUserUsernameKey, doesNotMatchKey: kVYBUserUsernameKey, inQuery: relationQuery)
      query.findObjectsInBackgroundWithBlock({ (result: [AnyObject]!, error: NSError!) -> Void in
        if error == nil {
          self.userObjs = result
          self.filteredObjs = result
          self.tableView.reloadData()
        }
      })
    }
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return filteredObjs.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("AddMemberTableCellIdentifier") as UITableViewCell
    
    let user = filteredObjs[indexPath.row] as PFObject

    if let usernameLabel = cell.viewWithTag(123) as? UILabel {
      if let username = user[kVYBUserUsernameKey] as? String {
        usernameLabel.text = username
      }
    }

    if let checkBox = cell.viewWithTag(235) as? UIImageView {
      checkBox.hidden = !self.membersInclude(user)
    }
  
    return cell
  }
  
  // MARK: - SearchControllerDelegate
  func updateSearchResultsForSearchController(searchController: UISearchController) {
    self.filterContentsForSearchText(searchController.searchBar.text)
    self.tableView.reloadData()
  }
  
  // MARK: - Helper Functions
  private func filterContentsForSearchText(searchTxt: String) {
    if searchTxt == "" {
      self.filteredObjs = self.userObjs
      return
    }
    
    self.filteredObjs = self.userObjs.filter({ (usr: AnyObject) -> Bool in
      if let username = usr.objectForKey(kVYBUserUsernameKey) as? String {
        let stringMatch = username.lowercaseString.rangeOfString(searchTxt.lowercaseString)
        return (stringMatch != nil)
      } else {
        return false
      }
    })
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
    if let cell = tableView.cellForRowAtIndexPath(indexPath) {
      let user = filteredObjs[indexPath.row] as PFObject
      self.addMember(user)

      if let checkBox = cell.viewWithTag(235) as? UIImageView {
        checkBox.hidden = false
      }
    }
  }
  
  func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
    if let cell = tableView.cellForRowAtIndexPath(indexPath) {
      let user = filteredObjs[indexPath.row] as PFObject
      self.removeMember(user)

      if let checkBox = cell.viewWithTag(235) as? UIImageView {
        checkBox.hidden = true
      }
    }
  }
  
  private func addMember(user: AnyObject) {
    if let array = newMemberObjs as? [PFObject] {
      let user = user as PFObject
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
    
    if let array = newMemberObjs as? [PFObject] {
      let user = user as PFObject
      for member in array {
        if member.objectId != user.objectId {
          newArray += [member]
        }
      }
      self.newMemberObjs = newArray
    }
  }
  
  
}
