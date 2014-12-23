//
//  MyVybeStore.swift
//  VybeTen
//
//  Created by Jinsu Kim on 12/22/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit

private let _sharedInstance = MyVybeStore()

class MyVybeStore: NSObject {
//  var 
  var currZone: Zone?
  
  class var sharedInstance: MyVybeStore {
    return _sharedInstance
  }
  
  override init() {
    super.init()
  }
  
  func myVybesArchivePath() -> String? {
    let array = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
    if let documentPath = array.first as? NSString {
      return documentPath.stringByAppendingPathComponent("myVybes.archive")
    }
    return nil

  }
  
}
