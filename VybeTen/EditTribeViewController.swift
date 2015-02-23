//
//  EditTribeViewController.swift
//  Vybe
//
//  Created by Jinsu Kim on 2/22/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class EditTribeViewController: TribeDetailsViewController {
  @IBOutlet weak var photoAerial: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let photoFile = tribeObj?[kVYBTribePhotoKey] as? PFFile {
      tribePhoto.file = photoFile
      tribePhoto.loadInBackground({ (image: UIImage!, error: NSError!) -> Void in
        if image != nil {
          let maskImage = UIImage(named: "SquareMask")
          self.tribePhoto.image = VYBUtility.maskImage(image, withMask: maskImage)
        }
      })
    }
    
    if let tribeName = tribeObj?[kVYBTribeNameKey] as? String {
      nameText.text = tribeName
    }
    
    if let coordinator = tribeObj?[kVYBTribeCoordinatorKey] as? PFObject {
      if coordinator.objectId != PFUser.currentUser().objectId {
        // Disable editing photo/name
        photoAerial.enabled = false
        nameText.enabled = false
        
//        self.navigationItem. width = 0.01
      }
    }
  }  
  
  @IBAction func doneButtonPressed(sender: AnyObject) {
    super.saveTribe({ () -> () in
      self.navigationController?.popViewControllerAnimated(true)
    })
  }
  
  @IBAction func backButtonPressed(sender: AnyObject) {
    self.navigationController?.popViewControllerAnimated(true)
  }
  
}
