//
//  VYBMenuViewController.m
//  VybeTen
//
//  Created by jinsuk on 2/25/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBMenuViewController.h"
#import "VYBMyVybesViewController.h"
#import "VYBTribesViewController.h"
#import "VYBMyTribeViewController.h"
#import "UINavigationController+Fade.h"
#import "VYBExploreViewController.h"
#import "TransitionDelegate.h"

@interface VYBMenuViewController ()

@end

@implementation VYBMenuViewController

- (void)loadView {
    UIView *theView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view = theView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissMenu:)];
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.height - 150, self.view.bounds.size.width);
    UIView *tapView = [[UIView alloc] initWithFrame:frame];
    [tapView addGestureRecognizer:tapRecognizer];
    [self.view addSubview:tapView];
    
    // Adding blurred dark background for menu column
    frame = CGRectMake(self.view.bounds.size.height - 150, 0, 150, self.view.bounds.size.width);
    UIToolbar *menuColumn = [[UIToolbar alloc] initWithFrame:frame];
    [menuColumn setBarStyle:UIBarStyleBlack];
    [self.view addSubview:menuColumn];
    
    /*
    // Adding CAPTURE button
    CGRect buttonCaptureFrame = CGRectMake(self.view.bounds.size.height - 50, self.view.bounds.size.width - 50, 50, 50);
    UIButton *buttonCapture = [[UIButton alloc] initWithFrame:buttonCaptureFrame];
    UIImage *captureImage = [UIImage imageNamed:@"button_vybe.png"];
    [buttonCapture setContentMode:UIViewContentModeCenter];
    [buttonCapture setImage:captureImage forState:UIControlStateNormal];
    [buttonCapture addTarget:self action:@selector(captureVybe:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonCapture];
    */
    
    // Adding EXPLORE button
    frame = CGRectMake(0, 0, 150, self.view.bounds.size.width/4);
    UIButton *buttonExplore = [[UIButton alloc] initWithFrame:frame];
    [buttonExplore setTitle:@"E X P L O R E" forState:UIControlStateNormal];
    [buttonExplore.titleLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20.0f]];
    [buttonExplore addTarget:self action:@selector(goToExplore:) forControlEvents:UIControlEventTouchUpInside];
    [menuColumn addSubview:buttonExplore];
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(20, self.view.bounds.size.width/4, 110, 1.0f);
    bottomBorder.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.5f].CGColor;
    [buttonExplore.layer addSublayer:bottomBorder];
    
    // Adding TRIBES button
    frame = CGRectMake(0, self.view.bounds.size.width * 0.25, 150, self.view.bounds.size.width/4);
    UIButton *buttonMyTribes = [[UIButton alloc] initWithFrame:frame];
    [buttonMyTribes setTitle:@"T R I B E S" forState:UIControlStateNormal];
    [buttonMyTribes.titleLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20.0f]];
    [buttonMyTribes addTarget:self action:@selector(goToMyTribes:) forControlEvents:UIControlEventTouchUpInside];
    [menuColumn addSubview:buttonMyTribes];
    CALayer *bottomBorder2 = [CALayer layer];
    bottomBorder2.frame = CGRectMake(20, self.view.bounds.size.width/4, 110, 1.0f);
    bottomBorder2.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.5f].CGColor;
    [buttonMyTribes.layer addSublayer:bottomBorder2];
    
    // Adding FRIENDS button
    frame = CGRectMake(0, self.view.bounds.size.width * 0.5, 150, self.view.bounds.size.width/4);
    UIButton *buttonFriends = [[UIButton alloc] initWithFrame:frame];
    [buttonFriends setTitle:@"F R I E N D S" forState:UIControlStateNormal];
    [buttonFriends.titleLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20.0f]];
    [buttonFriends addTarget:self action:@selector(goToFriends:) forControlEvents:UIControlEventTouchUpInside];
    [menuColumn addSubview:buttonFriends];
    CALayer *bottomBorder3 = [CALayer layer];
    bottomBorder3.frame = CGRectMake(20, self.view.bounds.size.width/4, 110, 1.0f);
    bottomBorder3.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.5f].CGColor;
    [buttonFriends.layer addSublayer:bottomBorder3];
    
    // Adding MyVybes button
    frame = CGRectMake(0, self.view.bounds.size.width * 0.75, 150, self.view.bounds.size.width/4);
    UIButton *buttonMyVybes = [[UIButton alloc] initWithFrame:frame];
    [buttonMyVybes setTitle:@"M Y  V Y B E S" forState:UIControlStateNormal];
    [buttonMyVybes.titleLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20.0f]];
    [buttonMyVybes addTarget:self action:@selector(goToMyVybes:) forControlEvents:UIControlEventTouchUpInside];
    [menuColumn addSubview:buttonMyVybes];
}

/**
 * Actions that are triggered by buttons
 **/

- (void)dismissMenu:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)goToExplore:(id)sender {
    VYBExploreViewController *exploreVC = [[VYBExploreViewController alloc] init];
    [(UINavigationController *)self.presentingViewController popToRootViewControllerAnimated:NO];
    [(UINavigationController *)self.presentingViewController pushFadeViewController:exploreVC];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)goToMyTribes:(id)sender {
    VYBTribesViewController *tribesVC = [[VYBTribesViewController alloc] init];
    [(UINavigationController *)self.presentingViewController popToRootViewControllerAnimated:NO];
    [(UINavigationController *)self.presentingViewController pushFadeViewController:tribesVC];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)goToFriends:(id)sender {
    
    VYBMyTribeViewController *tribesVC = [[VYBMyTribeViewController alloc] init];
    [(UINavigationController *)self.presentingViewController popToRootViewControllerAnimated:NO];
    [(UINavigationController *)self.presentingViewController pushFadeViewController:tribesVC];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)goToMyVybes:(id)sender {
    VYBMyVybesViewController *myVybesVC = [[VYBMyVybesViewController alloc] init];
    [(UINavigationController *)self.presentingViewController popToRootViewControllerAnimated:NO];
    [(UINavigationController *)self.presentingViewController pushFadeViewController:myVybesVC];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}




@end
