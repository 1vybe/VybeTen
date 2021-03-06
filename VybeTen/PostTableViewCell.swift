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
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var hashtagLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var vybeThumbnailImageView: PFImageView!
  @IBOutlet weak var countLabel: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()

    if let customView = NSBundle.mainBundle().loadNibNamed("PostTableViewCell", owner: self, options: nil).first as? UIView {
      customView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
      customView.setTranslatesAutoresizingMaskIntoConstraints(false)
      self.contentView.addSubview(customView)
      
      self.contentView.addConstraint(NSLayoutConstraint(item: customView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self.contentView, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0))
      self.contentView.addConstraint(NSLayoutConstraint(item: customView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: self.contentView, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0))
      self.contentView.addConstraint(NSLayoutConstraint(item: customView, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: self.contentView, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0))
      self.contentView.addConstraint(NSLayoutConstraint(item: customView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self.contentView, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0))
    }
  }
  
  override func setSelected(selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
  func setVybe(vybeObj: PFObject) {
    if let hashtags = vybeObj[kVYBVybeHashtagsKey] as? NSArray {
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
    } else {
      hashtagLabel.text = ""
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
          self.userProfileImageView.image = UIImage(named: "PersonAvartar")
        }
      })
    }
    
    if let username = user[kVYBUserUsernameKey] as? String {
      usernameLabel.text = username
    }
  }
}
