//
//  VYBLoginViewController.m
//  VybeTen
//
//  Created by jinsuk on 4/28/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBLoginViewController.h"


@implementation VYBLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor clearColor];
    // Adding blurred background
    UIToolbar *backView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.height, self.view.bounds.size.width)];
    [backView setBarStyle:UIBarStyleBlack];
    [self.view insertSubview:backView atIndex:0];
    
    // Adding Vybe Logo
    UIImageView *logoImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"vybe_logo_text.png"]];
    [self.logInView setLogo:logoImgView];
    
    [self.logInView.facebookButton setTitle:@" Sign in with Facebook" forState:UIControlStateNormal];

    [self.logInView.twitterButton setTitle:@" Sign in with Twitter" forState:UIControlStateNormal];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self.logInView.logo setFrame:CGRectMake((self.view.bounds.size.width - 200)/2, 0, 200, 200)];
    
    CGRect frame = self.logInView.facebookButton.frame;
    frame.origin.x = (self.view.bounds.size.width - frame.size.width) / 2;
    frame.origin.y = 200 + 10;
    [self.logInView.facebookButton setFrame:frame];
    
    frame.origin.y += 50;
    [self.logInView.twitterButton setFrame:frame];
}

- (void)logInViewController:(PFLogInViewController *)controller
               didLogInUser:(PFUser *)user {
    if (user.isNew) {
        NSLog(@"NEW User is %@", [[PFUser currentUser] username]);
    }
    else {
        NSLog(@"Returning User is %@", [[PFUser currentUser] username]);
    }
    
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
    NSLog(@"Failed to log in...");
}

@end
