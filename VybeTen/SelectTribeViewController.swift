//
//  SelectTribeViewController.swift
//  Vybe
//
//  Created by Jinsu Kim on 2/11/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

@objc protocol SelectTribeDelegate {
  func didSelectTribe(tribe: AnyObject?)
  func dismissSelectTribeViewContrller(vc: SelectTribeViewController)
}

class SelectTribeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CreateTribeDelegate {
  var delegate: SelectTribeDelegate?
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var topBar: UIView!
  
  var tribeObjects: [AnyObject] = []
  var selectedTribeIndex: Int?
  
  deinit {
    println("SelectTribeVC deinit")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.tableFooterView = UIView(frame: CGRectZero)
    
    tableView.contentInset = UIEdgeInsetsMake(topBar.bounds.size.height, 0.0, 0.0, 0.0)
    
    let query = PFQuery(className: kVYBTribeClassKey)
    query.whereKey(kVYBTribeMembersKey, equalTo: PFUser.currentUser())
    query.findObjectsInBackgroundWithBlock { (result: [AnyObject]!, error: NSError!) -> Void in
      if result != nil {
        self.tribeObjects = result
        self.moveSelectedTribeToFirst()
        
        self.tableView.reloadData()
      }
    }
  }
  
  private func moveSelectedTribeToFirst() {
    var sortedObjects = [AnyObject]()
    if let selected = MyVybeStore.sharedInstance.currTribe {
      for obj in tribeObjects {
        if let fName = obj.objectForKey(kVYBTribeNameKey) as? String,
          let sName = selected.objectForKey(kVYBTribeNameKey) as? String
          where fName == sName {
            sortedObjects = [obj] + sortedObjects
            selectedTribeIndex = 0
        } else {
          sortedObjects = sortedObjects + [obj]
        }
      }
      tribeObjects = sortedObjects
    }
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "PresentCreateTribeSegue" {
      if let createTribeVC = segue.destinationViewController as? CreateTribeViewController {
        createTribeVC.delegate = self
      }
    }
  }
  
  @IBAction func dismissButtonPressed(sender: AnyObject) {
    delegate?.dismissSelectTribeViewContrller(self)
  }
  
  @IBAction func okButtonPressed(sender: AnyObject) {
    let selectedTribe: PFObject?
    
    if let index = selectedTribeIndex {
      selectedTribe = tribeObjects[index] as? PFObject
    } else {
      selectedTribe = nil
    }
    
    MyVybeStore.sharedInstance.currTribe = selectedTribe
    delegate?.didSelectTribe(selectedTribe)
  }
  
  @IBAction func tribeSelected(sender: AnyObject) {
    let button = sender as! UIButton
    
    if button.selected {
      selectedTribeIndex = nil
    } else {
      let prevSelectedIdx: Int? = selectedTribeIndex
      
      selectedTribeIndex = button.tag
      
      if let rowIndex = prevSelectedIdx {
        self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: rowIndex, inSection: 0)], withRowAnimation: UITableViewRowAnimation.None)
      }
    }
    button.selected = !button.selected
  }
  
  // MARK: - Table view data source
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return tribeObjects.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let tribe = tribeObjects[indexPath.row] as! PFObject

    let cell = tableView.dequeueReusableCellWithIdentifier("TribeListTableCell") as! SelectTribeTableCell
    
    if let tribeName = tribe[kVYBTribeNameKey] as? String {
        cell.nameLabel.text = tribeName
    }
    
    cell.selectButton.tag = indexPath.row
    cell.selectButton.selected = (indexPath.row == selectedTribeIndex)
    
    return cell
  }
  
  // MARK: - CreateTribeDelegate
  
  func didCreateTribe(tribe: AnyObject) {
    MyVybeStore.sharedInstance.currTribe = tribe as? PFObject
    
    self.delegate?.didSelectTribe(tribe)
  }
  
  func didCancelTribe() {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
}
