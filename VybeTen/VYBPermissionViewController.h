//
//  VYBPermissionViewController.h
//  VybeTen
//
//  Created by jinsuk on 7/16/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface VYBPermissionViewController : UIViewController <CLLocationManagerDelegate, UIAlertViewDelegate>
- (BOOL)checkPermissionSettings;

@end
