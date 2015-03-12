//
//  FunRecordButton.swift
//  Vybe
//
//  Created by Jinsu Kim on 3/11/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

@IBDesignable

class FunRecordButton: UIView {
  internal struct Constants {
    static let initRadius: CGFloat = 48.0
    static let initBorderWidth: CGFloat = 4.0
    static let foregroundRadius: CGFloat = 48.0
  }
  
  var _backgroundLayer: CAShapeLayer!
  var _borderProgressLayer: VYBPizzaLayer!
  var _foregroundLayer: CAShapeLayer!
    
  @IBInspectable var bgFillColor: UIColor = UIColor(white: 0.5, alpha: 0.5) {
    didSet { setNeedsDisplay() }
  }
  
  @IBInspectable var fgFillColor: UIColor = UIColor.orangeColor() {
    didSet { setNeedsDisplay() }
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    self.setUpLayers()
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    self.setUpLayers()
  }
  
  private func setUpLayers() {
    self.backgroundColor = UIColor.clearColor()
    self.opaque = false
    
    _backgroundLayer = CAShapeLayer()
    _borderProgressLayer = VYBPizzaLayer()
    _foregroundLayer = CAShapeLayer()
    
    self.layer.addSublayer(_backgroundLayer)
    self.layer.addSublayer(_borderProgressLayer)
    self.layer.addSublayer(_foregroundLayer)
  }
  
  override func layoutSubviews() {
    _backgroundLayer.frame = self.bounds
    _backgroundLayer.path = self.circleWithRadius(Constants.initRadius)
    _backgroundLayer.fillColor = self.bgFillColor.CGColor
    _backgroundLayer.strokeColor = UIColor.whiteColor().CGColor
    _backgroundLayer.lineWidth = CGFloat(Constants.initBorderWidth)
    
    _borderProgressLayer.frame = self.bounds
    _borderProgressLayer.startAngle = CGFloat(-M_PI_2)
    _borderProgressLayer.endAngle = _borderProgressLayer.startAngle
    _borderProgressLayer.strokeColor = UIColor.redColor()
    _borderProgressLayer.strokeWidth = CGFloat(Constants.initBorderWidth)
    _borderProgressLayer.fillColor = UIColor.clearColor()
    _borderProgressLayer.rasterizationScale = UIScreen.mainScreen().scale
    _borderProgressLayer.shouldRasterize = true
    
    _foregroundLayer.frame = self.bounds
    _foregroundLayer.path = self.circleWithRadius(Constants.foregroundRadius)
    _foregroundLayer.fillColor = self.fgFillColor.CGColor
  }
  
  func circleWithRadius(radius: CGFloat) -> CGPathRef! {
    let circleRect = CGRectInset(self.bounds, self.bounds.width/2.0 - radius, self.bounds.height/2.0 - radius)
    let circlePath = UIBezierPath(ovalInRect:circleRect)
    return circlePath.CGPath
  }
  
  func didStartRecording() {
    let bigRadius: CGFloat = 60.0
    let thickBorderWidth: CGFloat = 7.0
    
    // Border Progress Animation
    CATransaction.begin()
    let duration: NSNumber = 15.0
    CATransaction.setValue(duration, forKey: kCATransactionAnimationDuration)
    _borderProgressLayer.endAngle = CGFloat(3.0 * M_PI_2)
    
    // GetBigger Animation
//    CATransaction.begin()
//    CATransaction.setValue(2.0, forKey: kCATransactionAnimationDuration)
//    let getBigger = CABasicAnimation(keyPath: "getBigger")
//    getBigger.fillMode = kCAFillModeForwards
//    getBigger.removedOnCompletion = false
//    getBigger.toValue = self.circleWithRadius(bigRadius)
//    _backgroundLayer.addAnimation(getBigger, forKey: "getBigger")
//    _backgroundLayer.lineWidth = thickBorderWidth
//    
//    _borderProgressLayer.strokeWidth = thickBorderWidth
//    _borderProgressLayer.radius = bigRadius
//    CATransaction.commit()
    
    CATransaction.commit()
    
  }
  
  func didStopRecording() {
    
  }
  
  
}
