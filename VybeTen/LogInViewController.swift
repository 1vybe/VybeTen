//
//  LogInViewController.swift
//  VybeTen
//
//  Created by Mohammed Tangestani on 2014-11-26.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import Foundation

class LogInViewController: PFLogInViewController, PFSignUpViewControllerDelegate {
  // MARK: View Life Cycle
  override func viewDidLoad() {
      super.viewDidLoad()
      
      let vybeLogoImage = UIImage(named: "VYBE_Txt")
      self.logInView.logo = UIImageView(image: vybeLogoImage)
      
      let logInBackgroundImage = UIImage(named: "LogIn-Btn")
      self.logInView.logInButton.setBackgroundImage(logInBackgroundImage, forState: .Normal)
      
      let signUpBackgroundImage = UIImage(named: "SignUp-BtnA")
      self.logInView.signUpButton.setBackgroundImage(signUpBackgroundImage, forState: .Normal)
  }
  
  func signUpViewController(signUpController: PFSignUpViewController!, didSignUpUser user: PFUser!) {
    signUpController.dismissViewControllerAnimated(false, completion: nil)
    self.delegate?.logInViewController?(self, didLogInUser: user)
  }
}
