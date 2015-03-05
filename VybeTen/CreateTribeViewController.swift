//
//  CreateTribeViewController.swift
//  Vybe
//
//  Created by Jinsu Kim on 2/22/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

protocol CreateTribeDelegate {
  func didCancelTribe()
  func didCreateTribe(tribe: AnyObject)
}

class CreateTribeViewController: TribeDetailsViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
  var delegate: CreateTribeDelegate?
  
  @IBOutlet weak var nameText: UITextField!
  @IBOutlet weak var coordinatorName: UILabel!
  @IBOutlet weak var createButton: UIButton!
  @IBOutlet weak var bottomSpacing: NSLayoutConstraint!
  
  var allUsers: [AnyObject] = []
  var members: [AnyObject] = []
  
  @IBAction func createButtonPressed(sender: AnyObject) {
    self.saveTribe({ () -> () in
      if let trb = self.tribeObj as? PFObject {
        self.delegate?.didCreateTribe(trb)
      }
    })
  }
  
  @IBAction func cancelButtonPressed(sender: AnyObject) {
    tribeObj?.unpinInBackgroundWithName("MyTribes")
    self.delegate?.didCancelTribe()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.allowsMultipleSelection = true

    if let font = UIFont(name: "Helvetica Neue", size: 18) {
      let attributedStr = NSAttributedString(string: "Name your tribe...", attributes: [NSForegroundColorAttributeName: UIColor(red: 155/255.0, green: 155/255.0, blue: 155/255.0, alpha: 1.0), NSFontAttributeName: font])
      nameText.attributedPlaceholder = attributedStr
    }
    
    // Tap to dismiss a keyboard
    let tapGesture = UITapGestureRecognizer(target: self, action: "dismissKeyboard:")
    tapGesture.cancelsTouchesInView = false
    self.view.addGestureRecognizer(tapGesture)
    
    // Register for keyboard notification
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)

    // Create a tribe object locally
    let trb = PFObject(className: kVYBTribeClassKey)
    trb[kVYBTribeCoordinatorKey] = PFUser.currentUser()
    let relation = trb.relationForKey(kVYBTribeMembersKey)
    relation.addObject(PFUser.currentUser())
    
    trb.pinInBackgroundWithName("MyTribes", block: { (success: Bool, error: NSError!) -> Void in
      if success {
        self.tribeObj = trb
      }
    })
    
    if let relation = trb.relationForKey(kVYBTribeMembersKey) {
      relation.addObject(PFUser.currentUser())
    }
    
    if let username = PFUser.currentUser().objectForKey(kVYBUserUsernameKey) as? String {
      coordinatorName.text = username
      
      let query = PFUser.query()
      query.whereKey(kVYBUserUsernameKey, notEqualTo: username)
      MBProgressHUD.showHUDAddedTo(self.view, animated: true)
      query.findObjectsInBackgroundWithBlock { (result: [AnyObject]!, error: NSError!) -> Void in
        if result != nil {
          self.allUsers = result
          self.tableView.reloadData()
        }
        MBProgressHUD.hideHUDForView(self.view, animated: true)
      }
    }
    
    nameText.becomeFirstResponder()
  }
  
  func saveTribe(closure: (() -> ())?) {
    if let tribe = tribeObj as? PFObject {
      if self.validateTribeName(nameText.text) {
        tribe.setObject(nameText.text, forKey: kVYBTribeNameKey)
        let relation = tribe.relationForKey(kVYBTribeMembersKey)
        if let array = members as? [PFUser] {
          for m in array {
            relation.addObject(m)
          }
        }
        tribe.saveEventually({ (success: Bool, error: NSError!) -> Void in
          if closure != nil {
            closure!()
          }
        })
      }
    } else {
      let alertVC = UIAlertController(title: "Invalid tribe name", message: "A name must be between 2 - 20 in length and consist of alphabets and numbers only.", preferredStyle: UIAlertControllerStyle.Alert)
      alertVC.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
      self.presentViewController(alertVC, animated: true, completion: nil)
    }
  }
  
  // MARK: - UITableViewDelegate
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("AddMemberTableCellIdentifier") as UITableViewCell
    
    let user = allUsers[indexPath.row] as PFObject
    
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
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return allUsers.count
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    if let cell = tableView.cellForRowAtIndexPath(indexPath) {
      let user = allUsers[indexPath.row] as PFObject
      self.addMember(user)

      if let checkBox = cell.viewWithTag(235) as? UIImageView {
        checkBox.hidden = false
      }
    }
  }
  
  func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
    if let cell = tableView.cellForRowAtIndexPath(indexPath) {
      let user = allUsers[indexPath.row] as PFObject
      self.removeMember(user)

      if let checkBox = cell.viewWithTag(235) as? UIImageView {
        checkBox.hidden = true
      }
    }
  }
  
  private func membersInclude(user: AnyObject) -> Bool {
    if let array = members as? [PFObject] {
      for m in array {
        if m.objectId == user.objectId {
          return true
        }
      }
    }
    
    return false
  }
  
  private func addMember(user: AnyObject) {
    let user = user as PFObject

    if let array = members as? [PFObject] {
        for member in array {
          if member.objectId == user.objectId {
            return
          }
        }
        self.members += [user]
    }
  }
  
  private func removeMember(user: AnyObject) {
    let user = user as PFObject
    
    var newMembers = [PFObject]()
    
    if let array = members as? [PFObject] {
        for member in array {
          if member.objectId != user.objectId {
            newMembers += [member]
          }
        }
        self.members = newMembers
    }
  }
  
  // MARK: - UITextFieldDelegate
  func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
    let oldStr = textField.text
    var newStr: String
    
    if string == "" && oldStr != "" {
      newStr = oldStr.substringWithRange(Range<String.Index>(start: oldStr.startIndex, end: advance(oldStr.endIndex, -1)))
    } else {
      newStr = oldStr + string
    }
    
    self.updateCreateButtonAppearance(newStr)
    
    return true
  }
  
  func textFieldDidBeginEditing(textField: UITextField) {
    self.updateCreateButtonAppearance(textField.text)
  }
  
  func textFieldDidEndEditing(textField: UITextField) {
    self.updateCreateButtonAppearance(textField.text)
  }
  
  private func updateCreateButtonAppearance(text: String) {
    if countElements(text) > 2 {
      createButton.hidden = false
    } else {
      createButton.hidden = true
    }
  }
  
  private func validateTribeName(text: String!) -> Bool {
    if countElements(text) < 3 || countElements(text) > 20 {
      return false
    }
    
    let name = text as NSString
    
    return name.isValidTribeName()
  }

  // MARK: - UIKeyboardNotification
  
  func keyboardWillShow(notification: NSNotification) {
    if let userInfo = notification.userInfo {
      if let endFrame = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue() {
        if let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue {
  //      let curve = userInfo[UIKeyboardAnimationCurveUserInfoKey]?.integerValue
          
          let keyboardFrame = self.view.convertRect(endFrame, fromView: self.view.window)
          let keyboardHeight = CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(keyboardFrame)

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
            UIView.animateWithDuration(duration, animations: { () -> Void in
              self.bottomSpacing.constant = keyboardHeight
            })
          })
        }
      }
    }
  }
  
  func keyboardWillHide(notification: NSNotification) {
    if let userInfo = notification.userInfo {
      if let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
          UIView.animateWithDuration(duration, animations: { () -> Void in
            self.bottomSpacing.constant = 0
          })
        })
      }
    }
  }
  
  func dismissKeyboard(recognizer: UIGestureRecognizer) {
    self.view.endEditing(true)
  }

}
