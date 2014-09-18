//
//  VYBPlayerViewController.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 6..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "MBProgressHUD.h"
#import "GAITrackedViewController.h"

@class VYBPlayerView;

@interface VYBPlayerViewController : GAITrackedViewController <UIAlertViewDelegate, MBProgressHUDDelegate>

@property (nonatomic, copy) NSArray *vybePlaylist;
@property (nonatomic) NSInteger currVybeIndex;
@property (nonatomic) PFObject *currRegion;
@property (nonatomic) PFObject *currUser;

- (void)beginPlayingFrom:(NSInteger)from;

@end
