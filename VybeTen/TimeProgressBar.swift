//
//  TimeProgressBar.swift
//  Vybe
//
//  Created by Jinsu Kim on 2/24/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

@IBDesignable

class TimeProgressBar: UIView {
  var _timerCount: Int!
  var _timer: NSTimer?

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
 
    // Background
    bgColor.setFill()
    let rectPath = UIBezierPath(rect: rect)
    rectPath.fill()
    
    // Progress Drawing
    let progRect = CGRectMake(0, 0, rect.width * CGFloat(progress), rect.height)
    let progPath = UIBezierPath(rect: progRect)
    barColor.setFill()
    progPath.fill()
  }
  
  func fire(sec: Double) {
    _timer?.invalidate()
    
    _timerCount = 100
    self.progress = 0.0
    let interval: NSTimeInterval = sec / 100.0
    _timer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: "updateTimeBar:", userInfo: nil, repeats: true)
  }
  
  func updateTimeBar(timer: NSTimer) {
    if _timerCount > 0 {
      _timerCount = _timerCount - 1
    } else {
      timer.invalidate()
      _timer = nil
    }
    self.progress = (100.0 - Double(_timerCount)) / 100.0
  }
  
}
