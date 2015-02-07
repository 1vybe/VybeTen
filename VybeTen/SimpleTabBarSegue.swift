//
//  SimpleTabBarSegue.swift
//  VybeTen
//
//  Created by Jinsu Kim on 1/19/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class SimpleTabBarSegue: UIStoryboardSegue {
  override func perform() {
    if let sourceViewController = self.sourceViewController as? SimpleTabBarController {
      if let destViewController = self.destinationViewController as? UIViewController {
        sourceViewController.presentTabbedViewController(destViewController)
      }
    }
    
    if let profileVC = self.sourceViewController as? ProfileViewController {
      if self.identifier == "ListViewSegue" {
        if let listVC = self.destinationViewController as? ProfileListViewController {
          listVC.mainProfileViewController = profileVC
          profileVC.naviContainer?.setViewControllers([listVC], animated: true)
        }
      } else if self.identifier == "CollectionViewSegue" {
        if let collectionVC = self.destinationViewController as? ProfileCollectionViewController {
          collectionVC.mainProfileViewController = profileVC
          profileVC.naviContainer?.setViewControllers([collectionVC], animated: true)
        }
      }
    }
  }
}
