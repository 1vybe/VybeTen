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
    
    if let profileViewController = self.sourceViewController as? ProfileViewController {
      if self.identifier == "ListViewSegue" {
        if !profileViewController.listViewButton.selected {
          if let listVC = self.destinationViewController as? ProfileListViewController {
            profileViewController.naviContainer?.setViewControllers([listVC], animated: true)
            
            profileViewController.listViewButton.selected = true
            profileViewController.collectionViewButton.selected = false
          }
        }
      } else if self.identifier == "CollectionViewSegue" {
        if !profileViewController.collectionViewButton.selected {
          if let collectionVC = self.destinationViewController as? ProfileCollectionViewController {
            profileViewController.naviContainer?.setViewControllers([collectionVC], animated: true)
  
            profileViewController.listViewButton.selected = false
            profileViewController.collectionViewButton.selected = true
          }
        }
      }
    }
  }
}
