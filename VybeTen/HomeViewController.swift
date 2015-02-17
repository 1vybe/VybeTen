//
//  HomeViewController.swift
//  VybeTen
//
//  Created by Jinsu Kim on 1/23/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class HomeViewController: UITableViewController {
  var tableObjects = [PFObject]()
  
  override func viewDidLoad() {
    super.viewDidLoad()

    let params = [:]
    PFCloud.callFunctionInBackground("get_fresh_vybes", withParameters: params as! [NSObject : AnyObject]) { (result: AnyObject!, error: NSError!) -> Void in
      if error == nil {
        if let list = result as? [AnyObject] {
          self.tableObjects = list.reverse() as! [PFObject]
          self.tableView.reloadData()
        }
      }
    }
    // Do any additional setup after loading the view.
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return tableObjects.count
  }
  
  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    if let fullHeight = UIApplication.sharedApplication().keyWindow?.bounds.height {
      return fullHeight
    }
    return 0
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    var cell = tableView.dequeueReusableCellWithIdentifier("VybeCardCell", forIndexPath: indexPath) as! VybeCardCell
    
    cell.contentView.frame = cell.bounds;
    cell.contentView.autoresizingMask = .FlexibleWidth | .FlexibleHeight;

    if let vybeThumbnailFile = tableObjects[indexPath.row].objectForKey(kVYBVybeThumbnailKey) as? PFFile {
      cell.thumbnailImageView.file = vybeThumbnailFile
      cell.thumbnailImageView.loadInBackground({ (image: UIImage!, error: NSError!) -> Void in
        if image != nil {
          if image.size.height > image.size.width {
            cell.thumbnailImageView.image = image;
          } else {
            let rotatedImg = UIImage(CGImage: image.CGImage, scale: 1.0, orientation: UIImageOrientation.Right)
            cell.thumbnailImageView.image = rotatedImg
          }
        }
      })
    }
    
    return cell
  }
  
}
