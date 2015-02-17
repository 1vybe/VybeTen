//
//  ProfileTableViewController.swift
//  Vybe
//
//  Created by Jinsu Kim on 2/3/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class ProfileListViewController: PFQueryTableViewController {
  
  deinit {
    println("Profile List Deinit")
  }
  
//  required init(coder aDecoder: NSCoder) {
//    super.init(coder: aDecoder)
//    
//    paginationEnabled = false
//    pullToRefreshEnabled = true
//  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
   
    println("Profile List viewDidLoad")
        
    tableView.estimatedRowHeight = 300.0
    tableView.rowHeight = UITableViewAutomaticDimension
    
    tableView.contentInset = UIEdgeInsetsMake(86.0, 0.0, 0.0, 0.0)
    
    tableView.tableFooterView = UIView(frame: CGRectZero)
  }
  
  override func queryForTable() -> PFQuery! {
    let query = PFQuery(className: kVYBVybeClassKey)
    query.whereKey(kVYBVybeUserKey, equalTo: PFUser.currentUser())
    query.includeKey(kVYBVybeUserKey)
    query.orderByDescending(kVYBVybeTimestampKey)
    
    return query
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return objects.count
  }
  
  override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 0.0
  }
  
  override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return 0.0
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {    
    let cell = tableView.dequeueReusableCellWithIdentifier("ListVybeCardCell") as! VybeCardCell
    
    if let vybeObj = objects[indexPath.row] as? PFObject {
      if let thumbnailFile = vybeObj.objectForKey(kVYBVybeThumbnailKey) as? PFFile {
        cell.thumbnailImageView.file = thumbnailFile
        cell.thumbnailImageView.loadInBackground({ (image: UIImage!, error: NSError!) -> Void in
          if image != nil {
            var maskImage: UIImage?
            if image.size.height > image.size.width {
              // Portrait
              maskImage = UIImage(named: "Mask_P")
            } else {
              maskImage = UIImage(named: "Mask_L")
            }
            cell.thumbnailImageView.image = VYBUtility.maskImage(image, withMask: maskImage)
          }
        })
      }
    }
    
    return cell
  }
  
  override func scrollViewDidScroll(scrollView: UIScrollView) {    
//    println("[profileList] offset \(scrollView.contentOffset)")
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
}
