//
//  TribesViewController.swift
//  Vybe
//
//  Created by Jinsu Kim on 2/17/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

@objc class Tribe {
  var tribeObject: AnyObject
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
  
  @IBAction func settingsButtonPressed(sender: AnyObject) {
    let username: String
    if let name = PFUser.currentUser()[kVYBUserUsernameKey] as? String {
      username = name
    } else {
      username = "Vyber"
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
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    var textAttributes = [NSObject : AnyObject]()
    if let font = UIFont(name: "HelveticaNeue-Medium", size: 18.0) {
      let textColor = UIColor(red: 255.0/255.0, green: 76.0/255.0, blue: 70.0/255.0, alpha: 1.0)
      textAttributes[NSFontAttributeName] = font
      textAttributes[NSForegroundColorAttributeName] = textColor
      self.navigationController?.navigationBar.titleTextAttributes = textAttributes
    }
    
    let control = UIRefreshControl()
    control.addTarget(self, action: "refreshControlPulled", forControlEvents: UIControlEvents.ValueChanged)
    collectionView?.addSubview(control)
    collectionView?.alwaysBounceVertical = true
    
    refreshControl = control
    
    let button = UIButton(frame: CGRectMake(20, self.view.bounds.height - 50, 30, 30))
    button.setImage(UIImage(named: "SmallPrivatecircle_selected"), forState: UIControlState.Normal)
    button.addTarget(self, action: "moveToCapture", forControlEvents: UIControlEvents.TouchUpInside)
    captureButton = button
    
//    self.view.addSubview(button)
    
    self.reloadTribes{  }
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
  
    // First reset freshCount for each tribe
    if let tribes = tribes as? [Tribe] {
      for tribe in tribes {
        tribe.freshCount = 0
      }
    }
    let query = PFQuery(className: kVYBVybeClassKey)
    query.fromPinWithName("MyFreshFeed")
    query.findObjectsInBackgroundWithBlock { (result :[AnyObject]!, error: NSError!) -> Void in
      if error == nil {
        for vybeObj in result {
          if let trObj = vybeObj.objectForKey(kVYBVybeTribeKey) as? PFObject {
            if let trbs = self.tribes as? [Tribe] {
              innerLoop: for tribe in trbs {
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
      self.reloadMyFeed()
    }
    
  }
  
  func refreshControlPulled() {
    self.reloadTribes { () -> Void in
      self.reloadMyFeed()
    }
  }
  
  private func reloadTribes(completionBlock: (() -> ())) {
    // Update all tribe list
    PFObject.unpinAllObjectsInBackgroundWithName("MyTribes", block: { (success: Bool, error: NSError!) -> Void in
      let query = PFQuery(className: kVYBTribeClassKey)
      query.whereKey(kVYBTribeMembersKey, equalTo: PFUser.currentUser())
      query.findObjectsInBackgroundWithBlock({ (result: [AnyObject]!, error: NSError!) -> Void in
        if result != nil {
          PFObject.pinAllInBackground(result, withName: "MyTribes", block: {
            (success: Bool, error: NSError!) -> Void in
            if let objects = result as? [PFObject] {
              self.tribes = []
              
              for obj in objects {
                let newTribe = Tribe(parseObj: obj)
                self.tribes += [newTribe]
              }
              completionBlock()
            }
          })
        }
      })
    })
  }
  
  private func reloadMyFeed() {
    // First reset freshCount for each tribe
    if let arr = tribes as? [Tribe] {
      for tribe in arr {
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
                  if let tribes = self.tribes as? [Tribe] {
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
    } else if segue.identifier == "ShowTribeInfoSegue" {
      if let tribeDetails = segue.destinationViewController as? TribeDetailsViewController {
        tribeDetails.tribeObj = selectedTribe
      }
    }
  }
  
  // MARK: - CreateTribeDelegate
  
  func didCreateTribe(tribe: AnyObject) {
    MyVybeStore.sharedInstance.currTribe = tribe as? PFObject
    
    let new = Tribe(parseObj: tribe)
    tribes += [new]
    
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
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! TribeCollectionCell
    // NOTE: - Initially a cell's subviews need to be updated for a new bounds of the cell.
    cell.layoutIfNeeded()
    
    let tribe = tribes[indexPath.row] as! Tribe
    
    cell.tribeObject = tribe.tribeObject
    cell.delegate = self

    cell.nameLabel.text = tribe.tribeObject.objectForKey(kVYBTribeNameKey) as? String
  
    let borderColor: UIColor
    if tribe.freshCount > 0 {
      borderColor = UIColor(red: 74/255.0, green: 144/255.0, blue: 226/255.0, alpha: 1.0)
    } else {
      borderColor = UIColor.clearColor()
    }
    cell.photoImageView.makeCircleWithBorderColor(borderColor, width: 4.0)
    
    if let file = tribe.tribeObject[kVYBTribePhotoKey] as? PFFile {
      cell.photoImageView.file = file
      cell.photoImageView.loadInBackground({ (image: UIImage!, error: NSError!) -> Void in
        if image != nil {
          let maskImage = UIImage(named: "SquareMask")
          cell.photoImageView.image = VYBUtility.maskImage(image, withMask: maskImage)
        }
      })
    } else {
      cell.photoImageView.image = UIImage()
    }
    
    return cell
  }
  
  func didSelectTribeToShowInfo(obj: AnyObject) {
    selectedTribe = obj
    self.performSegueWithIdentifier("ShowTribeInfoSegue", sender: nil)
  }
  
  func didSelectTribeToPlay(obj: AnyObject) {
    if let tribe = obj as? PFObject {
      let playerVC = VYBPlayerViewController(nibName: "VYBPlayerViewController", bundle: nil)
      playerVC.delegate = self
      playerVC.playStreamForTribe(tribe)
    }
  }
  
  func playVybeFromPushNotification(tribeID: String) {
    let tribe = PFObject(withoutDataWithClassName: kVYBTribeClassKey, objectId: tribeID)
    
    let query = PFQuery(className: kVYBVybeClassKey)
    query.fromPinWithName("MyFreshFeed")
    query.whereKey(kVYBVybeTribeKey, equalTo: tribe)
    query.includeKey(kVYBVybeUserKey)
    query.orderByAscending(kVYBVybeTimestampKey)
    
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
  
  // MARK: - UIScrollViewDelegate
  override func scrollViewDidScroll(scrollView: UIScrollView) {
    if let button = captureButton {
      var frame = button.frame
      frame.origin.y = scrollView.contentOffset.y + self.view.bounds.size.height - captureButton!.bounds.size.height
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
