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
    
    if selectedViewController == nil {
      // First time transition should not be animated
      containerView.addSubview(toView)
      toViewController.didMoveToParentViewController(self)
      self.finishTransitionToViewController(toViewController)
      return
    }
    
    let fromViewController = selectedViewController!
    fromViewController.willMoveToParentViewController(nil)
    
    var swipeAnimator = SwipeAnimator()
    var swipeTransition = SwipeTransitionContext(fromViewController: fromViewController, toController: toViewController, swipeToleft: (toViewController == viewControllers[1]))
    swipeTransition.animated = true
    swipeTransition.completionClosure = { (completed: Bool) -> Void in
      if completed {
        fromViewController.view.removeFromSuperview()
        fromViewController.removeFromParentViewController()
        
        toViewController.didMoveToParentViewController(self)
        self.finishTransitionToViewController(toViewController)
      } else {
        toViewController.view.removeFromSuperview()
      }
    }
    
    swipeAnimator.animateTransition(swipeTransition)
    self.finishTransitionToViewController(toViewController)
  }
  
  func setSelectedViewController(viewController: UIViewController) {
    self.transitionToViewController(viewController)
  }
  
  func finishTransitionToViewController(toViewController: UIViewController) {
    selectedViewController = toViewController
  }
  
}

class SwipeTransitionContext: NSObject, UIViewControllerContextTransitioning {
  var container: UIView
  var fromViewController: UIViewController
  var toViewController: UIViewController
  var animated: Bool
  var interactive: Bool
  var swipeToLeft: Bool
  
  var completionClosure: (Bool -> Void)?
  
  init(fromViewController from: UIViewController, toController to: UIViewController, swipeToleft left: Bool) {
    fromViewController = from
    toViewController = to
    
    container = fromViewController.view.superview!
    
    animated = true
    interactive = false
    
    swipeToLeft = left
    
    super.init()
  }
  
  func containerView() -> UIView {
    return container
  }
  
  func viewControllerForKey(key: String) -> UIViewController? {
    switch key {
    case UITransitionContextFromViewControllerKey:
      return fromViewController
    case UITransitionContextToViewControllerKey:
      return toViewController
    default:
      return nil
    }
  }
  
  func viewForKey(key: String) -> UIView? {
    switch key {
    case UITransitionContextFromViewControllerKey:
      return fromViewController.view
    case UITransitionContextToViewControllerKey:
      return toViewController.view
    default:
      return nil
    }
  }
  
  func initialFrameForViewController(vc: UIViewController) -> CGRect {
    switch vc {
    case fromViewController:
      return container.bounds
    case toViewController:
      var frame = container.bounds
      if swipeToLeft {
        // view to be presented is initially on the right
        frame.origin.x = frame.origin.x + frame.size.width
        return frame
      } else {
        // view to be presented is initially on the left
        frame.origin.x = frame.origin.x - frame.size.width
        return frame
      }
    default:
      return CGRectZero
    }
  }
  
  func finalFrameForViewController(vc: UIViewController) -> CGRect {
    switch vc {
    case fromViewController:
      var frame = container.bounds
      if swipeToLeft {
        // presenting view is on the left after transition
        frame.origin.x = frame.origin.x - frame.size.width
        return frame
      } else {
        // presenting view is on the right after transition
        frame.origin.x = frame.origin.x + frame.size.width
        return frame
      }
    case toViewController:
      return container.bounds
    default:
      return CGRectZero
    }
  }
  
  func isAnimated() -> Bool {
    return animated
  }
  
  func isInteractive() -> Bool {
    return interactive
  }
  
  func presentationStyle() -> UIModalPresentationStyle {
    return UIModalPresentationStyle.Custom
  }

  
  func cancelInteractiveTransition() {
    
  }
  
  func updateInteractiveTransition(percentComplete: CGFloat) {
    
  }
  
  func finishInteractiveTransition() {
    
  }
  
  func targetTransform() -> CGAffineTransform {
    return CGAffineTransformIdentity
  }
  
  func transitionWasCancelled() -> Bool {
    return true
  }
  
  func completeTransition(didComplete: Bool) {
    completionClosure?(didComplete)
  }

}

class SwipeAnimator: NSObject, UIViewControllerAnimatedTransitioning {
  
  func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
    var fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
    var toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
    
    let containerView = transitionContext.containerView()
    
    toViewController.view.frame = transitionContext.initialFrameForViewController(toViewController)
    containerView.addSubview(toViewController.view)
    
    UIView.animateWithDuration(self.transitionDuration(transitionContext), delay: 0.0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
      toViewController.view.frame = transitionContext.finalFrameForViewController(toViewController)
      fromViewController.view.frame = transitionContext.finalFrameForViewController(fromViewController)
    }) { (Bool) -> Void in
      
    }

  }
  
  
  func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
    return 2.0
  }
}

