//
//  VYBProfileViewController.h
//  VybeTen
//
//  Created by jinsuk on 8/22/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>

@class PFQueryTableViewController;
IB_DESIGNABLE
@interface VYBActivityTableViewController : PFQueryTableViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
- (void)scrollToTop:(id)sender;

@end
