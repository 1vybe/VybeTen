//
//  SimpleInteractionManager.swift
//  VybeTen
//
//  Created by Jinsu Kim on 11/25/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit

class SimpleInteractionManager: NSObject, UIViewControllerTransitioningDelegate {
  
  var sourceViewController: UIViewController
  var destinationViewController: UIViewController
  
  var edgeSwipeInteractorToLeft = UIPercentDrivenInteractiveTransition()
  var edgeSwipeInteractorToRight = UIPercentDrivenInteractiveTransition()
  
//  var animationController: SwipeAnimationController?
//  var edgeSwipeInteractor: EdgeSwipeInteractor?

  init(sourceController srcVC: UIViewController, destinationController destVC: UIViewController) {
    sourceViewController = srcVC
    destinationViewController = destVC
  }
  
  func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    return nil
  }
  
  func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    return nil
  }
  
  func interactionControllerForPresentation(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
    return edgeSwipeInteractorToRight
  }
  
  func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
    return edgeSwipeInteractorToLeft
  }
  
  func swipeToRightGestureDetected(recognizer: UIScreenEdgePanGestureRecognizer) {
    let state = recognizer.state
    let width = sourceViewController.view.bounds.width,
        percent = max(recognizer.translationInView(sourceViewController.view).x, 0) / width
    
    switch state {
    case UIGestureRecognizerState.Began:
      destinationViewController.modalPresentationStyle = UIModalPresentationStyle.Custom
      destinationViewController.transitioningDelegate = self
      self.sourceViewController.presentViewController(destinationViewController, animated: true, completion: nil)
    case UIGestureRecognizerState.Changed:
        edgeSwipeInteractorToRight.updateInteractiveTransition(percent);
        print("point: \(percent)")
    case UIGestureRecognizerState.Cancelled,
    .Ended:
      if (percent > 0.5 || recognizer.velocityInView(sourceViewController.view).x > 1000.0) {
        edgeSwipeInteractorToRight.finishInteractiveTransition()
      } else {
        edgeSwipeInteractorToRight.cancelInteractiveTransition()
      }
    default:
      return
    }
  }
  
  func swipeToLeftGestureDetected(recognizer: UIScreenEdgePanGestureRecognizer) {
    let state = recognizer.state
    let width = sourceViewController.view.bounds.width,
    percent = max(-recognizer.translationInView(sourceViewController.view).x, 0) / width
    
    switch state {
    case UIGestureRecognizerState.Began:
      self.sourceViewController.dismissViewControllerAnimated(true, completion: nil)
    case UIGestureRecognizerState.Changed:
        edgeSwipeInteractorToLeft.updateInteractiveTransition(percent);
    case UIGestureRecognizerState.Cancelled,
    .Ended:
      if (percent > 0.5 || recognizer.velocityInView(sourceViewController.view).x > 1000.0) {
        edgeSwipeInteractorToLeft.finishInteractiveTransition()
      } else {
        edgeSwipeInteractorToLeft.cancelInteractiveTransition()
      }
    default:
      return
    }
  }
  
}
