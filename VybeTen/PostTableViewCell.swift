//
//  PostTableViewCell.swift
//  VybeTen
//
//  Created by Jinsu Kim on 1/13/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit
class PostTableViewCell: UITableViewCell {
  
  @IBOutlet weak var userProfileImageView: PFImageView!
  @IBOutlet weak var usernameLabel: UILabel!
  @IBOutlet weak var locationLabel: UILabel!
  @IBOutlet weak var hashtagLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var vybeThumbnailImageView: PFImageView!
  @IBOutlet weak var countLabel: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    if let content = NSBundle.mainBundle().loadNibNamed("PostTableViewCell", owner: self, options: nil).last as? UIView {
      self.contentView.addSubview(content)
    }
  }
  
  override func setSelected(selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
  func setVybe(vybeObj: PFObject) {
    if let spotName = vybeObj[kVYBVybeZoneNameKey] as? String {
      locationLabel.text = spotName
    }
    
    if let hashtags = vybeObj[kVYBVybeHashtagsKey] as? NSArray {
      var tagString = "#"
      for obj in hashtags {
        if let last = hashtags.lastObject as? String {
          if let tag = obj as? String {
            if tag != last {
              tagString += "\(tag) #"
            }
          }
        }
      }
      hashtagLabel.text = tagString
    } else {
      hashtagLabel.text = ""
    }
    
    if let vybeThumbnailFile = vybeObj[kVYBVybeThumbnailKey] as? PFFile {
      vybeThumbnailImageView.file = vybeThumbnailFile
      vybeThumbnailImageView.loadInBackground({ (image: UIImage!, error: NSError!) -> Void in
        if image != nil {
          let maskImage = UIImage(named: "Profile_Mask")
          self.vybeThumbnailImageView.image = VYBUtility.maskImage(image, withMask: maskImage)
        }
      })
    }
  }
  
  func setFromUser(user: PFObject) {
    // TODO: - Use ProfilePicSmall instead
    if let profilePicFile = user[kVYBUserProfilePicMediumKey] as? PFFile {
      userProfileImageView.file = profilePicFile
      userProfileImageView.loadInBackground({ (image: UIImage!, error: NSError!) -> Void in
        if error != nil {
          if image != nil {
            let maskImage = UIImage(named: "Profile_Mask")
            self.userProfileImageView.image = VYBUtility.maskImage(image, withMask: maskImage)
          }
        } else {
          // TODO: - Put placeholder for small profile pic
          
        }
      })
    }
    
    let username = user[kVYBUserUsernameKey] as String
    usernameLabel.text = username
  }
  
}
