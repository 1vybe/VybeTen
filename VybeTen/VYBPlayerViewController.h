//
//  VYBPlayerViewController.h
//  VybeTen
//
//  Created by jinsuk on 10/6/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VYBPlayerViewController : UIViewController
- (id)initWithPageIndex:(NSInteger)pageIndex;
- (NSInteger)pageIndex;

//TODO: Called should call this method inside the completion block when it is calling presentViewController:

- (void)playZoneVybesFromVybe:(PFObject *)aVybe;        // User clicked on one of his individual vybe
- (void)playFreshVybesFromZone:(NSString *)zoneID;      // User clicked on one of active zones
//- (void)playActiveVybesFromZone:(NSString *)zoneID;     // User clicked on one of active zones but there is no fresh content


@end
