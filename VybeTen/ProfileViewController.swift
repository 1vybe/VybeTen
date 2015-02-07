//
//  ProfileViewController.swift
//  VybeTen
//
//  Created by Jinsu Kim on 1/12/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

protocol ProfileSummaryViewDelegate {
  func showListView()
  func showCollectionView()
}

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ProfileSummaryViewDelegate {  
  var naviContainer: UINavigationController?

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "ProfileEmbedSegue" {
      naviContainer = segue.destinationViewController as? UINavigationController
      if let listVC = naviContainer?.topViewController as? ProfileListViewController {
        listVC.mainProfileViewController = self
      }
    }
  }
  
  // MARK: - ProfileSummaryViewDelegate
  func showListView() {
    self.performSegueWithIdentifier("ListViewSegue", sender: nil)
  }
  
  func showCollectionView() {
    self.performSegueWithIdentifier("CollectionViewSegue", sender: nil)
  }
  
  // MARK: - Update user profile picture
  
  @IBAction func profileButtonPressed(sender: AnyObject) {
    // TODO: - Make the following version check mechanism GLOBAL
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
    //VYBUtility.uploadProfileImage()
    self.dismissViewControllerAnimated(true, completion: nil)
    
    let imgData = UIImagePNGRepresentation(image)
    let imgFile = PFFile(data: imgData, contentType: "image/png")
    PFUser.currentUser().setObject(imgFile, forKey: kVYBUserProfilePicMediumKey)
    PFUser.currentUser().saveInBackgroundWithBlock { (success: Bool, error: NSError!) -> Void in
      if success {
        self.showPopUpWindow(message: "Profile picture changed. :)")
        if let maskImage = UIImage(named: "Profile_Mask") {
//          self.profilePicView?.image = VYBUtility.maskImage(image, withMask: maskImage)
        }
      } else {
        self.showPopUpWindow(message: "Network unavailable. :(")
      }
    }
  }
  
  // TODO: - This method should available across all viewcontrollers. Make a generic viewcontroller.
  func showPopUpWindow(message msg: String) {
    let comparisonResult: NSComparisonResult = UIDevice.currentDevice().systemVersion.compare("8.0.0", options: NSStringCompareOptions.NumericSearch)
    if comparisonResult == .OrderedSame || comparisonResult == .OrderedDescending { // iOS 8
      let popUp = UIAlertController(title: "", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
      let okAction = UIAlertAction(title: "OK", style: .Default, handler: { (action: UIAlertAction!) -> Void in
        self.dismissViewControllerAnimated(true, completion: nil)
      })
      popUp.addAction(okAction)
      self.presentViewController(popUp, animated: true, completion: nil)
    } else { // iOS 7 and below
      
    }
  }
  
  func imagePickerControllerDidCancel(picker: UIImagePickerController) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }

}
