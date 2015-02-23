//
//  AddMemberTableViewCell.swift
//  Vybe
//
//  Created by Jinsu Kim on 2/22/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

import UIKit

class AddMemberTableViewCell: UITableViewCell {
  override func setSelected(selected: Bool, animated: Bool) {
    if let checkBox = self.viewWithTag(235) as? UIButton {
      checkBox.selected = selected
    }
  }
}
