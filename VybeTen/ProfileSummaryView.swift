//
//  ProfileSummaryView.swift
//  Vybe
//
//  Created by Jinsu Kim on 2/7/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class ProfileSummaryView: UIView {
  var delegate: ProfileSummaryViewDelegate?

  @IBOutlet weak var listViewButton: UIButton!
  @IBOutlet weak var collectionViewButton: UIButton!
  @IBOutlet weak var usernameLabel: UILabel!
  @IBOutlet weak var settingsButton: UIButton!
  
  @IBAction func listViewButtonPressed(sender: AnyObject) {
    if !listViewButton.selected {
      delegate?.showListView()
    }
  }
  
  @IBAction func collectionViewButtonPressed(sender: AnyObject) {
    if !collectionViewButton.selected {
      delegate?.showCollectionView()
    }
  }
  
  @IBAction func settingsButtonPressed(sender: AnyObject) {
    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
    let unblockAction = UIAlertAction(title: "Show Blocked Users", style: UIAlertActionStyle.Default, handler: nil)
    let logOutAction = UIAlertAction(title: "Log Out", style: .Destructive) { (action: UIAlertAction!) -> Void in
      if let appDelegate = UIApplication.sharedApplication().delegate as? VYBAppDelegate {
        appDelegate.logOut()
      }
    }
    
    let goBackAction = UIAlertAction(title: "Go Back", style: .Cancel, handler: nil)
    
    alertController.addAction(unblockAction)
    alertController.addAction(logOutAction)
    alertController.addAction(goBackAction)
    
    if let viewController = delegate as? ProfileViewController {
      viewController.presentViewController(alertController, animated: true, completion: nil)
    }
  }
}
