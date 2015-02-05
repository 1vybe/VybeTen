//
//  ProfileTableViewController.swift
//  Vybe
//
//  Created by Jinsu Kim on 2/3/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class ProfileListViewController: PFQueryTableViewController {
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    paginationEnabled = false
    pullToRefreshEnabled = true
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
   
    println("My Vybes Table viewDidLoad")
    
    tableView.estimatedRowHeight = 300.0
    tableView.rowHeight = UITableViewAutomaticDimension
    
    tableView.tableFooterView = UIView(frame: CGRectZero)
    
    // Do any additional setup after loading the view.
  }
  
  override func objectsDidLoad(error: NSError!) {
    super.objectsDidLoad(error)
  }
  
  override func queryForTable() -> PFQuery! {
    let query = PFQuery(className: kVYBVybeClassKey)
    query.whereKey(kVYBVybeUserKey, equalTo: PFUser.currentUser())
    query.includeKey(kVYBVybeUserKey)
    query.orderByDescending(kVYBVybeTimestampKey)
    
    return query
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return objects.count + 1
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    if indexPath.row == 0 {
      return tableView.dequeueReusableCellWithIdentifier("EmptyListCell") as UITableViewCell
    }
    
    let cell = tableView.dequeueReusableCellWithIdentifier("ListVybeCardCell") as VybeCardCell
    
    if let vybeObj = objects[indexPath.row - 1] as? PFObject {
      if let thumbnailFile = vybeObj.objectForKey(kVYBVybeThumbnailKey) as? PFFile {
        cell.thumbnailImageView.file = thumbnailFile
        cell.thumbnailImageView.loadInBackground({ (image: UIImage!, error: NSError!) -> Void in
          if image != nil {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
              cell.thumbnailImageView.image = image
            })
          }
        })
      }
    }
    
    return cell
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
}
