//
//  ProfileCollectionViewController.swift
//  Vybe
//
//  Created by Jinsu Kim on 2/3/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class ProfileCollectionViewController: PF {
  
  deinit {
    println("My Vybes Collection deinit")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    println("My Vybes Collection viewDidLoad")

    // Do any additional setup after loading the view.
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  /*
  // MARK: - Navigation
  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
  // Get the new view controller using segue.destinationViewController.
  // Pass the selected object to the new view controller.
  }
  */
  
}
