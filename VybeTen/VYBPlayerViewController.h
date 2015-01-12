//
//  VYBPlayerViewController.h
//  VybeTen
//
//  Created by jinsuk on 10/6/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VYBPlayerViewControllerDelegate;
@class Zone;
@interface VYBPlayerViewController : UIViewController <UIGestureRecognizerDelegate>
@property (nonatomic, weak) id<VYBPlayerViewControllerDelegate> delegate;


//TODO: Called should call this method inside the completion block when it is calling presentViewController:
- (void)playAllFresh;
- (void)playAllActiveVybes;
- (void)playOnce:(PFObject *)vybe;
- (void)playStream:(NSArray *)vybes;
- (void)playStream:(NSArray *)vybes from:(PFObject *)vybe;
- (void)playFeaturedZone:(Zone *)zone;
- (void)playZoneVybesFromVybe:(PFObject *)aVybe;        // User clicked on one of his individual vybe
- (void)playFreshVybesFromZone:(NSString *)zoneID;      // User clicked on one of active zones
//- (void)playActiveVybesFromZone:(NSString *)zoneID;     // User clicked on one of active zones but there is no fresh content

- (void)playCurrentItem;

@end
@protocol VYBPlayerViewControllerDelegate <NSObject>
@required
- (void)playerViewController:(VYBPlayerViewController *)playerVC didFinishSetup:(BOOL)ready;

@end

