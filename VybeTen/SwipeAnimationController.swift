//
//  SwipeAnimationController.swift
//  VybeTen
//
//  Created by Jinsu Kim on 11/25/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit

class SwipeAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
  enum Direction {
    case Left
    case Right
  }
  
  var direction: Direction
  var source: UIViewController!
  
  init(direction d: Direction) {
    direction = d
  }
  
  func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
    if direction == Direction.Right {
      if let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) {
        
        toViewController.view.frame = transitionContext.finalFrameForViewController(toViewController)
        toViewController.view.layoutIfNeeded()
        
        if let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) {
          let containerView = transitionContext.containerView()
          
          var frame = containerView.bounds
          frame.origin.x = frame.origin.x - containerView.bounds.size.width
          toViewController.view.frame = frame
          
          containerView.addSubview(toViewController.view)
          
          let duration = self.transitionDuration(transitionContext)
          UIView.animateWithDuration(duration, delay: 0.0, options:UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
            toViewController.view.frame = containerView.bounds
            }, completion: { (success: Bool) -> Void in
              let completed = !transitionContext.transitionWasCancelled()
              if completed {
                fromViewController.view.removeFromSuperview()
              }
              else {
                toViewController.view.removeFromSuperview()
              }
              transitionContext.completeTransition(completed)
          })
        }
      }
    } else {
      if let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) {
        if let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) {
          let containerView = transitionContext.containerView()
          
          var frame = containerView.bounds
          frame.origin.x += containerView.bounds.size.width
          toViewController.view.frame = frame
          
          containerView.addSubview(toViewController.view)
          
          let duration = self.transitionDuration(transitionContext)
          UIView.animateWithDuration(duration, delay: 0.0, options:UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
            toViewController.view.frame = containerView.bounds
//            fromViewController.view.frame.origin.x = fromViewController.view.frame.origin.x - fromViewController.view.bounds.size.width
            }, completion: { (success: Bool) -> Void in
              let completed = !transitionContext.transitionWasCancelled()
              if completed {
                fromViewController.view.removeFromSuperview()
              }
              else {
                toViewController.view.removeFromSuperview()
              }
              transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
          })
        }
      }

    }
    
  }
  
  
  func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
    return 3.0
  }
}
