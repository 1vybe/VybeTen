//
//  UserPromptsViewController.swift
//  VybeTen
//
//  Created by Jinsu Kim on 12/18/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit

class UserPromptsViewController: UIViewController {
  @IBOutlet weak var promptView: UIImageView!
  
  var prompts = [UIImage]()
  var currIndex = 0
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    for index in 1...5 {
      if let image = UIImage(named: "Intro\(index)") {
        prompts += [image]
      }
    }
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = false
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem()
   
    var swipeToLeft = UISwipeGestureRecognizer(target: self, action: "swipeToLeft")
    swipeToLeft.direction = UISwipeGestureRecognizerDirection.Left
    var swipeToRight = UISwipeGestureRecognizer(target: self, action: "swipeToRight")
    swipeToRight.direction = UISwipeGestureRecognizerDirection.Right
    
    self.view.addGestureRecognizer(swipeToLeft)
    self.view.addGestureRecognizer(swipeToRight)
  }
  
  func swipeToLeft() {
    currIndex++
    if currIndex < prompts.count {
      promptView.image = prompts[currIndex]
      self.promptView.setNeedsDisplay()
    } else {
      NSUserDefaults.standardUserDefaults().setObject(NSNumber(bool: true), forKey: kVYBUserDefaultsUserPromptsSeenKey)
      self.navigationController?.popViewControllerAnimated(true)
    }
  }
  
  func swipeToRight() {
    currIndex--
    if currIndex >= 0 {
      promptView.image = prompts[currIndex]
      self.promptView.setNeedsDisplay()
    } else {
      currIndex = 0
    }
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}
