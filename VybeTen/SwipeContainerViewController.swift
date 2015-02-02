//
//  SwipeContainerController.swift
//  VybeTen
//
//  Created by Jinsu Kim on 11/26/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit

@objc class SwipeContainerController: UIViewController, UIGestureRecognizerDelegate {
  private var containerView = UIView()
  private var selectedViewController: UIViewController?
  private var destViewController: UIViewController?
  
  var viewControllers: [UIViewController]!
  
  var swipeInteractor = SwipeInteractionManager()
  
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
    containerView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | .FlexibleWidth
    containerView.setTranslatesAutoresizingMaskIntoConstraints(false)
    rootView.addSubview(containerView)
    
    rootView.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: rootView, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0))
    rootView.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: rootView, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0))
    rootView.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: rootView, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0))
    rootView.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: rootView, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0))
    
    self.view = rootView
    
    let screenEdgePanGesture_Right = UIScreenEdgePanGestureRecognizer(target: self, action: "handleScreenEdgePanGesture:")
    screenEdgePanGesture_Right.edges = UIRectEdge.Right
    screenEdgePanGesture_Right.delegate = self
    let screenEdgePanGesture_Left = UIScreenEdgePanGestureRecognizer(target: self, action: "handleScreenEdgePanGesture:")
    screenEdgePanGesture_Left.edges = UIRectEdge.Left
    screenEdgePanGesture_Left.delegate = self
    
    containerView.addGestureRecognizer(screenEdgePanGesture_Left)
    containerView.addGestureRecognizer(screenEdgePanGesture_Right)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // NOTE: - Start with Capture screen
    selectedViewController = viewControllers[1]
    self.transitionToViewController(selectedViewController!, interactive: false, animation: false)
  }
  
  func moveToProfileScreen(animation animate: Bool) {
    self.transitionToViewController(viewControllers[0], interactive: false, animation:animate)
  }

  
  func moveToCaptureScreen(animation animate: Bool) {
    self.transitionToViewController(viewControllers[1], interactive: false, animation:animate)
  }
  
  
  func goToNotificationScreen(completionBlock: (Void -> Void)!) {
    if let nav = viewControllers[1] as? VYBNavigationController {
      nav.popToRootViewControllerAnimated(false)
      if let activity = nav.topViewController as? VYBActivityTableViewController {
        activity.goToNotificationScreenWithCompletion(completionBlock)
      }
    }
  }
  
  private func previousViewController() -> UIViewController? {
    for i in 0...viewControllers.count - 1 {
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
    for i in 0...viewControllers.count - 1 {
      if viewControllers[i] == selectedViewController {
        if i < viewControllers.count - 1  {
          return viewControllers[i + 1]
        }
        break
      }
    }
    
    return nil
  }
  
  func transitionToViewController(toViewController: UIViewController, interactive: Bool, animation: Bool) {
    if !self.isViewLoaded() {
      return
    }
    
    let toView = toViewController.view
    toView.setTranslatesAutoresizingMaskIntoConstraints(true)
    toView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | .FlexibleHeight
    toView.frame = containerView.bounds
    self.addChildViewController(toViewController)
    
    if selectedViewController == toViewController {
      // First time transition should not be animated
      containerView.addSubview(toView)
      toViewController.didMoveToParentViewController(self)
      return
    }
    
    assert(selectedViewController != nil, "SwipeContainerViewController crashing. condition failed.")
    let fromViewController = selectedViewController!
    fromViewController.willMoveToParentViewController(nil)

    // We want to scroll to top everytime we swipe back to activity
    if let captureVC = fromViewController as? VYBCaptureViewController {
      NSNotificationCenter.defaultCenter().postNotificationName(VYBSwipeContainerControllerWillMoveToActivityScreenNotification, object: nil)
    }

    var animator = SwipeAnimator()
    var transitionContext = SwipeTransitionContext(fromViewController: fromViewController, toController: toViewController, swipeToleft: (self.indexOfViewController(toViewController) > self.indexOfViewController(fromViewController) ))
    transitionContext.animated = animation
    swipeInteractor.animator = animator

    transitionContext.completionClosure = { (completed: Bool) -> Void in
      if completed {
        fromViewController.view.removeFromSuperview()
        fromViewController.removeFromParentViewController()
        toViewController.didMoveToParentViewController(self)
      } else {
        toViewController.view.removeFromSuperview()
        self.selectedViewController = fromViewController
      }
    }
    
    selectedViewController = toViewController

    if interactive {
      transitionContext.interactive = interactive
      swipeInteractor.startInteractiveTransition(transitionContext)
    } else {
      animator.animateTransition(transitionContext)
    }
    
  }
  
  func handleScreenEdgePanGesture(recognizer: UIScreenEdgePanGestureRecognizer) {
    let state = recognizer.state
    switch state {
    case UIGestureRecognizerState.Began:
      let velocity = recognizer.velocityInView(recognizer.view).x
      let leftToRight = velocity > 0
      if leftToRight {
        if let toViewController = self.previousViewController() {
          self.transitionToViewController(toViewController, interactive: true, animation: true)
        }
      } else {
        if let toViewController = self.nextViewController() {
          self.transitionToViewController(toViewController, interactive: true, animation: true)
        }
      }
    case .Changed:
      if let leftToRight = swipeInteractor.leftToRight {
        var translation = recognizer.translationInView(containerView).x
        // To prevent user scrolling in the opposite direction of the initial direction beyond the original x position. 
        if !leftToRight {
          translation = min(translation, 0)
          translation = translation * -1
        } else {
          translation = max(translation, 0)
        }
        var percent = translation / CGRectGetWidth(containerView.bounds)
        swipeInteractor.updateInteractiveTransition(percent)
      }
    case .Ended:
      if let leftToRight = swipeInteractor.leftToRight {
        var velocity = recognizer.velocityInView(containerView).x
        if !leftToRight { velocity = -1 * velocity }
        
        if velocity > 0 {
          swipeInteractor.finishInteractiveTransition()
        } else {
          swipeInteractor.cancelInteractiveTransition()
        }
      }
    case .Cancelled:
      swipeInteractor.cancelInteractiveTransition()
    default:
      return
    }
  }
  
  private func indexOfViewController(vc: UIViewController) -> Int {
    var idx: Int = 0

    for i in 0...viewControllers.count - 1 {
      if viewControllers[i] == vc {
        idx = i
        break
      }
    }
    
    return idx
  }
  
  override func shouldAutorotate() -> Bool {
    if selectedViewController != nil {
      return selectedViewController!.shouldAutorotate()
    }
    return true
  }
  
  override func supportedInterfaceOrientations() -> Int {
    if selectedViewController != nil {
      return selectedViewController!.supportedInterfaceOrientations()
    }
    return Int(UIInterfaceOrientationMask.Portrait.rawValue)
  }
  
  override func prefersStatusBarHidden() -> Bool {
    if selectedViewController != nil {
      return selectedViewController!.prefersStatusBarHidden()
    }
    return true
  }
  
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}

class SwipeInteractionManager: NSObject, UIViewControllerInteractiveTransitioning {
  var animator: UIViewControllerAnimatedTransitioning!
  var transitionContext: SwipeTransitionContext!
  
  var completionSpeed: CGFloat = 1
  var percentCompleted: CGFloat!
  var duration: CGFloat {
    get {
      return CGFloat(animator.transitionDuration(transitionContext))
    }
  }

  var cancelTick: CADisplayLink!

  var leftToRight: Bool?
  
  func startInteractiveTransition(transitionContext: UIViewControllerContextTransitioning) {
    self.transitionContext = transitionContext as SwipeTransitionContext
    leftToRight = !self.transitionContext.swipeToLeft
    
    transitionContext.containerView().layer.speed = 0
    
    animator.animateTransition(transitionContext)
  }
  
  func updateInteractiveTransition(percent: CGFloat) {
    percentCompleted = percent
  
    transitionContext.containerView().layer.timeOffset = CFTimeInterval(self.duration * percentCompleted)
    transitionContext.updateInteractiveTransition(percentCompleted)
  }
  
  func finishInteractiveTransition() {
    var layer = transitionContext.containerView().layer
    
    layer.speed = Float(self.completionSpeed)
    
    let pausedTime = layer.timeOffset
    layer.timeOffset = 0
    layer.beginTime = 0
    let timePassed = layer.convertTime(CACurrentMediaTime(), fromLayer: nil) - pausedTime
    layer.beginTime = timePassed
    
    transitionContext.finishInteractiveTransition()
  }
  
  func cancelInteractiveTransition() {
    cancelTick = CADisplayLink(target: self, selector: "tickedToCancel:")
    cancelTick.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
    
    transitionContext.cancelInteractiveTransition()
  }
  
  func tickedToCancel(tick: CADisplayLink) {
    let layer = transitionContext.containerView().layer
    let timeOffset = layer.timeOffset - tick.duration
    if timeOffset < 0 {
      cancelTick.invalidate()
      layer.speed = 1
    } else {
      layer.timeOffset = timeOffset
    }
  }
}

class SwipeTransitionContext: NSObject, UIViewControllerContextTransitioning {
  var container: UIView
  var fromViewController: UIViewController
  var toViewController: UIViewController
  var animated: Bool
  var interactive: Bool
  var swipeToLeft: Bool
  
  var _transitionWasCancelled: Bool
  
  var completionClosure: (Bool -> Void)?
  
  init(fromViewController from: UIViewController, toController to: UIViewController, swipeToleft left: Bool) {
    fromViewController = from
    toViewController = to
    
    container = fromViewController.view.superview!
    
    animated = true
    interactive = false
    
    swipeToLeft = left
    
    _transitionWasCancelled = false
    
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
    _transitionWasCancelled = true
  }
  
  func updateInteractiveTransition(percentComplete: CGFloat) { }
  
  func finishInteractiveTransition() {
    _transitionWasCancelled = false
  }
  
  func targetTransform() -> CGAffineTransform {
    return CGAffineTransformIdentity
  }
  
  func transitionWasCancelled() -> Bool {
    return _transitionWasCancelled
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
      // status bar animation
      toViewController.setNeedsStatusBarAppearanceUpdate()
      }) { (completed: Bool) -> Void in
        if transitionContext.transitionWasCancelled() {
          fromViewController.view.frame = transitionContext.initialFrameForViewController(fromViewController)
//          fromViewController.setNeedsStatusBarAppearanceUpdate()
        }
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
    }
  }
  
  func animationEnded(transitionCompleted: Bool) {
    if !transitionCompleted {
      println("transition cancelled!")
    }
  }
  
  func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
    return 0.3
  }
}

