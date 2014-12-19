//
//  NotificationTableViewController.swift
//  VybeTen
//
//  Created by Jinsu Kim on 12/17/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit

class NotificationTableViewController: UITableViewController, VYBPlayerViewControllerDelegate {
  var activities = [PFObject]()
  var watchedItems = [PFObject]()
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self, name: VYBCacheRefreshedBumpActivitiesForCurrentUser, object: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshActivityTable", name: VYBCacheRefreshedBumpActivitiesForCurrentUser, object: nil)
    
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
    
    VYBCache.sharedCache().refreshBumpsForMeInBackground()
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

    VYBCache.sharedCache().refreshBumpsForMeInBackground()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
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
  
    let activityObj = activities[indexPath.row]
    if self.isUnwatchedActivity(activityObj) {
      cell = tableView.dequeueReusableCellWithIdentifier("NewBumpForMeCell", forIndexPath: indexPath) as UITableViewCell
    } else {
      cell = tableView.dequeueReusableCellWithIdentifier("BumpForMeCell", forIndexPath: indexPath) as UITableViewCell
    }
    
    var fromUsername = "Someone"
    if let fromUser = activityObj[kVYBActivityFromUserKey] as? PFObject {
      fromUsername = fromUser[kVYBUserUsernameKey] as String
    }
    var usernameLabel = cell.viewWithTag(70) as UILabel
    usernameLabel.text = fromUsername
    
    
    let timeString = VYBUtility.reverseTime(activityObj.createdAt)
    var timeLabel = cell.viewWithTag(71) as UILabel
    timeLabel.text = timeString

    
    if let vybe = activityObj[kVYBActivityVybeKey] as? PFObject {
      var thumbnailView = cell.viewWithTag(72) as PFImageView
      thumbnailView.file = vybe[kVYBVybeThumbnailKey] as PFFile
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
          thumbnailView.image = UIImage(named: "OverlayThumbnail")
        }
      })
    }
    
    return cell
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let activityObj = activities[indexPath.row]
    if let vybe = activityObj[kVYBActivityVybeKey] as? PFObject {
      var playerVC = VYBPlayerViewController(nibName: "VYBPlayerViewController", bundle: nil)
      playerVC.delegate = self
      playerVC.playOnce(vybe)
      
      self.addWatchedActivity(activityObj)
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
    self.presentViewController(playerVC, animated: true, completion: nil)
  }
  
  @IBAction func closeButtonPressed(sender: AnyObject) {
    // If a user dismisses this screen, we assume the user has seen all new activities
    VYBUtility.updateLastRefreshForCurrentUser()

    self.navigationController?.popViewControllerAnimated(true)
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return false
  }
  
  // MARK: - VYBCacheRefreshedBumpActivities Notification
  
  func refreshActivityTable() {
    activities = []
    if let user = PFUser.currentUser() {
      if let allActivities = VYBCache.sharedCache().bumpActivitiesForUser(user) as? [PFObject] {
        // we do NOT want to include bumps from ourself
        for activity in allActivities {
          if let fromUser = activity[kVYBActivityFromUserKey] as? PFObject {
            if fromUser.objectId != user.objectId {
              activities += [activity]
            }
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
  
  /*
  // Override to support conditional editing of the table view.
  override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
  // Return NO if you do not want the specified item to be editable.
  return true
  }
  */
  
  /*
  // Override to support editing the table view.
  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
  if editingStyle == .Delete {
  // Delete the row from the data source
  tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
  } else if editingStyle == .Insert {
  // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
  }
  }
  */
  
  /*
  // Override to support rearranging the table view.
  override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
  
  }
  */
  
  /*
  // Override to support conditional rearranging of the table view.
  override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
  // Return NO if you do not want the item to be re-orderable.
  return true
  }
  */
  
  /*
  // MARK: - Navigation
  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
  // Get the new view controller using [segue destinationViewController].
  // Pass the selected object to the new view controller.
  }
  */
  
}
