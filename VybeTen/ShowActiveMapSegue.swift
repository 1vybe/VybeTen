//
//  ShowActiveMapSegue.swift
//  VybeTen
//
//  Created by jinsuk on 11/5/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

import UIKit

class ShowActiveMapSegue: UIStoryboardSegue {
    override func perform() {
        let mapVC = self.destinationViewController as VYBMapViewController
        let sourceVC = self.sourceViewController as UIViewController
        sourceVC.presentViewController(mapVC, animated: true) { () -> Void in
            mapVC.displayAllActiveVybes()
        }
    }
}
