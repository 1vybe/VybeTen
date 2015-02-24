//
//  TribeDetailsViewController.swift
//  Vybe
//
//  Created by Jinsu Kim on 2/15/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class TribeDetailsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
  var tribeObj: AnyObject?
  var members: [AnyObject]?
  
  @IBOutlet weak var tribePhoto: PFImageView!
  @IBOutlet weak var nameText: UITextField!
  @IBOutlet weak var tableView: UITableView!
  
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
    
    tribeObj?.setObject(imgFile, forKey:kVYBTribePhotoKey)
    
    let maskImage = UIImage(named: "SquareMask")
    tribePhoto.image = VYBUtility.maskImage(image, withMask: maskImage)
  }
  
  func saveTribe(closure: (() -> ())?) {
    if let tribe = tribeObj as? PFObject where self.validateTribeName(nameText.text) {
      tribe.setObject(nameText.text, forKey: kVYBTribeNameKey)
      
      if let newFile = tribe[kVYBTribePhotoKey] as? PFFile {
          newFile.saveInBackgroundWithBlock({ (success: Bool, error: NSError!) -> Void in
            if success {
              tribe.saveInBackgroundWithBlock({ (success: Bool, error: NSError!) -> Void in
                closure?()
                MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
              })
            } else {
              MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
            }
          })
      } else {
        tribe.saveEventually({ (success: Bool, error: NSError!) -> Void in
          closure?()
          MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
        })
      }
    } else {
      let alertVC = UIAlertController(title: "Invalid tribe name", message: "A name must be between 2 - 20 in length and consist of alphabets and numbers only.", preferredStyle: UIAlertControllerStyle.Alert)
      alertVC.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
      self.presentViewController(alertVC, animated: true, completion: nil)
    }
  }
  
  private func validateTribeName(text: String!) -> Bool {
    if count(text) < 3 || count(text) > 20 {
      return false
    }
    
    let name = text as NSString
    
    return name.isValidTribeName()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
        
    var textAttributes = [NSObject : AnyObject]()
    if let font = UIFont(name: "HelveticaNeue-Medium", size: 18.0) {
      let textColor = UIColor(red: 74.0/255.0, green: 74.0/255.0, blue: 74.0/255.0, alpha: 1.0)
      textAttributes[NSFontAttributeName] = font
      textAttributes[NSForegroundColorAttributeName] = textColor
      self.navigationController?.navigationBar.titleTextAttributes = textAttributes
    }
    
    textAttributes = [:]
    if let font = UIFont(name: "Helvetica Neue", size: 16.0) {
      let textColor = UIColor(red: 74.0/255.0, green: 144.0/255.0, blue: 226.0/255.0, alpha: 1.0)
      textAttributes[NSFontAttributeName] = font
      textAttributes[NSForegroundColorAttributeName] = textColor
      self.navigationItem.leftBarButtonItem?.setTitleTextAttributes(textAttributes, forState: .Normal)
    }
    
    textAttributes = [:]
    if let font = UIFont(name: "HelveticaNeue-Bold", size: 16.0) {
      let textColor = UIColor(red: 74.0/255.0, green: 144.0/255.0, blue: 226.0/255.0, alpha: 1.0)
      textAttributes[NSFontAttributeName] = font
      textAttributes[NSForegroundColorAttributeName] = textColor
      self.navigationItem.rightBarButtonItem?.setTitleTextAttributes(textAttributes, forState: .Normal)
    }
    
    let attributedStr = NSAttributedString(string: "Name", attributes: [NSForegroundColorAttributeName: UIColor(red: 155/255.0, green: 155/255.0, blue: 155/255.0, alpha: 1.0)])
    nameText.attributedPlaceholder = attributedStr
    nameText.delegate = self
    
    let tapGesture = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
    self.view.addGestureRecognizer(tapGesture)
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    tribeObj?.fetchFromLocalDatastoreInBackgroundWithBlock({ (obj: PFObject!, error: NSError!) -> Void in
      if let relation = obj.relationForKey(kVYBTribeMembersKey),
        let username = PFUser.currentUser().objectForKey(kVYBUserUsernameKey) as? String {
          let query = relation.query()
          query.fromLocalDatastore()
          query.whereKey(kVYBUserUsernameKey, notEqualTo: username)
          query.findObjectsInBackgroundWithBlock({ (result: [AnyObject]!, error: NSError!) -> Void in
            if error == nil {
              self.members = result
              self.tableView.reloadData()
            }
          })
          
      }
    })
  }
  
  // MARK: - UITableViewDelegate
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("TribeMemberTableCell") as! UITableViewCell
    
    if let member = members?[indexPath.row] as? PFObject,
      let username = member[kVYBUserUsernameKey] as? String,
      let usernameLabel = cell.viewWithTag(123) as? UILabel {
        usernameLabel.text = username
    }
    
    return cell
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let count: Int
    
    if members != nil {
      count = members!.count
    } else {
      count = 0
    }
    
    return count
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if let addMemberVC = segue.destinationViewController as? AddMemberViewController
      where segue.identifier == "ShowAddMemberSegue" {
        addMemberVC.currTribe = tribeObj
    }
  }
  
  func dismissKeyboard() {
    self.view.endEditing(true)
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }  
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

}
