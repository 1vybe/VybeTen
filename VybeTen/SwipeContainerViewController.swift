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
  private var selectedViewController: UIViewController? {
    didSet {
      self.transitionToViewController(selectedViewController!)
    }
  }
  
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
    containerView.setTranslatesAutoresizingMaskIntoConstraints(true)
    rootView.addSubview(containerView)
    
    rootView.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: rootView, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0))
    rootView.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: rootView, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0))
    rootView.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: rootView, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0))
    rootView.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: rootView, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0))
    
    self.view = rootView
    
    let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: "panGestureRecognized:")
    gesture.edges = UIRectEdge.Left | .Right
    
    containerView.addGestureRecognizer(gesture)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let first = viewControllers.first {
      self.transitionToViewController(first)
    }
  }
  
  
  private func panGestureRecognized(recognizer: UIScreenEdgePanGestureRecognizer!) {
    let swipeToRight = recognizer.velocityInView(recognizer.view).x > 0
    
    if swipeToRight {
      if let toViewController = self.previousViewController() {
        self.selectedViewController = toViewController
      }
    } else {
      if let toViewController = self.nextViewController() {
        self.selectedViewController = toViewController
      }
    }
  }
  
  private func previousViewController() -> UIViewController? {
    for i in 0...viewControllers.count {
      if viewControllers[i] == selectedViewController {
        if let prevController = viewControllers[i - 1] as UIViewController? {
          return prevController
        }
        break
      }
    }
    
    return nil
  }
  
  private func nextViewController() -> UIViewController? {
    for i in 0...viewControllers.count {
      if viewControllers[i] == selectedViewController {
        if let nextController = viewControllers[i + 1] as UIViewController? {
          return nextController
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
//    toView.setTranslatesAutoresizingMaskIntoConstraints(true)
//    toView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | .FlexibleHeight
//    toView.frame = containerView.bounds
    self.addChildViewController(toViewController)
    
    if let fromViewController = selectedViewController? {
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
      return
    }
  }
  
  func finishTransitionToViewController(toViewController: UIViewController) {
    selectedViewController = toViewController
  }
  
}
