//
//  PaddedLabel.swift
//  Vybe
//
//  Created by Jinsu Kim on 2/24/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class PaddedLabel: UILabel {
  override func drawTextInRect(rect: CGRect) {
    let insets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    
    return super.drawTextInRect(UIEdgeInsetsInsetRect(rect, insets))
  }
}
