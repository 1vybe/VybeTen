//
//  TribesViewController.swift
//  Vybe
//
//  Created by Jinsu Kim on 2/17/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

let reuseIdentifier = "TribeCollectionCell"

class TribesViewController: UICollectionViewController {
  var tribeObjects: [AnyObject]
  
  required init(coder aDecoder: NSCoder) {
    tribeObjects = []

    super.init(coder: aDecoder)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let query = PFQuery(className: kVYBTribeClassKey)
    query.fromLocalDatastore()
    query.findObjectsInBackgroundWithBlock { (result: [AnyObject]!, error: NSError!) -> Void in
      if result != nil {
        self.tribeObjects = result
        self.collectionView?.reloadData()
      }
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  // MARK: UICollectionViewDataSource
  
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return tribeObjects.count
  }
  
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
    if collectionView.bounds.size.width > 320 {
      // iPhone6
      return CGSizeMake(100.0, 136.0)
    } else {
      return CGSizeMake(84.0, 120.0)
    }
  }
  
  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PFCollectionViewCell
    
    let tribeObj = tribeObjects[indexPath.row] as! PFObject
    
    if let nameLabel = cell.viewWithTag(235) as? UILabel {
      nameLabel.text = tribeObj.objectForKey(kVYBTribeNameKey) as? String
    }
    
    if let userCountLabel = cell.viewWithTag(358) as? UILabel {
//      userCountLabel.text = 
    }
    
    if let tribeImageView = cell.viewWithTag(123) as? PFImageView {
      if let file = tribeObj[kVYBTribePhotoKey] as? PFFile {
        tribeImageView.file = file
        tribeImageView.loadInBackground({ (image: UIImage!, error: NSError!) -> Void in
          if image != nil {
            let maskImage = UIImage(named: "SquareMask")
            tribeImageView.image = VYBUtility.maskImage(image, withMask: maskImage)
          }
        })
      }
    }
    
    return cell
  }
  
}
