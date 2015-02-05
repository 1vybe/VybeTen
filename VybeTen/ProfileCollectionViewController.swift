//
//  ProfileCollectionViewController.swift
//  Vybe
//
//  Created by Jinsu Kim on 2/3/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class ProfileCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
  var collectionObjects: [AnyObject]
  
  deinit {
    println("Profile Collection Deinit")
  }

  required init(coder aDecoder: NSCoder) {
    collectionObjects = []

    super.init(coder: aDecoder)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    println("My Vybes Collection viewDidLoad")

    // Do any additional setup after loading the view.
    let query = PFQuery(className: kVYBVybeClassKey)
    query.whereKey(kVYBVybeUserKey, equalTo: PFUser.currentUser())
    query.includeKey(kVYBVybeUserKey)
    query.orderByDescending(kVYBVybeTimestampKey)

    query.findObjectsInBackgroundWithBlock { (result: [AnyObject]!, error: NSError!) -> Void in
      if error == nil {
        self.collectionObjects = result
        self.collectionView?.reloadData()
      }
    }
  }
  
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return collectionObjects.count
  }
  
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
    if collectionView.bounds.size.width > 320 {
      // iPhone6
      return CGSizeMake(90.0, 96.0)
    } else {
      return CGSizeMake(76.0, 81.0)
    }
  }
  
  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier("VybeCollectionCellIdentifier", forIndexPath: indexPath) as UICollectionViewCell
    
    let object = collectionObjects[indexPath.row] as PFObject
    
    if let thumbnailFile = object[kVYBVybeThumbnailKey] as? PFFile {
      if let imageView = cell.viewWithTag(235) as? PFImageView {
        imageView.file = thumbnailFile
        imageView.loadInBackground({ (image: UIImage!, error: NSError!) -> Void in
          if image != nil {
            var maskImage: UIImage?
            if image.size.height > image.size.width {
              // Portrait
              maskImage = UIImage(named: "Mask_P")
            } else {
              maskImage = UIImage(named: "Mask_L")
            }
            imageView.image = VYBUtility.maskImage(image, withMask: maskImage)
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
