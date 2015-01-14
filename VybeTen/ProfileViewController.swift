//
//  ProfileViewController.swift
//  VybeTen
//
//  Created by Jinsu Kim on 1/12/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class ProfileViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  @IBOutlet weak var profilePicView: PFImageView!
  @IBOutlet weak var profileButton: UIButton!
  @IBOutlet weak var username: UILabel!
  @IBOutlet weak var activitySummary: UILabel!
  
  @IBOutlet weak var activityCountLabel: UILabel!
  @IBOutlet weak var activityButton: UIButton!
  
  @IBAction func activityButtonPressed(sender: AnyObject) {
    
  }
  
  @IBAction func profileButtonPressed(sender: AnyObject) {
    let comparisonResult: NSComparisonResult = UIDevice.currentDevice().systemVersion.compare("8.0.0", options: NSStringCompareOptions.NumericSearch)
    if comparisonResult == .OrderedSame || comparisonResult == .OrderedDescending {
      // ios 8
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
  
  func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
    let imgData = UIImagePNGRepresentation(image)
    let imgFile = PFFile(data: imgData, contentType: "image/png")
    PFUser.currentUser().setObject(imgFile, forKey: kVYBUserProfilePicMediumKey)
    PFUser.currentUser().saveInBackgroundWithBlock { (success: Bool, error: NSError!) -> Void in
      if success {
        self.showPopUpWindow(message: "Profile picture changed. :)")
        if let maskImage = UIImage(named: "Profile_Mask") {
          self.profilePicView.image = VYBUtility.maskImage(image, withMask: maskImage)
        }
      } else {
        self.showPopUpWindow(message: "Network unavailable. :(")
      }
    }

    //VYBUtility.uploadProfileImage()
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  // TODO: - This method should available across all viewcontrollers. Make a generic viewcontroller.
  func showPopUpWindow(message msg: String) {
    
  }
  
  func imagePickerControllerDidCancel(picker: UIImagePickerController) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let currUser = PFUser.currentUser()
    
    if let profileThumbnail = currUser[kVYBUserProfilePicMediumKey] as? PFFile {
      profilePicView.file = profileThumbnail
      profilePicView.loadInBackground({ (image: UIImage!, error: NSError!) -> Void in
        if image != nil {
          if let maskImage = UIImage(named: "Profile_Mask") {
            self.profilePicView.image = VYBUtility.maskImage(maskImage, withMask: maskImage)
          }
        } else {
          // TODO: - Placeholder image for profile pic
        }
      })
    }
    
    if let name = currUser[kVYBUserUsernameKey] as? String {
      username.text = name
    }
    
    // Do any additional setup after loading the view.
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return false
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
