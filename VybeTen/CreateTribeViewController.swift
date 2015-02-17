//
//  CreateTribeViewController.swift
//  Vybe
//
//  Created by Jinsu Kim on 2/15/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

protocol CreateTribeDelegate {
  func didCreateTribe(tribe: AnyObject)
}

class CreateTribeViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  var newTribe: PFObject?
  var delegate: CreateTribeDelegate?
  
  @IBOutlet weak var tribePhoto: PFImageView!
  @IBOutlet weak var nameText: UITextField!
  @IBOutlet weak var descriptionText: UITextView!
  
  @IBAction func tribePhotoSelected(sender: AnyObject) {
    // TODO: - Make the following version check mechanism GLOBAL
    let comparisonResult: NSComparisonResult = UIDevice.currentDevice().systemVersion.compare("8.0.0", options: NSStringCompareOptions.NumericSearch)
    if comparisonResult == .OrderedSame || comparisonResult == .OrderedDescending {
      // ios 8
      var alertController = UIAlertController(title: "Tribe Photo", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
      let albumAction = UIAlertAction(title: "Choose from Album", style: .Default, handler: { (action: UIAlertAction!) -> Void in
        if UIImagePickerController.isSourceTypeAvailable(.SavedPhotosAlbum) {
          var imagePicker = UIImagePickerController()
          imagePicker.sourceType = .SavedPhotosAlbum
          imagePicker.allowsEditing = true
          imagePicker.delegate = self
          
          self.presentViewController(imagePicker, animated: true, completion: nil)
        }
      })
      let cameraAction = UIAlertAction(title: "Take a photo", style: .Default, handler: { (action: UIAlertAction!) -> Void in
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
          var imagePicker = UIImagePickerController()
          imagePicker.sourceType = .Camera
          imagePicker.allowsEditing = true
          imagePicker.delegate = self
          
          self.presentViewController(imagePicker, animated: true, completion: nil)
        }
      })
      let cancelAction = UIAlertAction(title: "Go Back", style: .Cancel, handler: nil)
      alertController.addAction(cancelAction)
      
      alertController.addAction(albumAction)
      alertController.addAction(cameraAction)
      self.presentViewController(alertController, animated: true, completion: nil)
    } else {
      // ios 7 and below
      var alertController = UIAlertController(title: "Profile Picture", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
      let albumAction = UIAlertAction(title: "Choose from Album", style: .Default, handler: { (action: UIAlertAction!) -> Void in
        if UIImagePickerController.isSourceTypeAvailable(.SavedPhotosAlbum) {
          var imagePicker = UIImagePickerController()
          imagePicker.sourceType = .SavedPhotosAlbum
          imagePicker.allowsEditing = true
          imagePicker.delegate = self
          
          self.presentViewController(imagePicker, animated: true, completion: nil)
        }
      })
      let cameraAction = UIAlertAction(title: "Take a photo", style: .Default, handler: { (action: UIAlertAction!) -> Void in
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
          var imagePicker = UIImagePickerController()
          imagePicker.sourceType = .Camera
          imagePicker.allowsEditing = true
          imagePicker.delegate = self
          
          self.presentViewController(imagePicker, animated: true, completion: nil)
        }
      })
      let cancelAction = UIAlertAction(title: "Go Back", style: .Cancel, handler: nil)
      alertController.addAction(cancelAction)
      
      alertController.addAction(albumAction)
      alertController.addAction(cameraAction)
      self.presentViewController(alertController, animated: true, completion: nil)
    }
  }
  
  func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
    //VYBUtility.uploadProfileImage()
    self.dismissViewControllerAnimated(true, completion: nil)
    
    let imgData = UIImagePNGRepresentation(image)
    let imgFile = PFFile(data: imgData, contentType: "image/png")
    
    newTribe?.setObject(imgFile, forKey:kVYBTribePhotoKey)
    
    let maskImage = UIImage(named: "SquareMask")
    tribePhoto.image = VYBUtility.maskImage(image, withMask: maskImage)
  }
  
  @IBAction func cancelButtonPressed(sender: AnyObject) {
    self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
  }
  
  @IBAction func nextButtonPressed(sender: AnyObject) {
    if self.validateTribeName(nameText.text) {
      newTribe?.setObject(nameText.text, forKey: kVYBTribeNameKey)
      newTribe?.setObject(descriptionText.text, forKey: kVYBTribeDescriptionKey)
      
      MBProgressHUD.showHUDAddedTo(self.view, animated: true)
      newTribe?.saveInBackgroundWithBlock({ (success: Bool, error: NSError!) -> Void in
        if success {
          let query = PFQuery(className: kVYBTribeClassKey)
          query.whereKey(kVYBTribeNameKey, equalTo: self.nameText.text)
          query.whereKey(kVYBTribeCoordinatorKey, equalTo: PFUser.currentUser())
          query.getFirstObjectInBackgroundWithBlock({ (result: PFObject!, error: NSError!) -> Void in
            if result != nil {
              result.pinInBackgroundWithBlock({ (success: Bool, error: NSError!) -> Void in
                if success {
                  self.delegate?.didCreateTribe(result)
                }
              })
            } else {
              let alertVC = UIAlertController(title: "Network Unavailable", message: "Could not create your tribe at the moment.", preferredStyle: UIAlertControllerStyle.Alert)
              alertVC.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
              self.presentViewController(alertVC, animated: true, completion: nil)
            }
            MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
          })
        } else {
          MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
          
          let alertVC = UIAlertController(title: "Network Unavailable", message: "Cannot create your tribe at the moment.", preferredStyle: UIAlertControllerStyle.Alert)
          alertVC.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
          self.presentViewController(alertVC, animated: true, completion: nil)
        }
      })
    } else {
      let alertVC = UIAlertController(title: "Invalid tribe name", message: "A name must be between 2 - 20 in length and consist of alphabets and numbers only.", preferredStyle: UIAlertControllerStyle.Alert)
      alertVC.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
      self.presentViewController(alertVC, animated: true, completion: nil)
    }
  }
  
  private func validateTribeName(text: String!) -> Bool {
    if count(text) < 3 {
      return false
    }
    
    let name = text as NSString
    
    return name.isValidTribeName()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let tribeObj = PFObject(className: kVYBTribeClassKey)
    tribeObj[kVYBTribeCoordinatorKey] = PFUser.currentUser()
    
    let ACL = PFACL(user: PFUser.currentUser())
    ACL.setPublicReadAccess(true)
    tribeObj.ACL = ACL
    
    newTribe = tribeObj
    // Do any additional setup after loading the view.
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  /*
  // MARK: - Navigation
  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
  // Get the new view controller using segue.destinationViewController.
  // Pass the selected object to the new view controller.
  }
  */
  
}
