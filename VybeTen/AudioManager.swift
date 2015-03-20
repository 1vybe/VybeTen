//
//  AudioManager.swift
//  VybeTen
//
//  Created by Jinsu Kim on 1/28/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit
import AVFoundation

private let _sharedInstance = AudioManager()

class AudioManager: NSObject {
  class var sharedInstance: AudioManager {
    return _sharedInstance
  }
  
  deinit {
    let session = AVAudioSession.sharedInstance()
    NSNotificationCenter.defaultCenter().removeObserver(self, name: AVAudioSessionInterruptionNotification, object: session)
  }
  
  func initiate() {
    if let session = AVAudioSession.sharedInstance() {
      // By default
      session.setCategory(AVAudioSessionCategoryPlayback, error: nil)
      
      NSNotificationCenter.defaultCenter().addObserver(self, selector: "audioSessionInterrupted:", name: AVAudioSessionInterruptionNotification, object: session)
    }
  }
  
  func activateCategoryPlayAndRecording() -> Bool {
    if let session = AVAudioSession.sharedInstance() {
      var error: NSError?
      AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, error: &error)
      AVAudioSession.sharedInstance().setActive(true, error: &error)
      
      if error == nil {
        return true
      }
    }
    
    return false
  }
  
  func activateCategoryPlaybackOnly() -> Bool {
    if let session = AVAudioSession.sharedInstance() {
      var error: NSError?
      AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, error: &error)
      AVAudioSession.sharedInstance().setActive(true, error: &error)
      
      if error == nil {
        return true
      }
    }
    
    return false
  }

}
