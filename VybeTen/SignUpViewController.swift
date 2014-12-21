//
//  SignUpViewController.swift
//  VybeTen
//
//  Created by Mohammed Tangestani on 2014-11-26.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import Foundation

class SignUpViewController: PFSignUpViewController {
  // MARK: View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let vybeLogoImage = UIImage(named: "VYBE_Txt")
    self.signUpView.logo = UIImageView(image: vybeLogoImage)
    
    let signUpBackgroundImage = UIImage(named: "SignUp-BtnB")
    self.signUpView.signUpButton.setBackgroundImage(signUpBackgroundImage, forState: .Normal)
  }
}
