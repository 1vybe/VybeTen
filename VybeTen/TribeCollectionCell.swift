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
  @IBOutlet weak var playButton: UIButton!
  @IBOutlet weak var detailButton: UIButton!
  
  weak var tribeObject: Tribe?
  weak var delegate: UIViewController?
  
  var doubleTapGesture: UIGestureRecognizer!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    let doubleTap = UITapGestureRecognizer(target: self, action: "doubleTapDetected")
    doubleTap.numberOfTapsRequired = 2
    doubleTap.delegate = self
    self.doubleTapGesture = doubleTap
    
    self.addGestureRecognizer(doubleTap)
    
    let tapToPlay = UITapGestureRecognizer(target: self, action: "playTribe")
    tapToPlay.requireGestureRecognizerToFail(doubleTap)
    self.playButton.addGestureRecognizer(tapToPlay)
    
    let tapToShowDetails = UITapGestureRecognizer(target: self, action: "showTribeDetail")
    tapToShowDetails.requireGestureRecognizerToFail(doubleTap)
    self.detailButton.addGestureRecognizer(tapToShowDetails)
  }
  
  func doubleTapDetected() {
    MyVybeStore.sharedInstance.currTribe = tribeObject?.tribeObject as? PFObject
    
    if let tribesVC = delegate as? TribesViewController {
      tribesVC.moveToCapture()
    }
  }
  
  func showTribeDetail() {
    if let tribesVC = delegate as? TribesViewController {
      if let tribe = tribeObject?.tribeObject as? PFObject {
        tribesVC.didSelectTribeToShowInfo(tribe)
      }
    }
  }
  
  func playTribe() {
    if let tribesVC = delegate as? TribesViewController {
      tribesVC.didSelectTribeToPlay(tribeObject)
    }
  }

}
