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
  }
}
