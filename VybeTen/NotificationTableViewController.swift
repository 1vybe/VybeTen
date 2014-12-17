//
//  NotificationTableViewController.swift
//  VybeTen
//
//  Created by Jinsu Kim on 12/17/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit

class NotificationTableViewController: UITableViewController, VYBPlayerViewControllerDelegate {
  var objects = [PFObject]()
  
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
    
    if let user = PFUser.currentUser() {
      if let allActivities = VYBCache.sharedCache().bumpActivitiesForUser(user) as? [PFObject] {
        // we do NOT want to include bumps from ourself
        for activity in allActivities {
          if let fromUser = activity[kVYBActivityFromUserKey] as? PFObject {
            if fromUser.objectId != PFUser.currentUser().objectId {
              objects += [activity]
            }
          }
        }
      }
    }
    
    VYBUtility.updateLastRefreshForCurrentUser()
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
    return objects.count
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("BumpForMeCell", forIndexPath: indexPath) as UITableViewCell
  
    let activityObj = objects[indexPath.row]
    
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
    let activityObj = objects[indexPath.row]
    if let vybe = activityObj[kVYBActivityVybeKey] as? PFObject {
      var playerVC = VYBPlayerViewController(nibName: "VYBPlayerViewController", bundle: nil)
      playerVC.delegate = self
      playerVC.playOnce(vybe)
    }
  }
  
  // MARK: - PlayerViewControllerDelegate
  
  func playerViewController(playerVC: VYBPlayerViewController!, didFinishSetup ready: Bool) {
    self.presentViewController(playerVC, animated: true, completion: nil)
  }
  
  @IBAction func closeButtonPressed(sender: AnyObject) {
    self.navigationController?.popViewControllerAnimated(true)
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return false
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
