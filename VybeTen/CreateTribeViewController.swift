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

class CreateTribeViewController: TribeDetailsViewController {
  var delegate: CreateTribeDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()
    
    let trb = PFObject(className: kVYBTribeClassKey)
    trb[kVYBTribeCoordinatorKey] = PFUser.currentUser()
    let relation = trb.relationForKey(kVYBTribeMembersKey)
    relation.addObject(PFUser.currentUser())
    
    let ACL = PFACL(user: PFUser.currentUser())
    ACL.setPublicReadAccess(true)
    trb.ACL = ACL
    
    trb.pinInBackgroundWithName("MyTribes", block: { (success: Bool, error: NSError!) -> Void in
      if success {
        self.tribeObj = trb
      }
    })
    
    self.nameText.becomeFirstResponder()
  }
  
  @IBAction func createButtonPressed(sender: AnyObject) {
    super.saveTribe({ () -> () in
      if let trb = self.tribeObj as? PFObject {
        self.delegate?.didCreateTribe(trb)
      }
    })
  }
  
  @IBAction func cancelButtonPressed(sender: AnyObject) {
    tribeObj?.unpinInBackgroundWithName("MyTribes", block: { (success: Bool, error: NSError!) -> Void in
      self.delegate?.didCancelTribe()
    })
  }
}
