//
//  PlayerViewController.swift
//  Vybe
//
//  Created by Jinsu Kim on 3/13/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit
import AVFoundation

protocol PlayerDelegate {
  func didFinishSetup(success: Bool, vc: PlayerViewController)
  func didDismissPlayer(vc: PlayerViewController)
}

class PlayerViewController: UIViewController {
  @IBOutlet weak var playerView: PlayerView!

  @IBOutlet weak var timeProgressBar: TimeProgressBar!
  @IBOutlet weak var firstOverlay: UIView!
  
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var usernameLabel: UILabel!
  @IBOutlet weak var optionsButton: UIButton!
  
  @IBOutlet weak var voteUpButton: UIButton!
  @IBOutlet weak var voteDownButton: UIButton!
  @IBOutlet weak var pointsLabel: UILabel!
  
  @IBOutlet weak var optionsOverlay: UIView!
  @IBOutlet weak var flagButton: UIButton!
  @IBOutlet weak var blockButton: UIButton!
  
  var currPlayer: AVPlayer = AVPlayer()
  var currItem: AVPlayerItem?
  var currAsset: AVAsset?
  
  var currVybe: PFObject?
  var query: PFQuery?
  
  var delegate: PlayerDelegate?
    
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.playerView.setPlayer(self.currPlayer)
    
    self.optionsOverlay.hidden = true
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateVybePointScore", name:CloudUtilityPointUpdatedByCurrentUserNotification, object: nil)
    
    let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: "swipeDownToDismiss")
    swipeDownGesture.direction = UISwipeGestureRecognizerDirection.Down
    self.view.addGestureRecognizer(swipeDownGesture)
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    self.updateUIElements()
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    // status bar will be hidden
    self.setNeedsStatusBarAppearanceUpdate()
  }
  
  func prepare(vybe vy: PFObject) {
    self.currVybe = vy
    
    if let url = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true) {
      var cacheURL = url.URLByAppendingPathComponent(vy.objectId)
      cacheURL = cacheURL.URLByAppendingPathExtension("mp4")
      
      if NSFileManager.defaultManager().fileExistsAtPath(cacheURL.path!) {
        let asset = AVURLAsset(URL: cacheURL, options: nil)
        self.currAsset = asset

        self.delegate?.didFinishSetup(true, vc: self)
      } else {
        if let videoFile = vy[kVYBVybeVideoKey] as? PFFile {
          videoFile.getDataInBackgroundWithBlock({ (data: NSData!, error: NSError!) -> Void in
            if error == nil {
              data.writeToURL(cacheURL, atomically: true)
              let asset = AVURLAsset(URL: cacheURL, options: nil)
              self.currAsset = asset
              
              self.delegate?.didFinishSetup(true, vc: self)
            } else {
              self.delegate?.didFinishSetup(false, vc: self)
            }
          })
        }
      }
    }
  }
  
  private func updateUIElements() {
    if let vy = currVybe {
      if let user = vy[kVYBVybeUserKey] as? PFObject {
        if let username = user[kVYBUserUsernameKey] as? String {
          self.usernameLabel.text = username
        }
      }
      
      if let timestamp = vy[kVYBVybeTimestampKey] as? NSDate {
        self.timeLabel.text = VYBUtility.reverseTime(timestamp)
      }
    }
    
    self.updateVybePointScore()
  }
  
  func updateVybePointScore() {
    if let vy = currVybe {
      let score = VYBCache.sharedCache().pointScoreForVybe(vy)
      self.pointsLabel.text = "\(score)"
    }
  }
  
  func play() {
    if let asset = currAsset {
      self.playerView.setOrientation(asset)
      
      self.currItem = AVPlayerItem(asset: asset)
      self.currPlayer.replaceCurrentItemWithPlayerItem(self.currItem)
      self.currPlayer.play()
      
      let seconds = Double(CMTimeGetSeconds(asset.duration))
      self.timeProgressBar.fire(seconds)
    }
  }

  // MARK: - Voting
  
  @IBAction func voteUpButtonPressed(sender: AnyObject) {
    if currVybe != nil {
      CloudUtility.voteUp(vybe: currVybe!)
    }
  }
  
  @IBAction func voteDownButtonPressed(sender: AnyObject) {
    if currVybe != nil {
      CloudUtility.voteDown(vybe: currVybe!)
    }
  }
  
  func swipeDownToDismiss() {
    self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
  }
  
  override func shouldAutorotate() -> Bool {
    return false
  }
  
  override func supportedInterfaceOrientations() -> Int {
    return Int(UIInterfaceOrientationMask.Portrait.rawValue)
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
}
