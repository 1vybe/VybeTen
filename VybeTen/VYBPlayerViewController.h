//
//  VYBPlayerViewController.h
//  VybeTen
//
//  Created by jinsuk on 10/6/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

@protocol VYBPlayerViewControllerDelegate;
@class Zone;
@class Tribe;
@interface VYBPlayerViewController : UIViewController <UIGestureRecognizerDelegate>
@property (nonatomic, weak) id<VYBPlayerViewControllerDelegate> delegate;


//TODO: Called should call this method inside the completion block when it is calling presentViewController:
- (void)playStreamForTribe:(Tribe *)obj;
- (void)playOnce:(PFObject *)vybe;
- (void)playStream:(NSArray *)vybes;
- (void)playStream:(NSArray *)vybes from:(PFObject *)vybe;

- (void)playCurrentItem;

@end
@protocol VYBPlayerViewControllerDelegate <NSObject>
@required
- (void)playerViewController:(VYBPlayerViewController *)playerVC didFinishSetup:(BOOL)ready;
@optional
- (void)dismissPlayerViewController:(VYBPlayerViewController *)playerVC completion:(void (^)())completionHandler;
@end

