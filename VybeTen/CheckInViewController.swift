//
//  CheckInViewController.swift
//  VybeTen
//
//  Created by Jinsu Kim on 1/12/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class CheckInViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  @IBOutlet var tableView: UITableView!
  var spots = [Zone]()
  
  @IBAction func backButtonPressed(sender: AnyObject) {
    self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    let nib = UINib(nibName: "SpotTableCell", bundle: NSBundle.mainBundle())
    self.tableView.registerNib(nib, forCellReuseIdentifier: "CheckInSpotCellIdentifier")
    
    SpotFinder.sharedInstance.findNearbySpotsInBackground { (success: Bool) -> Void in
      if success {
        if let suggestions = SpotFinder.sharedInstance.suggestedSpots() {
          self.spots = suggestions
          dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableView.reloadData()
          })
        }
      }
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  // MARK: - Table view data source
  
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return spots.count
  }
  
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    var cell = tableView.dequeueReusableCellWithIdentifier("CheckInSpotCellIdentifier") as UITableViewCell
    cell.backgroundColor = UIColor.clearColor()
    
    let spot = spots[indexPath.row]
    if let spotNameLabel = cell.viewWithTag(77) as? UILabel {
      spotNameLabel.text = spot.name
    }
    
  
    return cell
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let spot = spots[indexPath.row]
    MyVybeStore.sharedInstance.currZone = spot
    
    self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
  }
  
}
