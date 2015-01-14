//
//  PostTableViewCell.swift
//  VybeTen
//
//  Created by Jinsu Kim on 1/13/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit
@IBDesignable
class PostTableViewCell: UITableViewCell {
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
        
    self.buildHiearchy()
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    self.buildHiearchy()
  }
  
  override func prepareForInterfaceBuilder() {
    self.buildHiearchy()
  }
  
  func buildHiearchy() {
//    if let view = NSBundle.mainBundle().loadNibNamed("PostTableViewCell", owner: self, options: nil).first as? UIView {
////      self.contentView.addSubview(view)
//    }
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  override func setSelected(selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
}
