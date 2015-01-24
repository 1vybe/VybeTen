//
//  SimpleTabBarController.swift
//  VybeTen
//
//  Created by Jinsu Kim on 1/19/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class SimpleTabBarView: UIView {
  @IBOutlet weak var homeButton: UIButton!
  @IBOutlet weak var discoverButton: UIButton!
  @IBOutlet weak var activityButton: UIButton!
  @IBOutlet weak var profileButton: UIButton!
  weak var selectedButton: UIButton?

  func selectButton(button: UIButton) {
    if !button.selected {
      selectedButton?.selected = false
      button.selected = true
      selectedButton = button
    }
  }
  
  func selectHomeTab() {
    self.selectButton(homeButton)
  }

  func selectDiscoverTab() {
    self.selectButton(discoverButton)
  }
  
  func selectActivityTab() {
    self.selectButton(activityButton)
  }
  
  func selectProfileTab() {
    self.selectButton(profileButton)
  }
}

class SimpleTabBarController: UIViewController {
  @IBOutlet weak var tabBar: SimpleTabBarView!
  
  @IBOutlet weak var containerView: UIView!
  
  var mainNavigationController: VYBNavigationController?
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tabBar.selectHomeTab()
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if let identifier = segue.identifier {
      if identifier == "TabBarEmbedSegue" {
        if let destViewController = segue.destinationViewController as? VYBNavigationController {
          mainNavigationController = destViewController
        }
      } else {
        switch identifier {
        case "HomeTabSegue":
          tabBar.selectHomeTab()
        case "DiscoverTabSegue":
          tabBar.selectDiscoverTab()
        case "ActivityTabSegue":
          tabBar.selectActivityTab()
        case "ProfileTabSegue":
          tabBar.selectProfileTab()
        default:
          return
        }
      }
    }
  }
  
  func presentTabbedViewController(viewController: UIViewController) {
    mainNavigationController?.setViewControllers([viewController], animated:true)
  }

}
