//
//  CircleProgressView.swift
//
//
//  Created by Eric Rolf on 8/11/14.
//  Copyright (c) 2014 Eric Rolf, Cardinal Solutions Group. All rights reserved.
//

import UIKit
import QuartzCore

@IBDesignable

class CircleProgressView: UIView {
  
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
  
  @IBInspectable var trackWidth: CGFloat = 10 {
    didSet { setNeedsDisplay() }
  }
  
  @IBInspectable var trackImage: UIImage? {
    didSet { setNeedsDisplay() }
  }
  
  @IBInspectable var trackBackgroundColor: UIColor = UIColor.grayColor() {
    didSet { setNeedsDisplay() }
  }
  
  @IBInspectable var trackFillColor: UIColor = UIColor.blueColor() {
    didSet { setNeedsDisplay() }
  }
  
  @IBInspectable var trackBorderColor:UIColor = UIColor.clearColor() {
    didSet { setNeedsDisplay() }
  }
  
  @IBInspectable var trackBorderWidth: CGFloat = 0 {
    didSet { setNeedsDisplay() }
  }
  
  @IBInspectable var centerFillColor: UIColor = UIColor.whiteColor() {
    didSet { setNeedsDisplay() }
  }
  
  override func drawRect(rect: CGRect) {
    
    super.drawRect(rect)
    
    let innerRect = CGRectInset(rect, trackBorderWidth, trackBorderWidth)
    
    progress = (progress/1.0) == 0.0 ? Constants.minimumValue : progress
    progress = (progress/1.0) == 1.0 ? Constants.maximumValue : progress
    progress = clockwise ? (-Constants.twoSeventyDegrees + ((1.0 - progress) * Constants.circleDegress)) : (Constants.ninetyDegrees - ((1.0 - progress) * Constants.circleDegress))
    
    let context = UIGraphicsGetCurrentContext()
    
    // background Drawing
    trackBackgroundColor.setFill()
    let circlePath = UIBezierPath(ovalInRect: CGRectMake(innerRect.minX, innerRect.minY, CGRectGetWidth(innerRect), CGRectGetHeight(innerRect)))
    circlePath.fill();
    
    if trackBorderWidth > 0 {
      circlePath.lineWidth = trackBorderWidth
      trackBorderColor.setStroke()
      circlePath.stroke()
    }
    
    // progress Drawing
    let progressPath = UIBezierPath()
    let progressRect: CGRect = CGRectMake(innerRect.minX, innerRect.minY, CGRectGetWidth(innerRect), CGRectGetHeight(innerRect))
    let center = CGPointMake(progressRect.midX, progressRect.midY)
    let radius = progressRect.width / 2.0
    let startAngle:CGFloat = clockwise ? CGFloat(-progress * M_PI / 180.0) : CGFloat(Constants.twoSeventyDegrees * M_PI / 180)
    let endAngle:CGFloat = clockwise ? CGFloat(Constants.twoSeventyDegrees * M_PI / 180) : CGFloat(-progress * M_PI / 180.0)
    
    progressPath.addArcWithCenter(center, radius:radius, startAngle:startAngle, endAngle:endAngle, clockwise:!clockwise)
    progressPath.addLineToPoint(CGPointMake(progressRect.midX, progressRect.midY))
    progressPath.closePath()
    
    CGContextSaveGState(context)
    
    progressPath.addClip()
    
    if trackImage != nil {
      trackImage!.drawInRect(innerRect)
    } else {
      trackFillColor.setFill()
      circlePath.fill()
    }
    
    CGContextRestoreGState(context)
  }
  
  private func setProgress(progress: Double) {
    self.progress = progress
  }
  
}