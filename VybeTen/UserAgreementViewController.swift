//
//  UserAgreementViewController.swift
//  VybeTen
//
//  Created by Jinsu Kim on 12/5/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit

class UserAgreementViewController: UIViewController {
  @IBOutlet weak var checkBoxButton: UIButton!
  @IBOutlet weak var acceptButton: UIButton!
  
  @IBAction func checkBoxButtonPressed() {
    checkBoxButton.selected = !checkBoxButton.selected
    acceptButton.enabled = checkBoxButton.selected
    if acceptButton.enabled {
      acceptButton.alpha = 1.0;
    }
    else {
      acceptButton.alpha = 0.3;
    }
  }
  
  @IBAction func acceptButtonPressed() {
    let agreed = NSNumber(bool: true)
    PFUser.currentUser().setObject(agreed, forKey: kVYBUserTermsAgreedKey)
    PFUser.currentUser().saveEventually()
    self.navigationController?.popViewControllerAnimated(false)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    acceptButton.enabled = false
    acceptButton.alpha = 0.3;
    
    // Do any additional setup after loading the view.
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
}
