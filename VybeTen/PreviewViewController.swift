//
//  PreviewViewController.swift
//  Vybe
//
//  Created by Jinsu Kim on 1/31/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class PreviewViewController: UIViewController {
  @IBOutlet weak var playerView: VYBPlayerView!
  
  @IBOutlet weak var overlayView: UIView!
  @IBOutlet weak var bottomBarImageView: UIImageView!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var doneButton: UIButton!
  @IBOutlet weak var tagButton: UIButton!
  
  var player: AVPlayer?
  var currItem: AVPlayerItem?
  let videoPath: String?
  let thumbnailPath: String?
  
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    videoPath = MyVybeStore.sharedInstance.currVybe?.videoFilePath()
    thumbnailPath = MyVybeStore.sharedInstance.currVybe?.thumbnailFilePath()
  }
  
  @IBAction func cancelButtonPressed(sender: AnyObject) {
    
  }
  
  @IBAction func doneButtonPressed(sender: AnyObject) {
    
  }
  
  @IBAction func tagButtonPressed(sender: AnyObject) {
    
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    player = AVPlayer()
    playerView.player = player
    
    if videoPath != nil {
      if let videoURL = NSURL(fileURLWithPath: videoPath!) {
        let asset = AVURLAsset(URL: videoURL, options: nil)
  
        currItem = AVPlayerItem(asset: asset)
        
        var value: NSNumber
        switch asset.videoOrientation {
        case .Portrait:
          value = NSNumber(integer: UIInterfaceOrientation.Portrait.rawValue)
        case .LandscapeLeft:
          value = NSNumber(integer: UIInterfaceOrientation.LandscapeLeft.rawValue)
        case .LandscapeRight:
          value = NSNumber(integer: UIInterfaceOrientation.LandscapeRight.rawValue)
        default:
          return
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
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
}
