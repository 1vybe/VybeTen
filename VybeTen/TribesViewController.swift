//
//  TribesViewController.swift
//  Vybe
//
//  Created by Jinsu Kim on 2/17/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

let reuseIdentifier = "TribeCollectionCell"

class TribesViewController: UICollectionViewController, CreateTribeDelegate, VYBPlayerViewControllerDelegate {
  var tribeObjects: [AnyObject]
  
  var refreshControl: UIRefreshControl?
  
  required init(coder aDecoder: NSCoder) {
    tribeObjects = []

    super.init(coder: aDecoder)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let control = UIRefreshControl()
    control.addTarget(self, action: "refreshControlPulled", forControlEvents: UIControlEvents.ValueChanged)
    collectionView?.addSubview(control)
    collectionView?.alwaysBounceVertical = true
    
    refreshControl = control
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    // Update all tribe list
    let tribeQuery = PFQuery(className: kVYBTribeClassKey)
    tribeQuery.findObjectsInBackgroundWithBlock({ (objects: [AnyObject]!, error: NSError!) -> Void in
      if objects != nil {
        self.tribeObjects = objects
        self.collectionView?.reloadData()
      }
    })
  }
  
  func refreshControlPulled() {
    self.reloadMyFeed()
  }
  
  private func reloadMyFeed() {
    let feed = PFUser.currentUser().relationForKey(kVYBUserFreshFeedKey)
    let query = feed.query()
    query.includeKey(kVYBVybeTribeKey)
    query.includeKey(kVYBVybeUserKey)
    
    query.findObjectsInBackgroundWithBlock { (result: [AnyObject]!, error: NSError!) -> Void in
      if result != nil {
        PFObject.unpinAllObjectsInBackgroundWithName("MyFreshFeed", block: { (success: Bool, error: NSError!) -> Void in
          PFObject.pinAllInBackground(result, withName: "MyFreshFeed", block: { (success: Bool, error: NSError!) -> Void in
            if success {
              self.collectionView?.reloadData()
            }
            self.refreshControl?.endRefreshing()
          })
        })
      }
    }
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "ShowCreateTribeSegue" {
      if let createTribeVC = segue.destinationViewController as? CreateTribeViewController {
        createTribeVC.delegate = self
      }
    }
  }
  
  // MARK: - CreateTribeDelegate
  
  func didCreateTribe(tribe: AnyObject) {
    MyVybeStore.sharedInstance.currTribe = tribe as? PFObject
    
    if let navigation = self.navigationController as? VYBNavigationController {
      navigation.popViewControllerAnimated(true, completion: { () -> Void in
        if let swipeContainer = navigation.parentViewController as? SwipeContainerController {
          swipeContainer.moveToCaptureScreen(animation: true)
        }
      })
    }
  }
  
  func didCancelTribe() {
    if let navigation = self.navigationController as? VYBNavigationController {
      navigation.popViewControllerAnimated(true)
    }
  }
  
  // MARK: UICollectionViewDataSource
  
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return tribeObjects.count
  }
  
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
    if collectionView.bounds.size.width > 320 {
      // iPhone6
      return CGSizeMake(100.0, 120.0)
    } else {
      return CGSizeMake(84.0, 104.0)
    }
  }
  
  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PFCollectionViewCell
    
    let tribeObj = tribeObjects[indexPath.row] as! PFObject
    
    if let nameLabel = cell.viewWithTag(235) as? UILabel {
      nameLabel.text = tribeObj.objectForKey(kVYBTribeNameKey) as? String
    }
    
    if let tribeImageView = cell.viewWithTag(123) as? PFImageView {
      if let file = tribeObj[kVYBTribePhotoKey] as? PFFile {
        tribeImageView.file = file
        tribeImageView.loadInBackground({ (image: UIImage!, error: NSError!) -> Void in
          if image != nil {
            let maskImage = UIImage(named: "SquareMask")
            tribeImageView.image = VYBUtility.maskImage(image, withMask: maskImage)
          }
        })
      }
    }
    
    return cell
  }
  
  override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    let tribeObj = tribeObjects[indexPath.row] as? PFObject
    let query = PFQuery(className: kVYBVybeClassKey)
    query.fromPinWithName("MyFreshFeed")
    query.whereKey(kVYBVybeTribeKey, equalTo: tribeObj)
    query.includeKey(kVYBVybeUserKey)
    query.orderByAscending(kVYBVybeTimestampKey)

    query.findObjectsInBackgroundWithBlock { (result: [AnyObject]!, error: NSError!) -> Void in
      if error == nil {
        if let vybeObjs = result as? [PFObject] where vybeObjs.count > 0 {
          let playerVC = VYBPlayerViewController(nibName: "VYBPlayerViewController", bundle: nil)
          playerVC.delegate = self
          playerVC.playStream(vybeObjs)
          
          MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        }
      }
    }
  }
  
  // MARK: - VYBPlayerViewControllerDelegate
  
  func playerViewController(playerVC: VYBPlayerViewController!, didFinishSetup ready: Bool) {
    MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
    
    if ready {
      self.presentViewController(playerVC, animated: true, completion: { () -> Void in
        playerVC.playCurrentItem()
      })
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

}
