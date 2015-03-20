//
//  HomeViewController.swift
//  VybeTen
//
//  Created by Jinsu Kim on 1/23/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit
import Parse

class HomeViewController: PFQueryTableViewController, PlayerDelegate {
  enum FilterMode: Int {
    case New = 0
    case Hot
  }
  
  @IBOutlet weak var filterModeControl: UISegmentedControl!
  
  @IBAction func filterModeChanged(sender: AnyObject) {
    
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    self.paginationEnabled = true
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func queryForTable() -> PFQuery! {
    let query = PFQuery(className: kVYBVybeClassKey)
    query.includeKey(kVYBVybeUserKey)
    
    if filterModeControl.selectedSegmentIndex == 0 {
      query.orderByDescending(kVYBVybeTimestampKey)
    } else {
      // TODO: - How to efficiently order vybes by votes?
      query.orderByDescending(kVYBVybeTimestampKey)
    }
    return query
  }
  
  override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!, object: PFObject!) -> PFTableViewCell! {
    var cell = tableView.dequeueReusableCellWithIdentifier("HomeVybeCardCell", forIndexPath: indexPath) as PFTableViewCell
    
    if let thumbnailFile = object[kVYBVybeThumbnailKey] as? PFFile {
      if let imgView = cell.viewWithTag(123) as? PFImageView {
        imgView.file = thumbnailFile
        imgView.loadInBackground()
      }
    }
    
    if let user = object[kVYBVybeUserKey] as? PFObject {
      if let username = user[kVYBUserUsernameKey] as? String {
        if let nameLabel = cell.viewWithTag(235) as? UILabel {
          nameLabel.text = username
        }
      }
    }
    
    if let timestamp = object[kVYBVybeTimestampKey] as? NSDate {
      if let timeLabel = cell.viewWithTag(358) as? UILabel {
        timeLabel.text = VYBUtility.reverseTime(timestamp)
      }
    }
    
    return cell
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let fromIdx = indexPath.row
    let toIdx = self.objects.count - 1
    let playlist = self.objects[fromIdx...toIdx]
    
    let playerVC = PlayerViewController(nibName: "PlayerViewController", bundle: nil)
    playerVC.query = self.queryForTable()
    playerVC.delegate = self
    playerVC.play(Array(playlist))
  }
  
  func didFinishSetup(success: Bool, vc: PlayerViewController) {
    if success {
      self.presentViewController(vc, animated: true, completion: nil)
    }
  }
  
  func didDismissPlayer(vc: PlayerViewController) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
}
