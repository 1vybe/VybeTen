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
  @IBOutlet weak var addButton: UIButton!
  @IBOutlet weak var leaveButton: UIButton!
  
  var editable: Bool = false
  
  var members: AnyObject = []
  
  @IBAction func doneButtonPressed(sender: AnyObject) {
//    super.saveTribe({ () -> () in
//      self.navigationController?.popViewControllerAnimated(true)
//    })
  }
  
  @IBAction func backButtonPressed(sender: AnyObject) {
    self.navigationController?.popViewControllerAnimated(true)
  }
  
  @IBAction func leaveButtonPressed(sender: AnyObject) {
    
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let tribeName = tribeObj?[kVYBTribeNameKey] as? String {
      self.navigationItem.title = tribeName
    }
    
    if let coordinator = tribeObj?[kVYBTribeCoordinatorKey] as? PFObject,
      let name = coordinator[kVYBUserUsernameKey] as? String {
      let nameText: String
        if coordinator.objectId == PFUser.currentUser().objectId {
          editable = true
          nameText = "You"
        } else {
          nameText = name
        }
        
        coordinatorName.text = nameText
    }
  }  

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    tribeObj?.fetchFromLocalDatastoreInBackgroundWithBlock({ (obj: PFObject!, error: NSError!) -> Void in
      if let relation = obj.relationForKey(kVYBTribeMembersKey),
        let currUsername = PFUser.currentUser().objectForKey(kVYBUserUsernameKey) as? String,
        let coordUsername = obj[kVYBTribeCoordinatorKey].objectForKey(kVYBUserUsernameKey) as? String {
          let query = relation.query()
          query.whereKey(kVYBUserUsernameKey, notEqualTo: currUsername)
          query.whereKey(kVYBUserUsernameKey, notEqualTo: coordUsername)
          query.findObjectsInBackgroundWithBlock({ (result: [AnyObject]!, error: NSError!) -> Void in
            if error == nil {
              self.members = result
              self.tableView.reloadData()
            }
          })
      }
    })
  }
  
  // MARK: - UITableViewDelegate & UITableViewDateSource
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return members.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("TribeMemberTableCellIdentifier") as! UITableViewCell
    
    if let member = members[indexPath.row] as? PFObject,
      let username = member[kVYBUserUsernameKey] as? String,
      let usernameLabel = cell.viewWithTag(123) as? UILabel {
        usernameLabel.text = username
    }
    
    return cell
  }
  
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if let addMemberVC = segue.destinationViewController as? AddMemberViewController
      where segue.identifier == "ShowAddMemberSegue" {
        addMemberVC.currTribe = tribeObj
    }
  }
  
}
