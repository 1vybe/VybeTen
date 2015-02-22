//
//  TribeCollectionCell.swift
//  Vybe
//
//  Created by Jinsu Kim on 2/20/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class TribeCollectionCell: UICollectionViewCell, UIGestureRecognizerDelegate {
  @IBOutlet weak var photoImageView: PFImageView!
  @IBOutlet weak var nameLabel: UILabel!
  
  weak var tribeObject: AnyObject?
  weak var delegate: UIViewController?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    let doubleTap = UITapGestureRecognizer(target: self, action: "doubleTapDetected")
    doubleTap.numberOfTapsRequired = 2
    doubleTap.delegate = self
    self.addGestureRecognizer(doubleTap)
  }
  
  func doubleTapDetected() {
    MyVybeStore.sharedInstance.currTribe = tribeObject as? PFObject
    
    if let tribesVC = delegate as? TribesViewController {
      tribesVC.moveToCapture()
    }
  }

  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}
