//
//  SimpleTabBarController.swift
//  VybeTen
//
//  Created by Jinsu Kim on 1/19/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class SimpleTabBarController: UIViewController {
  var mainNavigationController: VYBNavigationController?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "TabBarEmbedSegue" {
      if let destViewController = segue.destinationViewController as? VYBNavigationController {
        mainNavigationController = destViewController
      }
    }
  }
  
  func presentTabbedViewController(viewController: UIViewController) {
    mainNavigationController?.setViewControllers([viewController], animated:true)
  }
  
  /*
  // MARK: - Navigation
  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
  // Get the new view controller using segue.destinationViewController.
  // Pass the selected object to the new view controller.
  }
  */
  
}
