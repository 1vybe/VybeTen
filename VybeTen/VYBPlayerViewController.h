//
//  VYBPlayerViewController.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 3..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VYBPlayerViewController : UIViewController

- (IBAction)captureVybe:(id)sender;
- (IBAction)goToMenu:(id)sender;

- (void)playFromIndex:(NSInteger)i;

@end
