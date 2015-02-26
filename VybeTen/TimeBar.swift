//
//  TimeBar.swift
//  Vybe
//
//  Created by Jinsu Kim on 2/24/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

@IBDesignable

class TimeBar: UIView {
  internal struct Constants {
    static let zeroProgress = 0.0
  }
  
  @IBInspectable var progress: Double = Constants.zeroProgress {
    didSet { setNeedsDisplay() }
  }
  
  @IBInspectable var barColor: UIColor = UIColor(red: 254/255.0, green: 68/255.0, blue: 0, alpha: 1.0) {
    didSet { setNeedsDisplay() }
  }
  
  @IBInspectable var bgColor: UIColor = UIColor(red: 255/255.0, green: 102/255.0, blue: 53/255.0, alpha: 0.26) {
    didSet { setNeedsDisplay() }
  }
  
  override func drawRect(rect: CGRect) {
    super.drawRect(rect)
    
    let context = UIGraphicsGetCurrentContext()
    CGContextClearRect(context, rect)
    
    let linearPath = UIBezierPath(rect: rect)
    
  }
  
}
