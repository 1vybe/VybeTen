//
//  VYBFirstPageViewController.swift
//  VybeTen
//
//  Created by jinsuk on 10/20/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit

class VYBFirstPageViewController: UIViewController, VYBLogInViewControllerDelegate, VYBSignUpViewControllerDelegate {
    weak var delegate: VYBFirstPageViewControllerDelegate?
    
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    @IBAction func logInButtonPressed(sender: UIButton) {
        let logInVC = VYBLogInViewController()
        logInVC.delegate = self
        self.navigationController?.pushViewController(logInVC, animated: false)
    }
    
    @IBAction func signUpButtonPressed(sender: UIButton) {
        let signUpVC = VYBSignUpViewController()
        signUpVC.delegate = self
        self.navigationController?.pushViewController(signUpVC, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.tintColor = UIColor(red: 72.0/255.0, green: 72.0/255.0, blue: 72.0/255.0, alpha: 1.0)
        self.navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.translucent = true
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func logInViewController(logInController: VYBLogInViewController!, didLogInUser user: PFUser!) {
        self.delegate?.didLogInuser(user)
    }
    
    func didCompleteSignUp() {
        self.delegate?.didLogInuser(PFUser.currentUser())
    }
    
    override func shouldAutorotate() -> Bool {
        return false;
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return UIInterfaceOrientation.Portrait.rawValue
    }
    
}

@objc protocol VYBFirstPageViewControllerDelegate {
    func didLogInuser (user: PFUser!)
}
    
