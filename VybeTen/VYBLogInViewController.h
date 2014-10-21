//
//  VYBLogInViewController.h
//  VybeTen
//
//  Created by jinsuk on 7/30/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VYBSignUpViewController.h"

@protocol VYBLogInViewControllerDelegate;

@interface VYBLogInViewController : UIViewController <UITextFieldDelegate>
@property (nonatomic, assign) id<VYBLogInViewControllerDelegate> delegate;
@end

@protocol VYBLogInViewControllerDelegate <NSObject>
@required
- (void)logInViewController:(VYBLogInViewController *)logInController didLogInUser:(PFUser *)user;
@end
