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
  @IBOutlet weak var userCount: UILabel!
  
  weak var tribeObject: Tribe?
  weak var delegate: UIViewController?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    let doubleTap = UITapGestureRecognizer(target: self, action: "doubleTapDetected")
    doubleTap.numberOfTapsRequired = 2
    doubleTap.delegate = self
    self.addGestureRecognizer(doubleTap)
  }
  
  func doubleTapDetected() {
    MyVybeStore.sharedInstance.currTribe = tribeObject?.tribeObject as? PFObject
    
    if let tribesVC = delegate as? TribesViewController {
      tribesVC.moveToCapture()
    }
  }
  
//  @IBAction func tribeNamePressed(sender: AnyObject) {
//    if let tribesVC = delegate as? TribesViewController,
//      let tribe = tribeObject {
//      tribesVC.didSelectTribeToShowInfo(tribe)
//    }
//  }
  
  @IBAction func tribePhotoPressed(sender: AnyObject) {
    if let tribesVC = delegate as? TribesViewController,
      let tribe = tribeObject {
        tribesVC.didSelectTribeToPlay(tribe)
    }
  }

}
