//
//  PizzaProgressView.swift
//
//  Created by jinsuk on 11/20/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit
import QuartzCore

@IBDesignable

class PizzaProgressView: UIView {
  internal struct Constants {
    static let circleDegress = 360.0
    static let minimumValue = 0.000001
    static let maximumValue = 0.999999
    static let ninetyDegrees = 90.0
    static let twoSeventyDegrees = 270.0
  }
  
  @IBInspectable var progress: Double = Constants.minimumValue {
    didSet { setNeedsDisplay() }
  }
  
  @IBInspectable var clockwise: Bool = true {
    didSet { setNeedsDisplay() }
  }
  
  @IBInspectable var pizzaBackgroundColor:UIColor = UIColor.clearColor() {
    didSet { setNeedsDisplay() }
  }
  
  @IBInspectable var pizzaSliceColor:UIColor = UIColor.clearColor() {
    didSet { setNeedsDisplay() }
  }
  
  
  required override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override func drawRect(rect: CGRect) {
    super.drawRect(rect)
    
    let context = UIGraphicsGetCurrentContext()
    CGContextClearRect(context, rect)
    
    let circlePath = UIBezierPath(ovalInRect: rect)
    UIColor.grayColor().setFill()
    circlePath.fill()
    
    
    
  }
  
  
}