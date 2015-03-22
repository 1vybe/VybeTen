//
//  PreviewViewController.swift
//  Vybe
//
//  Created by Jinsu Kim on 1/31/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit
import AVFoundation

class PreviewViewController: UIViewController {
  @IBOutlet weak var playerView: PlayerView!
  @IBOutlet weak var overlayView: UIView!
    
  @IBOutlet weak var shareButton: UIButton!
  
  var player: AVPlayer?
  var currItem: AVPlayerItem?
  let videoPath: String?
  let thumbnailPath: String?
  
  deinit {
    println("PreviewVC deinit")
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    videoPath = MyVybeStore.sharedInstance.currVybe?.videoFilePath()
    thumbnailPath = MyVybeStore.sharedInstance.currVybe?.thumbnailFilePath()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    player = AVPlayer()
    playerView.setPlayer(player!)
    
    if videoPath != nil {
      if let videoURL = NSURL(fileURLWithPath: videoPath!) {
        let asset = AVURLAsset(URL: videoURL, options: nil)
  
        currItem = AVPlayerItem(asset: asset)
        
        // default
        var value = NSNumber(integer: UIInterfaceOrientation.Portrait.rawValue)
        
        let orientation: AVCaptureVideoOrientation = asset.videoOrientation()
        if orientation == .LandscapeLeft {
          value = NSNumber(integer: UIInterfaceOrientation.LandscapeLeft.rawValue)
        } else if orientation == .LandscapeRight {
          value = NSNumber(integer: UIInterfaceOrientation.LandscapeRight.rawValue)
        }
        
        UIDevice.currentDevice().setValue(value, forKey: "orientation")
      }
    }
    // Do any additional setup after loading the view.
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "currItemDidReachEnd", name: AVPlayerItemDidPlayToEndTimeNotification, object: currItem)
    
    player?.replaceCurrentItemWithPlayerItem(currItem)
    player?.play()
  }
  
  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    
    player?.pause()
    NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: currItem)
  }
  
  func currItemDidReachEnd() {
    currItem?.seekToTime(kCMTimeZero)
    player?.play()
  }
  
  // NOTE: - Unwind does not work when previewVC using show action segue (e.g. push)
  @IBAction func dismissButtonPressed(sender: AnyObject) {
    self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
  }
  
  @IBAction func sendButtonPressed(sender: AnyObject) {
    MyVybeStore.sharedInstance.uploadCurrentVybe()
    
    self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  override func shouldAutorotate() -> Bool {
    return false
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
}
