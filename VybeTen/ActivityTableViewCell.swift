//
//  ActivityTableViewCell.swift
//  VybeTen
//
//  Created by Jinsu Kim on 1/15/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class ActivityTableViewCell: PFTableViewCell {
  @IBOutlet weak var userProfileImageView: PFImageView!
  @IBOutlet weak var usernameLabel: UILabel!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var hashtagLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var vybeThumbnailImageView: PFImageView!
  
  func setVybe(vybeObj: PFObject) {
    if let hashtags = vybeObj[kVYBVybeHashtagsKey] as? NSArray {
      if hashtags.count > 0 {
        var tagString = "#"
        for obj in hashtags {
          if let last = hashtags.lastObject as? String {
            if let tag = obj as? String {
              if tag != last {
                tagString += "\(tag) #"
              } else {
                tagString += tag
              }
            }
          }
        }
        hashtagLabel.text = tagString
      }
    }
    
    if let vybeThumbnailFile = vybeObj[kVYBVybeThumbnailKey] as? PFFile {
      vybeThumbnailImageView.file = vybeThumbnailFile
      vybeThumbnailImageView.loadInBackground({ (image: UIImage!, error: NSError!) -> Void in
        if error == nil {
          if image != nil {
            var maskImage: UIImage?
            if image.size.height > image.size.width {
              maskImage = UIImage(named: "thumbnail_mask_portrait")
            } else {
              maskImage = UIImage(named: "thumbnail_mask_landscape")
            }
            self.vybeThumbnailImageView.image = VYBUtility.maskImage(image, withMask: maskImage)
          }
        } else {
          self.vybeThumbnailImageView.image = UIImage(named: "Placeholder")
        }
      })
    } else {
      self.vybeThumbnailImageView.image = UIImage(named: "Placeholder")
    }
  }
  
  func setUser(user: PFObject) {
    // TODO: - Use ProfilePicSmall instead
    if let profilePicFile = user[kVYBUserProfilePicMediumKey] as? PFFile {
      userProfileImageView.file = profilePicFile
      userProfileImageView.loadInBackground({ (image: UIImage!, error: NSError!) -> Void in
        if error == nil {
          if image != nil {
            let maskImage = UIImage(named: "Profile_Mask")
            self.userProfileImageView.image = VYBUtility.maskImage(image, withMask: maskImage)
          }
        } else {
          // TODO: - Put placeholder for small profile pic
          self.userProfileImageView.image = UIImage(named: "PersonAvartar")
        }
      })
    } else {
      self.userProfileImageView.image = UIImage(named: "PersonAvartar")
    }
    
    if let username = user[kVYBUserUsernameKey] as? String {
      usernameLabel.text = username
    }
  }
  
}
