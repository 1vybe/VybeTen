
//  TribesViewController.swift
//  Vybe
//
//  Created by Jinsu Kim on 2/17/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

@objc class Tribe {
  var tribeObject: AnyObject
  var coverVybe: AnyObject?
  var freshCount: Int
  var memberCount: Int
  
  init(parseObj: AnyObject) {
    tribeObject = parseObj
    freshCount = 0
    memberCount = 0
  }
}

let reuseIdentifier = "TribeCollectionCell"

class TribesViewController: UICollectionViewController, CreateTribeDelegate, VYBPlayerViewControllerDelegate {
  var tribes: [AnyObject]
  var selectedTribe: AnyObject?
  var captureButton: UIButton?
  
  var refreshControl: UIRefreshControl?
  
  required init(coder aDecoder: NSCoder) {
    tribes = []

    super.init(coder: aDecoder)
  }
  
  func moveToCapture() {
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
    
    let button = UIButton(frame: CGRectMake(25, self.view.bounds.size.height - 86, 61, 61))
    button.setImage(UIImage(named: "Camera-Btn"), forState: UIControlState.Normal)
    button.addTarget(self, action: "moveToCapture", forControlEvents: UIControlEvents.TouchUpInside)
    captureButton = button
    
    self.collectionView?.addSubview(button)
    
    // Subscribe to a notification to receive vybe updates in real time
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "appDelegateDidReceiveRemoteNotification:", name: VYBAppDelegateApplicationDidReceiveRemoteNotification, object: nil)
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    var textAttributes = [NSObject : AnyObject]()
    if let font = UIFont(name: "Helvetica Neue", size: 18.0) {
      let textColor = UIColor(red: 254.0/255.0, green: 68.0/255.0, blue: 0.0/255.0, alpha: 1.0)
      textAttributes[NSFontAttributeName] = font
      textAttributes[NSForegroundColorAttributeName] = textColor
      self.navigationController?.navigationBar.titleTextAttributes = textAttributes
    }
  
    self.loadTribesFromCloud()
  }
  
  func loadTribesFromCloud() {
    // First reset freshCount and coverVybe for each tribe
    tribes = []
    
    let query = PFQuery(className: kVYBTribeClassKey)
    query.whereKey(kVYBTribeMembersKey, equalTo: PFUser.currentUser())
    query.includeKey(kVYBTribeCoordinatorKey)
    
    query.findObjectsInBackgroundWithBlock({ (result: [AnyObject]!, error: NSError!) -> Void in
      if result != nil {
        for obj in result {
          let newTribe = Tribe(parseObj: obj)
          self.tribes += [newTribe]
        }
        
        self.refreshMyFeed()
      }
    })
  }
  
  func refreshMyFeed() {
    let feed = PFUser.currentUser().relationForKey(kVYBUserFreshFeedKey)
    
    let query = feed.query()
    query.includeKey(kVYBVybeUserKey)
    // We only show vybes within the last 48 hrs
    let twoDaysAgo = NSDate(timeIntervalSinceNow: -1 * 60 * 60 * 24 * 2)
    query.whereKey(kVYBVybeTimestampKey, greaterThanOrEqualTo: twoDaysAgo)
    
    query.findObjectsInBackgroundWithBlock { (result: [AnyObject]!, error: NSError!) -> Void in
      PFObject.pinAllInBackground(result, withName: "MyFreshFeed", block: { (success: Bool, error: NSError!) -> Void in
        if success {
          for vybeObj in result {
            if let trObj = vybeObj[kVYBVybeTribeKey] as? PFObject {
              if let tribes = self.tribes as? [Tribe] {
                innerLoop: for tribe in tribes {
                  let trb = tribe.tribeObject as PFObject
                  if trObj.objectId == trb.objectId {
                    // Ignore your own vybes when incrementing the count and updating the cover vybe
                    let user = vybeObj[kVYBVybeUserKey] as PFObject
                    if user.objectId != PFUser.currentUser().objectId {
                      tribe.freshCount++
                      if let coverObjDate = tribe.coverVybe?.objectForKey(kVYBVybeTimestampKey) as? NSDate {
                        if let newDate = vybeObj[kVYBVybeTimestampKey] as? NSDate {
                          let comparison = newDate.compare(coverObjDate)
                          if comparison == NSComparisonResult.OrderedAscending {
                            tribe.coverVybe = vybeObj
                          }
                        }
                      } else {
                        tribe.coverVybe = vybeObj
                      }
                    }
                    
                    break innerLoop
                  }
                }
              }
            }
          }
          // Update cover thumbnails
          let lastQ = PFQuery(className:kVYBVybeClassKey)
          lastQ.fromPinWithName("LastVybes")
          // NOTE: - This should be unnecessary because only one vybe should have been pinned for each tribe
          lastQ.orderByAscending(kVYBVybeTimestampKey)
          lastQ.findObjectsInBackgroundWithBlock({ (result: [AnyObject]!, error: NSError!) -> Void in
            if result != nil {
              for obj in result {
                if let tribe = obj[kVYBVybeTribeKey] as? PFObject {
                  innerLoop: for trb in self.tribes {
                    let trbObj = trb.tribeObject as PFObject
                    if trbObj.objectId == tribe.objectId {
                        // NOTE: - Update Tribe that has no fresh contents. However it must be that checking this condition is not required.
                      let t = trb as Tribe
                      if t.freshCount == 0 {
                        t.coverVybe = obj
                      }
                      
                      break innerLoop
                    }
                  }
                }
              }
            }
            // Refresh the collection view after updating cover vybes
            self.collectionView?.reloadData()
            
            // Download the most recent vybe for tribes that have ZERO fresh content - however cover vybe might exist
            for (idx, tribe) in enumerate(self.tribes) {
              let trb = tribe as Tribe
              
              if trb.freshCount == 0 {
                let trbObj = trb.tribeObject as PFObject
                
                let query = PFQuery(className: kVYBVybeClassKey)
                query.whereKey(kVYBVybeTribeKey, equalTo: trbObj)
                query.orderByDescending(kVYBVybeTimestampKey)
                query.getFirstObjectInBackgroundWithBlock({ (obj: PFObject!, error: NSError!) -> Void in
                  if error == nil {
                    CloudUtility.updateLastVybe(obj)
                    
                    trb.coverVybe = obj
                    let indexPath = NSIndexPath(forRow: idx, inSection: 0)
                    self.collectionView?.reloadItemsAtIndexPaths([indexPath])
                  }
                })
              }
            }
          })
        }
        self.refreshControl?.endRefreshing()
      })
    }
    
    NSUserDefaults.standardUserDefaults().setObject(NSDate(), forKey: kVYBUserDefaultsLastRefreshKey)
  }
  
  func refreshControlPulled() {
    self.loadTribesFromCloud()
  }
  
  func appDelegateDidReceiveRemoteNotification(notification: NSNotification) {
    if let payload = notification.userInfo {
      if let pushType = payload[kVYBPushPayloadPayloadTypeKey] as? String {
        if pushType == kVYBPushPayloadPayloadTypeVybeKey {
      
        }
      }
    }
  }

  // MARK: - CreateTribeDelegate
  
  func didCreateTribe(tribe: AnyObject) {
    MyVybeStore.sharedInstance.currTribe = tribe as? PFObject
    
    let newTrb = Tribe(parseObj: tribe)
    tribes += [newTrb]
    
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
    return tribes.count
  }
  
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
    if UIScreen.mainScreen().bounds.size.width > 320 {
      // iPhone6
      return CGSizeMake(100.0, 135.0)
    } else {
      return CGSizeMake(84.0, 119.0)
    }
  }
  
  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as TribeCollectionCell
    // NOTE: - Initially a cell's subviews need to be updated for a new bounds of the cell.
    cell.layoutIfNeeded()
    
    let tribe = tribes[indexPath.row] as Tribe
    
    cell.tribeObject = tribe
    cell.delegate = self

    cell.nameLabel.text = tribe.tribeObject.objectForKey(kVYBTribeNameKey) as? String
  
    var borderColor: UIColor = UIColor.clearColor()
    if tribe.freshCount > 0 {
      borderColor = UIColor(red: 74/255.0, green: 144/255.0, blue: 226/255.0, alpha: 1.0)
    }

    cell.photoImageView.makeCircleWithBorderColor(borderColor, width: 4.0)
    
    var photoFile: PFFile!
    if let cover = tribe.coverVybe as? PFObject {
      if let file = cover[kVYBVybeThumbnailKey] as? PFFile {
        photoFile = file
        cell.photoImageView.file = photoFile
        cell.photoImageView.loadInBackground({ (image: UIImage!, error: NSError!) -> Void in
          if image != nil {
            var maskImage: UIImage?
            if image.size.height > image.size.width {
              maskImage = UIImage(named: "thumbnail_mask_portrait")
            } else {
              maskImage = UIImage(named: "thumbnail_mask_landscape")
            }
            cell.photoImageView.image = VYBUtility.maskImage(image, withMask: maskImage)
          }
        })
      }
    } else {
      cell.photoImageView.image = UIImage(named: "Placeholder_Tribe")
    }
    
    return cell
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "ShowCreateTribeSegue" {
      if let createTribeVC = segue.destinationViewController as? CreateTribeViewController {
        createTribeVC.delegate = self
      }
    } else if segue.identifier == "ShowTribeInfoSegue" {
      if let tribeDetails = segue.destinationViewController as? TribeDetailsViewController {
        tribeDetails.tribeObj = selectedTribe
      }
    }
  }
  
  func didSelectTribeToShowInfo(obj: AnyObject) {
    selectedTribe = obj
    self.performSegueWithIdentifier("ShowTribeInfoSegue", sender: nil)
  }
  
  func didSelectTribeToPlay(obj: AnyObject?) {
    if let tribe = obj as? Tribe {
      let playerVC = VYBPlayerViewController(nibName: "VYBPlayerViewController", bundle: nil)
      playerVC.delegate = self
      playerVC.playStreamForTribe(tribe)
    }
  }
  
  func playVybeFromPushNotification(tribeID: String) {
    let tribe = PFObject(withoutDataWithClassName: kVYBTribeClassKey, objectId: tribeID)
    
    let newQ = PFQuery(className: kVYBVybeClassKey)
    newQ.whereKey(kVYBVybeTribeKey, equalTo: tribe)
    newQ.whereKey(kVYBVybeTimestampKey, greaterThanOrEqualTo: NSUserDefaults.standardUserDefaults().objectForKey(kVYBUserDefaultsLastRefreshKey))
    let localQ = PFQuery(className: kVYBVybeClassKey)
    localQ.whereKey(kVYBVybeTribeKey, equalTo: tribe)
    localQ.fromPinWithName("MyFreshFeed")
    
    let query = PFQuery.orQueryWithSubqueries([newQ, localQ])
    query.orderByAscending(kVYBVybeTimestampKey)
    query.includeKey(kVYBVybeUserKey)
    
    query.findObjectsInBackgroundWithBlock { (result: [AnyObject]!, error: NSError!) -> Void in
      if result != nil {
        let playerVC = VYBPlayerViewController(nibName: "VYBPlayerViewController", bundle: nil)
        playerVC.delegate = self
        playerVC.playStream(result)
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
  
  @IBAction func settingsButtonPressed(sender: AnyObject) {
    var username: String = "Vyber"
    if let name = PFUser.currentUser()[kVYBUserUsernameKey] as? String {
      username = name
    }
    
    let alertController = UIAlertController(title: "Hello \(username)", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
    let logOutAction = UIAlertAction(title: "Log Out", style: .Destructive) { (action: UIAlertAction!) -> Void in
      if let appDelegate = UIApplication.sharedApplication().delegate as? VYBAppDelegate {
        appDelegate.logOut()
      }
    }
    
    let goBackAction = UIAlertAction(title: "Go Back", style: .Cancel, handler: nil)
    
    alertController.addAction(logOutAction)
    alertController.addAction(goBackAction)
    
    self.presentViewController(alertController, animated: true, completion: nil)
  }
  
  // MARK: - UIScrollViewDelegate
  
  override func scrollViewDidScroll(scrollView: UIScrollView) {
    if let button = captureButton {
      var frame = button.frame
      frame.origin.y = scrollView.contentOffset.y + self.view.bounds.size.height - captureButton!.bounds.size.height - 25
      button.frame = frame
    }
  }
  
  override func supportedInterfaceOrientations() -> Int {
    return UIInterfaceOrientation.Portrait.rawValue
  }
  
  override func shouldAutorotate() -> Bool {
    return false
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

}
