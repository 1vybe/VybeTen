//
//  SimpleTextField.swift
//  VybeTen
//
//  Created by Jinsu Kim on 1/6/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class SimpleTextField: UITextField {
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    self.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
    self.returnKeyType = .Done
    
    var simpleAttributes = [NSObject : AnyObject]()
    if let font = UIFont(name: "Avenir Next", size: 17.0) {
      let textColor = UIColor(white: 1.0, alpha: 1.0)
      simpleAttributes[NSFontAttributeName] = font
      simpleAttributes[NSForegroundColorAttributeName] = textColor
    }
    var attributedText = NSAttributedString(string: "#", attributes: simpleAttributes)
    self.attributedText = attributedText
    
    self.leftViewMode = .Always
    self.leftView = UIView(frame: CGRectMake(0.0, 0.0, 10.0, 30.0))
    self.leftViewRectForBounds(CGRectMake(0.0, 0.0, 10.0, 30.0))
  }

}
