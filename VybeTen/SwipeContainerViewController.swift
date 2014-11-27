//
//  SwipeContainerController.swift
//  VybeTen
//
//  Created by Jinsu Kim on 11/26/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit

@objc class SwipeContainerController: UIViewController {
  private var containerView = UIView()
  private var selectedViewController: UIViewController?
  
  var viewControllers: [UIViewController]!
  
  init(viewControllers arr: [UIViewController]!) {
    super.init()

    //TODO: copy this array
    viewControllers = arr
    
    containerView = UIView()
  }
  
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override func loadView() {
    var rootView = UIView()
    
    containerView = UIView()
    containerView.setTranslatesAutoresizingMaskIntoConstraints(false)
    rootView.addSubview(containerView)
    
    rootView.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: rootView, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0))
    rootView.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: rootView, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0))
    rootView.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: rootView, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0))
    rootView.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: rootView, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0))
    
    self.view = rootView
    
//    let gesture = UIScreenEdgePanGestureRecognizer(target: self, action:"panGestureRecognized:")
//    gesture.edges = UIRectEdge.Left | .Right
//    let gesture = UIPanGestureRecognizer(target: self, action:"panGestureRecognized:")
    let swipeToLeft = UISwipeGestureRecognizer(target: self, action: "panGestureRecognized:")
    swipeToLeft.direction = UISwipeGestureRecognizerDirection.Left
    let swipeToRight = UISwipeGestureRecognizer(target: self, action: "panGestureRecognized:")
    swipeToRight.direction = UISwipeGestureRecognizerDirection.Right
    containerView.addGestureRecognizer(swipeToLeft)
    containerView.addGestureRecognizer(swipeToRight)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let first = viewControllers.first {
      self.transitionToViewController(first)
    }
  }
  
  
  func panGestureRecognized(recognizer: UISwipeGestureRecognizer!) {
    if recognizer.direction == UISwipeGestureRecognizerDirection.Right {
      if let toViewController = self.previousViewController() {
        self.setSelectedViewController(toViewController)
      }
    } else {
      if let toViewController = self.nextViewController() {
        self.setSelectedViewController(toViewController)
      }
    }
  }
  
  private func previousViewController() -> UIViewController? {
    for i in 0...viewControllers.count {
      if viewControllers[i] == selectedViewController {
        if i > 0 {
          return viewControllers[i - 1]
        }
        break
      }
    }
    
    return nil
  }
  
  private func nextViewController() -> UIViewController? {
    for i in 0...viewControllers.count {
      if viewControllers[i] == selectedViewController {
        if i < viewControllers.count - 1  {
          return viewControllers[i + 1]
        }
        break
      }
    }
    
    return nil
  }
  
  func transitionToViewController(toViewController: UIViewController) {
    if !self.isViewLoaded() || toViewController == selectedViewController {
      return
    }
    
    let toView = toViewController.view
    toView.setTranslatesAutoresizingMaskIntoConstraints(true)
    toView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | .FlexibleHeight
    toView.frame = containerView.bounds
    self.addChildViewController(toViewController)
    
    if let fromViewController = selectedViewController {
      fromViewController.willMoveToParentViewController(nil)
      
      containerView.addSubview(toView)

      fromViewController.view.removeFromSuperview()
      fromViewController.removeFromParentViewController()
      
      toViewController.didMoveToParentViewController(self)
    } else {
      // First time transition should not be animated
      containerView.addSubview(toView)
      toViewController.didMoveToParentViewController(self)
      self.finishTransitionToViewController(toViewController)
    }
    
    self.finishTransitionToViewController(toViewController)
  }
  
  func setSelectedViewController(viewController: UIViewController) {
    self.transitionToViewController(viewController)
  }
  
  func finishTransitionToViewController(toViewController: UIViewController) {
    selectedViewController = toViewController
  }
  
}
