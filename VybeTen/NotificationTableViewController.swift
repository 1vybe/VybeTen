//
//  NotificationTableViewController.swift
//  VybeTen
//
//  Created by Jinsu Kim on 12/17/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit

class NotificationTableViewController: UITableViewController, VYBPlayerViewControllerDelegate {
  @IBOutlet weak var segmentedControl: UISegmentedControl!
  
  var activities = [PFObject]()
  var watchedItems = [PFObject]()
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self, name: VYBAppDelegateHandlePushPlayActivityNotification, object: nil)
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "playActivity:", name: VYBAppDelegateHandlePushPlayActivityNotification, object: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = false
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    
    let textAttributes = NSMutableDictionary()
    if let font = UIFont(name: "Avenir Next", size: 14.0) {
      let textColor = UIColor(red: 247.0/255.0, green: 109.0/255.0, blue: 60.0/255.0, alpha: 1.0)
      textAttributes.setObject(font, forKey: NSFontAttributeName)
      textAttributes.setObject(textColor, forKey: NSForegroundColorAttributeName)
      self.navigationController?.navigationBar.titleTextAttributes = textAttributes
    }
    
    let segmentedControlTextAttributes = NSMutableDictionary()
    if let font = UIFont(name: "Avenir Next", size: 10.0) {
      let mainColor = UIColor(red: 247.0/255.0, green: 109.0/255.0, blue: 60.0/255.0, alpha: 1.0)
      segmentedControl.tintColor = mainColor
      segmentedControlTextAttributes.setObject(font, forKey: NSFontAttributeName)
      segmentedControl.setTitleTextAttributes(segmentedControlTextAttributes, forState: UIControlState.Normal)
      segmentedControl.setTitleTextAttributes(segmentedControlTextAttributes, forState: UIControlState.Selected)
    }
    
    segmentedControl.addTarget(self, action: "segmentedControlChanged:", forControlEvents: .ValueChanged)
    
    VYBCache.sharedCache().refreshBumpsForMeInBackground { (success: Bool) -> Void in
      if success {
        self.reloadActivitiesForMe()
      }
    }
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

    if segmentedControl.selectedSegmentIndex == 0 { // My Vybes
      VYBCache.sharedCache().refreshBumpsForMeInBackground({ (success: Bool) -> Void in
        if success {
          self.reloadActivitiesForMe()
        }
      })
    } else { // My Bumps
      VYBCache.sharedCache().refreshMyBumpsInBackground({ (success: Bool) -> Void in
        self.reloadMyActivities()
      })
    }
  }
  
  func segmentedControlChanged(segControl: UISegmentedControl) {
    let selectedIdx = segControl.selectedSegmentIndex
    if segmentedControl.selectedSegmentIndex == 0 { // My Vybes
      segmentedControl.enabled = false
      VYBCache.sharedCache().refreshBumpsForMeInBackground({ (success: Bool) -> Void in
        if success {
          self.reloadActivitiesForMe()
        }
        dispatch_async(dispatch_get_main_queue()) {
          self.segmentedControl.enabled = true
        }
      })
    } else { // My Bumps
      segmentedControl.enabled = false
      VYBCache.sharedCache().refreshMyBumpsInBackground({ (success: Bool) -> Void in
        if success {
          self.reloadMyActivities()
        }
        dispatch_async(dispatch_get_main_queue()) {
          self.segmentedControl.enabled = true
        }
      })
    }
  }

  
  // MARK: - Table view data source
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return activities.count
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    var cell: UITableViewCell
    var username: String = "Someone"
    var timeString: String = "Earth, "
    
    let activityObj = activities[indexPath.row]
    
    if segmentedControl.selectedSegmentIndex == 0 { // My Vybes
      if self.isUnwatchedActivity(activityObj) {
        cell = tableView.dequeueReusableCellWithIdentifier("NewBumpForMeCell", forIndexPath: indexPath) as UITableViewCell
      } else {
        cell = tableView.dequeueReusableCellWithIdentifier("BumpForMeCell", forIndexPath: indexPath) as UITableViewCell
      }
      
      if let fromUser = activityObj[kVYBActivityFromUserKey] as? PFObject {
        username = fromUser[kVYBUserUsernameKey] as String
      }
      
      timeString = VYBUtility.reverseTime(activityObj.createdAt)
    } else {
      cell = tableView.dequeueReusableCellWithIdentifier("MyBumpCell", forIndexPath: indexPath) as UITableViewCell
      
      if let toUser = activityObj[kVYBActivityToUserKey] as? PFObject {
        username = toUser[kVYBUserUsernameKey] as String
      }
      
      if let vybeObj = activityObj[kVYBActivityVybeKey] as? PFObject {
        if let zoneName = vybeObj[kVYBVybeZoneNameKey] as? String {
          timeString = "\(zoneName), "
        }
        if let timestamp = vybeObj[kVYBVybeTimestampKey] as? NSDate {
          timeString += VYBUtility.timeStringForPlayer(timestamp)
        }
      }
    }
    
    var usernameLabel = cell.viewWithTag(70) as UILabel
    usernameLabel.text = username
    
    var timeLabel = cell.viewWithTag(71) as UILabel
    timeLabel.text = timeString
    
    if let vybe = activityObj[kVYBActivityVybeKey] as? PFObject {
      var thumbnailView = cell.viewWithTag(72) as PFImageView
      if let thumbnailFile = vybe[kVYBVybeThumbnailKey] as? PFFile {
        thumbnailView.file = thumbnailFile
        thumbnailView.loadInBackground({ (image: UIImage!, error: NSError!) -> Void in
          if error == nil {
            if image != nil {
              var maskImage: UIImage?
              if image.size.height > image.size.width {
                maskImage = UIImage(named: "thumbnail_mask_portrait")
              } else {
                maskImage = UIImage(named: "thumbnail_mask_landscape")
              }
              thumbnailView.image = VYBUtility.maskImage(image, withMask: maskImage)
            }
          } else {
            thumbnailView.image = UIImage(named: "Placeholder")
          }
        })
      }
    }
    
    return cell
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let activityObj = activities[indexPath.row]
    if let vybe = activityObj[kVYBActivityVybeKey] as? PFObject {
      if segmentedControl.selectedSegmentIndex == 0 { // My Vybes
        var playerVC = VYBPlayerViewController(nibName: "VYBPlayerViewController", bundle: nil)
        playerVC.delegate = self
        playerVC.playOnce(vybe)
        
        self.addWatchedActivity(activityObj)
      } else {
        var vybes = [PFObject]()
        for activity in activities {
          if let vybe = activity[kVYBActivityVybeKey] as? PFObject {
            vybe[kVYBVybeUserKey] = activity[kVYBActivityToUserKey]
            vybes += [vybe]
          }
        }
        
        vybes.sort({ (vybe1: PFObject, vybe2: PFObject) -> Bool in
          let firstTimestamp = vybe1[kVYBVybeTimestampKey] as NSDate
          let comparisonResult = firstTimestamp.compare(vybe2[kVYBVybeTimestampKey] as NSDate)
          
          return comparisonResult == NSComparisonResult.OrderedAscending
        })
        
        var playerVC = VYBPlayerViewController(nibName: "VYBPlayerViewController", bundle: nil)
        playerVC.delegate = self
        playerVC.playStream(vybes, from: vybe)
      }
    }
  }
  
  private func addWatchedActivity(activity: PFObject) {
    for obj in watchedItems {
      if obj.objectId == activity.objectId {
        return
      }
    }
    
    watchedItems += [activity]
  }
  
  // MARK: - PlayerViewControllerDelegate
  
  func playerViewController(playerVC: VYBPlayerViewController!, didFinishSetup ready: Bool) {
    if ready {
      self.presentViewController(playerVC, animated: true, completion: nil)
    }
  }
  
  @IBAction func closeButtonPressed(sender: AnyObject) {
    // If a user dismisses this screen, we assume the user has seen all new activities
    VYBUtility.updateLastRefreshForCurrentUser()

    self.navigationController?.popViewControllerAnimated(true)
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return false
  }
  
  func reloadActivitiesForMe() {
    activities = []
    if let newObjs = VYBCache.sharedCache().bumpActivitiesForUser(PFUser.currentUser()) as? [PFObject] {
      // we do NOT want to include vybes from ourself
      for activity in newObjs {
        if let fromUser = activity[kVYBActivityFromUserKey] as? PFObject {
          if fromUser.objectId != PFUser.currentUser() .objectId {
            activities += [activity]
          }
        }
      }
    }
    
    activities.sort { (activity1: PFObject, activity2: PFObject) -> Bool in
      let comparisonResult = activity1.createdAt.compare(activity2.createdAt)
      return comparisonResult == NSComparisonResult.OrderedDescending
    }
    
    self.tableView.reloadData()
  }
  
  func reloadMyActivities() {
    if let newObjs =  VYBCache.sharedCache().myBumpActivities() as? [PFObject] {
      activities = newObjs
      
      activities.sort { (activity1: PFObject, activity2: PFObject) -> Bool in
        let comparisonResult = activity1.createdAt.compare(activity2.createdAt)
        return comparisonResult == NSComparisonResult.OrderedDescending
      }
      
      self.tableView.reloadData()
    }
  }
  
  // MARK: - Play Activity (from remote notification)
  func playActivity(notificaton: NSNotification) {
    if let objId = notificaton.userInfo?[kVYBPushPayloadActivityIDKey] as? String {
      var query = PFQuery(className: kVYBActivityClassKey)
      query.whereKey("objectId", equalTo: objId)
      query.includeKey(kVYBActivityVybeKey)
      query.includeKey(kVYBActivityFromUserKey)
      query.getFirstObjectInBackgroundWithBlock({ (activityObj: PFObject!, error: NSError!) -> Void in
        if error == nil {
          if let vybe = activityObj[kVYBActivityVybeKey] as? PFObject {
            if let user = activityObj[kVYBActivityFromUserKey] as? PFObject {
              vybe[kVYBVybeUserKey] = user
              
              var playerVC = VYBPlayerViewController(nibName: "VYBPlayerViewController", bundle: nil)
              playerVC.delegate = self
              playerVC.playOnce(vybe)
              
              self.addWatchedActivity(activityObj)
            }
          }
        }
      })
    }
  }
  
  // MARK: - Helper Functions
  
  private func isUnwatchedActivity(activity: PFObject) -> Bool {
    for obj in watchedItems {
      if obj.objectId == activity.objectId {
        return false
      }
    }
    
    if let lastRefresh = NSUserDefaults.standardUserDefaults().objectForKey(kVYBUserDefaultsActivityLastRefreshKey) as? NSDate {
      let comparisonResult = lastRefresh.compare(activity.createdAt)
      
      if comparisonResult == NSComparisonResult.OrderedSame ||
        comparisonResult == NSComparisonResult.OrderedDescending {
        return false
      } else {
        return true
      }
    }
    return true
  }
  
  // MARK: - Orientation
  override func shouldAutorotate() -> Bool {
    return true
  }
  
  override func supportedInterfaceOrientations() -> Int {
    return Int(UIInterfaceOrientationMask.Portrait.rawValue)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  
}
