//
//  PlayerView.swift
//  Vybe
//
//  Created by Jinsu Kim on 3/16/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit
import AVFoundation

extension AVAsset {
  func videoOrientation() -> AVCaptureVideoOrientation {
    var orientation: AVCaptureVideoOrientation = .Portrait

    let videoTracks = self.tracksWithMediaType(AVMediaTypeVideo)
    
    if let videoTrack = videoTracks.first as? AVAssetTrack {
      let firstTransform = videoTrack.preferredTransform
      
      if firstTransform.a == 0 && firstTransform.b == 1.0 && firstTransform.c == -1.0 && firstTransform.d == 0 {
        orientation = .LandscapeLeft
      }
      if firstTransform.a == 0 && firstTransform.b == -1.0 && firstTransform.c == 1.0 && firstTransform.d == 0 {
        orientation = .LandscapeRight
      }
      if firstTransform.a == 1.0 && firstTransform.b == 0 && firstTransform.c == 0 && firstTransform.d == 1.0 {
        orientation = .Portrait
      }
      if firstTransform.a == -1.0 && firstTransform.b == 0 && firstTransform.c == -0 && firstTransform.d == -1.0 {
        orientation = .PortraitUpsideDown
      }
      
    }
    
    return orientation
  }
}

class PlayerView: UIView {
  var orientation: AVCaptureVideoOrientation!
  
  override class func layerClass() -> AnyClass {
    return AVPlayerLayer.self
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    (self.layer as AVPlayerLayer).videoGravity = AVLayerVideoGravityResizeAspectFill
  }

  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    (self.layer as AVPlayerLayer).videoGravity = AVLayerVideoGravityResizeAspectFill
  }
  
  func setPlayer(player: AVPlayer) {
    (self.layer as AVPlayerLayer).player = player
  }
  
  func player() -> AVPlayer! {
    return (self.layer as AVPlayerLayer).player
  }
  
  func setOrientation(asset: AVAsset) {
    let orientation: AVCaptureVideoOrientation = asset.videoOrientation()
    
    self.resetLayerToIdentity()
    
    if orientation == .LandscapeLeft || orientation == .LandscapeRight {
        let rotation = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
        self.transform = rotation
        
        self.bounds = CGRectMake(0, 0, UIScreen.mainScreen().bounds.height, UIScreen.mainScreen().bounds.width)
    }
  }

  private func resetLayerToIdentity() {
    self.transform = CGAffineTransformIdentity
    self.frame = UIScreen.mainScreen().bounds
  }
}
