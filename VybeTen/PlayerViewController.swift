//
//  PlayerViewController.swift
//  Vybe
//
//  Created by Jinsu Kim on 3/13/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class PlayerViewController: UIViewController {
  @IBOutlet weak var timeProgressBar: TimeProgressBar!
  @IBOutlet weak var firstOverlay: UIView!
  
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var usernameLabel: UILabel!
  @IBOutlet weak var optionsButton: UIButton!
  
  @IBOutlet weak var optionsOverlay: UIView!
  @IBOutlet weak var flagButton: UIButton!
  @IBOutlet weak var blockButton: UIButton!
  
  var currPlayerView: PlayerView!
  var currPlayer: AVPlayer = AVPlayer()
  var currItem: AVPlayerItem?
  
//  var inLoop: Bool

  override func viewDidLoad() {
    super.viewDidLoad()
    
    // playerView set-up
    let playerView = PlayerView(frame: UIScreen.mainScreen().bounds)
    playerView.setPlayer(currPlayer)
    currPlayerView = playerView
    self.view.insertSubview(playerView, atIndex: 0)
    
    
    self.firstOverlay.hidden = true
    self.optionsOverlay.hidden = true
    
    let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: "swipeDownToDismiss")
    swipeDownGesture.direction = UISwipeGestureRecognizerDirection.Down
    self.view.addGestureRecognizer(swipeDownGesture)
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    // status bar will be hidden
    self.setNeedsStatusBarAppearanceUpdate()
  }
  
  func playVybe(vy: PFObject) {
    if let videoFile = vy[kVYBVybeVideoKey] as? PFFile {
      MBProgressHUD.showHUDAddedTo(self.view, animated: true)
      videoFile.getDataInBackgroundWithBlock({ (data: NSData!, error: NSError!) -> Void in
        if error == nil {
          if let url = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true) {
            var cacheURL = url.URLByAppendingPathComponent(vy.objectId)
            cacheURL = cacheURL.URLByAppendingPathExtension("mp4")
            
            data.writeToURL(cacheURL, atomically: true)

            let asset = AVURLAsset(URL: cacheURL, options: nil)
            self.playAsset(asset)
          }
        }
        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
      })
    }
  }
  
  func playAsset(asset: AVAsset) {
    self.currPlayerView.setOrientation(asset)
    
    self.currItem = AVPlayerItem(asset: asset)
    self.currPlayer.replaceCurrentItemWithPlayerItem(self.currItem)
    self.currPlayer.play()
  }
  
  func swipeDownToDismiss() {
    self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
}
