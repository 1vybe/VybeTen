//
//  SimpleTabBarSegue.swift
//  VybeTen
//
//  Created by Jinsu Kim on 1/19/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

extension UIView {
  func moveToTopOn(baseView: UIView) {
    if let superView = self.superview {
      println("[moveToTop_BEFORE] superview has \(superView.constraints().count) constraints")
      self.removeFromSuperview()
      println("[moveToTop_AFTER] superview has \(superView.constraints().count) constraints")
    }
    println("[moveToTop] current constraints(\(self.constraints().count)) ----------")
    println(self.constraints())
    
    //    view.insertSubview(self,atIndex: 0)
    baseView.addSubview(self)
    baseView.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: baseView, attribute: NSLayoutAttribute.Left, multiplier: 1.0, constant: 0))
    baseView.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: baseView, attribute: NSLayoutAttribute.Right, multiplier: 1.0, constant: 0))
    baseView.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: baseView, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: 0))
  }
  
  func expandOn(baseVC: UIViewController) {
    if let superView = self.superview {
      println("[expand_BEFORE] superview has \(superView.constraints().count) constraints")
      self.removeFromSuperview()
      println("[expand_AFTER] superview has \(superView.constraints().count) constraints")
    }
    println("[expand] current constraints(\(self.constraints().count)) ----------")
    println(self.constraints())
    
    //    view.insertSubview(self,atIndex: 0)
    let baseView = baseVC.view
    baseView.addSubview(self)
    baseView.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: baseView, attribute: NSLayoutAttribute.Left, multiplier: 1.0, constant: 0))
    baseView.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: baseView, attribute: NSLayoutAttribute.Right, multiplier: 1.0, constant: 0))
    baseView.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: baseVC.topLayoutGuide, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: 0))
    baseView.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: baseVC.bottomLayoutGuide, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 0))
  }
}

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
          println("moving to profile view")
          profileVC.summaryView.moveToTopOn(profileVC.view)
          
          profileVC.containerViewController?.view.removeFromSuperview()
          listVC.view.expandOn(profileVC)
          
          profileVC.summaryView.moveToTopOn(listVC.view)
          
          profileVC.containerViewController = listVC
        }
      } else if self.identifier == "CollectionViewSegue" {
        if let collectionVC = self.destinationViewController as? ProfileCollectionViewController {
          println("moving to profile view")
          profileVC.summaryView.moveToTopOn(profileVC.view)
          
          profileVC.containerViewController?.view.removeFromSuperview()
          collectionVC.view.expandOn(profileVC)
          
          profileVC.summaryView.moveToTopOn(collectionVC.view)

          profileVC.containerViewController = collectionVC
        }
      }
    }
  }
}
