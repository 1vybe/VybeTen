//
//  VYBLoginViewController.m
//  VybeTen
//
//  Created by jinsuk on 4/28/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBLoginViewController.h"


@implementation VYBLoginViewController {
    UIToolbar *backView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Adding blurred background
    self.view.backgroundColor = [UIColor clearColor];
    backView = [[UIToolbar alloc] init];
    [backView setBarStyle:UIBarStyleBlack];
    [self.view insertSubview:backView atIndex:0];

    // Adding Vybe Logo
    UIImageView *logoImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"vybe_logo_text.png"]];
    [self.logInView setLogo:logoImgView];
    
    [self.logInView.facebookButton setTitle:@" Sign in with Facebook" forState:UIControlStateNormal];

    [self.logInView.twitterButton setTitle:@" Sign in with Twitter" forState:UIControlStateNormal];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [backView setFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self.logInView.logo setFrame:CGRectMake((self.view.bounds.size.width - 200)/2, 0, 200, 200)];
    
    CGRect frame = self.logInView.facebookButton.frame;
    frame.size.width = 200;
    frame.origin.x = (self.view.bounds.size.width - frame.size.width) / 2;
    frame.origin.y = 200 + 10;
    [self.logInView.facebookButton setFrame:frame];
    
    frame.origin.y += 50;
    [self.logInView.twitterButton setFrame:frame];
}


@end
