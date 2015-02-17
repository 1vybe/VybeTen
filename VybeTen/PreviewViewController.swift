//
//  PreviewViewController.swift
//  Vybe
//
//  Created by Jinsu Kim on 1/31/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class PreviewViewController: UIViewController, SelectTribeDelegate {
  @IBOutlet weak var playerView: VYBPlayerView!
  @IBOutlet weak var overlayView: UIView!
  @IBOutlet weak var tribeLabel: UILabel!
  
  var player: AVPlayer?
  var currItem: AVPlayerItem?
  let videoPath: String?
  let thumbnailPath: String?
  
  deinit {
    println("PreviewVC deinit")
  }
  
  required init(coder aDecoder: NSCoder) {
    videoPath = MyVybeStore.sharedInstance.currVybe?.videoFilePath()
    thumbnailPath = MyVybeStore.sharedInstance.currVybe?.thumbnailFilePath()

    super.init(coder: aDecoder)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let currTribe = MyVybeStore.sharedInstance.currTribe,
      let tribeName = currTribe.objectForKey(kVYBTribeNameKey) as? String {
        tribeLabel.text = tribeName
    }
    
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
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "SelectTribeSegue" {
      if let selectTribeVC = segue.destinationViewController as? SelectTribeViewController {
        selectTribeVC.delegate = self
      }
      self.overlayView.hidden = true
    }
  }
  
  // NOTE: - Unwind does not work when previewVC using show action segue (e.g. push)
  @IBAction func dismissButtonPressed(sender: AnyObject) {
    self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
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
  
  // MARK: - SelectTribeDelegate
  
  func dismissSelectTribeViewContrller(vc: SelectTribeViewController) {
    self.dismissViewControllerAnimated(true, completion: { () -> Void in
      self.overlayView.hidden = false
    })
  }
  
  func didSelectTribe(tribe: AnyObject?) {
    self.dismissViewControllerAnimated(true, completion: { () -> Void in
      if let tribeName = tribe?.objectForKey(kVYBTribeNameKey) as? String {
        self.tribeLabel.text = tribeName
      } else {
        self.tribeLabel.text = "Select Tribe"
      }
      self.overlayView.hidden = false
    })
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
}
