//
//  TribesViewController.swift
//  Vybe
//
//  Created by Jinsu Kim on 2/17/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class Tribe {
  var tribeObject: AnyObject
  var freshCount: Int
  
  init(parseObj: AnyObject) {
    tribeObject = parseObj
    freshCount = 0
  }
}

let reuseIdentifier = "TribeCollectionCell"

class TribesViewController: UICollectionViewController, CreateTribeDelegate, VYBPlayerViewControllerDelegate {
  var tribeObjects: [AnyObject]
  
  var refreshControl: UIRefreshControl?
  
  required init(coder aDecoder: NSCoder) {
    tribeObjects = []

    super.init(coder: aDecoder)
  }
  
  @IBAction func moveToCapture() {
    if let navigation = self.navigationController as? VYBNavigationController {
      navigation.popViewControllerAnimated(true, completion: { () -> Void in
        if let swipeContainer = navigation.parentViewController as? SwipeContainerController {
          swipeContainer.moveToCaptureScreen(animation: true)
        }
      })
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let control = UIRefreshControl()
    control.addTarget(self, action: "refreshControlPulled", forControlEvents: UIControlEvents.ValueChanged)
    collectionView?.addSubview(control)
    collectionView?.alwaysBounceVertical = true
    
    refreshControl = control
    
    self.reloadTribes{  }
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
  
    self.reloadMyFeed()
  }
  
  func refreshControlPulled() {
    self.reloadTribes { () -> Void in
      self.reloadMyFeed()
    }
  }
  
  private func reloadTribes(completionBlock: (() -> ())) {
    // Update all tribe list
    let tribeQuery = PFQuery(className: kVYBTribeClassKey)
    tribeQuery.findObjectsInBackgroundWithBlock({ (result: [AnyObject]!, error: NSError!) -> Void in
      if let objects = result as? [PFObject] {
        self.tribeObjects = []
        
        for obj in objects {
          let newTribe = Tribe(parseObj: obj)
          self.tribeObjects += [newTribe]
        }
        completionBlock()
      }
    })
  }
  
  private func reloadMyFeed() {
    // First reset freshCount for each tribe
    if let tribes = tribeObjects as? [Tribe] {
      for tribe in tribes {
        tribe.freshCount = 0
      }
    }

    
    let feed = PFUser.currentUser().relationForKey(kVYBUserFreshFeedKey)
    let query = feed.query()
    query.includeKey(kVYBVybeTribeKey)
    query.includeKey(kVYBVybeUserKey)
    
    query.findObjectsInBackgroundWithBlock { (result: [AnyObject]!, error: NSError!) -> Void in
      if result != nil {
        PFObject.unpinAllObjectsInBackgroundWithName("MyFreshFeed", block: { (success: Bool, error: NSError!) -> Void in
          PFObject.pinAllInBackground(result, withName: "MyFreshFeed", block: { (success: Bool, error: NSError!) -> Void in
            if success {
              for vybeObj in result {
                if let trObj = vybeObj.objectForKey(kVYBVybeTribeKey) as? PFObject {
                  if let tribes = self.tribeObjects as? [Tribe] {
                    innerLoop: for tribe in tribes {
                      if trObj.objectId == tribe.tribeObject.objectId {
                        tribe.freshCount++
                        break innerLoop
                      }
                    }
                  }
                }
              }

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
    
    let tribe = tribeObjects[indexPath.row] as! Tribe
    
    if let nameLabel = cell.viewWithTag(235) as? UILabel {
      nameLabel.text = tribe.tribeObject.objectForKey(kVYBTribeNameKey) as? String
      
      println("\(nameLabel.text) has \(tribe.freshCount) fresh vybes")
    }
    
    if let tribeImageView = cell.viewWithTag(123) as? PFImageView {
      if let file = tribe.tribeObject[kVYBTribePhotoKey] as? PFFile {
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
    let tribe = tribeObjects[indexPath.row] as? Tribe
    let tribeObj = tribe?.tribeObject as? PFObject
    
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
  
  func dismissPlayerViewController(playerVC: VYBPlayerViewController!, completion completionHandler: (() -> Void)!) {
    self.dismissViewControllerAnimated(true, completion: completionHandler)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

}
