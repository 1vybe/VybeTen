//
//  HomeViewController.swift
//  VybeTen
//
//  Created by Jinsu Kim on 1/23/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController, PlayerDelegate, iCarouselDataSource, iCarouselDelegate {
  enum SortBy: Int {
    case New = 0
    case Hot
  }
  var objects: [AnyObject]!
  
  @IBOutlet weak var carouselView: iCarousel!
//  @IBOutlet weak var leftBarItem: UIBarButtonItem!
  @IBOutlet weak var sortingModeControl: UISegmentedControl!

  @IBAction func sotringModeChanged(sender: AnyObject) {
    
  }
  
  @IBAction func moveToCapture() {
    if let navigation = self.navigationController as? VYBNavigationController {
      if let swipeContainer = navigation.parentViewController as? SwipeContainerController {
        swipeContainer.moveToCaptureScreen(animation: true)
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.objects = []
    
    self.carouselView.delegate = self
    self.carouselView.dataSource = self
    self.carouselView.type = iCarouselType.Linear

//    self.carouselView.
    
    let query = self.query(SortBy.New)
    query.findObjectsInBackgroundWithBlock { (result: [AnyObject]!, error: NSError!) -> Void in
      if error == nil {
        self.objects = result
        self.carouselView.reloadData()
      }
    }
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    self.updateCurrentUserPointScore()
  }
  
  private func updateCurrentUserPointScore() {
    if let score = PFUser.currentUser().objectForKey(kVYBUserPointScoreKey) as? Int {
      self.navigationItem.leftBarButtonItem?.title = "\(score)"
    } else {
      self.navigationItem.leftBarButtonItem?.title = "100"
    }
  }
  
  // MARK: - iCarouselDataSource
  
  func numberOfItemsInCarousel(carousel: iCarousel!) -> Int {
    return self.objects.count
  }
  
  func carousel(carousel: iCarousel!, viewForItemAtIndex index: Int, reusingView view: UIView!) -> UIView! {
    var theView: PFImageView! = view as PFImageView!
    if theView == nil {
      let fullSize = self.carouselView.bounds.size
      theView = PFImageView(frame: CGRectMake(0.0, 0.0, fullSize.width * 0.9, fullSize.height * 0.9))
    }
    let vy = self.objects[index] as PFObject
    if let thumbnailFile = vy[kVYBVybeThumbnailKey] as? PFFile {
      theView.file = thumbnailFile
      theView.loadInBackground({ (img: UIImage!, error: NSError!) -> Void in
        if error == nil {
          if img.size.height > img.size.width {     // Portrait Thumbnail
            theView.image = img
          } else {      // Landscapre Thumbnail
            theView.image = img.fixOrientation(3)
          }
        }
      })
    }
    
    return theView
  }
 
  func carousel(carousel: iCarousel!, didSelectItemAtIndex index: Int) {
    let currIdx = self.carouselView.currentItemIndex
    let vy = self.objects[currIdx] as PFObject
    
    let player = PlayerViewController(nibName: "PlayerViewController", bundle: nil)
    player.delegate = self
    
    MBProgressHUD.showHUDAddedTo(self.view, animated: true)
    player.prepare(vybe: vy)
  }
  
  func query(mode: SortBy) -> PFQuery! {
    let query = PFQuery(className: kVYBVybeClassKey)
    query.includeKey(kVYBVybeUserKey)
    
    switch mode {
    case .New:
      query.orderByDescending(kVYBVybeTimestampKey)
    case .Hot:
      // TODO: - How to efficiently order vybes by votes?
      query.orderByDescending(kVYBVybeTimestampKey)
    }
    
    return query
  }
  
  // MARK: - PlayerDelegate
  
  func didFinishSetup(success: Bool, vc: PlayerViewController) {
    MBProgressHUD.hideHUDForView(self.view, animated: true)
    if success {
      vc.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
      vc.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
      self.presentViewController(vc, animated: true, completion: { () -> Void in
        vc.play()
      })
    }
  }
  
  func didDismissPlayer(vc: PlayerViewController) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  override func shouldAutorotate() -> Bool {
    return false
  }
  
  override func supportedInterfaceOrientations() -> Int {
    return Int(UIInterfaceOrientationMask.Portrait.rawValue)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}
