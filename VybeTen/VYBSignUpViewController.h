//
//  VYBSignUpViewController.h
//  VybeTen
//
//  Created by jinsuk on 7/18/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VYBSignUpViewControllerDelegate;
@interface VYBSignUpViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic) id<VYBSignUpViewControllerDelegate> delegate;

@end

@protocol VYBSignUpViewControllerDelegate <NSObject>
@optional
- (void)signUpCompleted;

@end;

